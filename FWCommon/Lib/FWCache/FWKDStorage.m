//
//  FWKVStorage.m
//  UIViewTest
//
//  Created by silver on 2017/8/25.
//  Copyright © 2017年 Fsilver. All rights reserved.
//

#import "FWKDStorage.h"
#import <sqlite3.h>

static const int kMaxLengthOfPath = PATH_MAX - 64;

/**
 the dictory used to save files
 **/
static NSString *const kDirectoryNameOfData = @"data";
/**
 the dictory used to delete files
 **/
static NSString *const kDirectoryNameOfTrash = @"trash";
/**
 when wo create maincache.db 
 the maincache.db-shm and maincache.db-wal will be created auto.
 **/
static NSString *const kDbFileName = @"maincache.db";
static NSString *const kDbShmFileName = @"maincache.db-shm";
static NSString *const kDbWalFileName = @"maincache.db-wal";
/**
 the only table in maincache.db
 **/
static NSString *const kTableName = @"cache_table";

@implementation FWKDStorageItem

-(NSString*)description {
    
    NSString *dataString = [[NSString alloc]initWithData:_data encoding:NSUTF8StringEncoding];
    if(!dataString){
        dataString = @"";
    }
    NSString *fileName = _fileName;
    if(!fileName){
        fileName = @"";
    }
    NSDictionary *dict = @{
                           @"key":_key,
                           @"fileName":fileName,
                           @"size":@(_size),
                           @"data":dataString,
                           @"modTime":@(_modTime),
                           @"accessTime":@(_accessTime),
                           };
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:NULL];
    return [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding]; 
}


@end

@interface FWKDStorage()
{
    dispatch_queue_t _trashQueue;
    
    NSString *_dataPath;
    NSString *_trashPath;
    NSString *_dbPath;
    
    sqlite3 *_db;
    CFMutableDictionaryRef _dbStmtCache;
}

@end


@implementation FWKDStorage

-(id)initWithPath:(NSString*)path {
    
    if(path.length == 0 || path.length > kMaxLengthOfPath){
        NSLog(@"FWKVStrorage init error : invalid path : [%@]",path);
        return nil;
    }
    
    self = [super init];
    _path = [path copy];
    _dataPath = [path stringByAppendingPathComponent:kDirectoryNameOfData];
    _trashPath = [path stringByAppendingPathComponent:kDirectoryNameOfTrash];
    _dbPath = [path stringByAppendingPathComponent:kDbFileName];
    _trashQueue = dispatch_queue_create("com.fw.cache.disk.trash", DISPATCH_QUEUE_SERIAL);
    
    NSError *error = nil;
    if(![[NSFileManager defaultManager]createDirectoryAtPath:_path withIntermediateDirectories:YES attributes:nil error:&error]
       ||![[NSFileManager defaultManager]createDirectoryAtPath:_dataPath withIntermediateDirectories:YES attributes:nil error:&error]
       ||![[NSFileManager defaultManager]createDirectoryAtPath:_trashPath withIntermediateDirectories:YES attributes:nil error:&error]){
        NSLog(@"FWKVStorage init error : %@",error);
        return nil;
    }
    
    
    if(![self dbOpen] || ![self dbInitialize]){
        NSLog(@"FWKVStorage init error: failed to open sqlite db.");
        return nil;
    }

    return self;
}



#pragma mark - db

-(BOOL)dbOpen {
    
    if(_db) return YES;
    int result = sqlite3_open([_dbPath UTF8String], &_db);
    if(result == SQLITE_OK){
        
        _dbStmtCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, NULL, NULL);
        return YES;
    }else{
        return NO;
    }
}

-(BOOL)dbInitialize {
    
    NSString *sql = [NSString stringWithFormat:@"pragma journal_mode = wal; pragma synchronous = normal;create table if not exists %@ (key text, filename text, size integer, inline_data blob, modification_time integer, last_access_time integer, primary key(key)); create index if not exists last_access_time_idx on %@(last_access_time);",kTableName,kTableName];
    return [self dbExecute:sql];
}

-(BOOL)dbClose {
    
    if(!_db){
        return YES;
    }
    
    int  result = 0;
    BOOL retry = NO;
    BOOL stmtFinalized = NO;
    
    if (_dbStmtCache) CFRelease(_dbStmtCache);
    _dbStmtCache = NULL;
    
    do{
        retry = NO;
        result = sqlite3_close(_db);
        if(result == SQLITE_BUSY || result == SQLITE_LOCKED){
            
            if (!stmtFinalized) {
                stmtFinalized = YES;
                sqlite3_stmt *stmt;
                while ((stmt = sqlite3_next_stmt(_db, nil)) != 0) {
                    sqlite3_finalize(stmt);
                    retry = YES;
                }
            }
        }else if(result != SQLITE_OK){
             NSLog(@"%s line:%d sqlite close failed (%d).", __FUNCTION__, __LINE__, result);
        }
    }while (retry);
    _db = NULL;
    return YES;
}

-(BOOL)dbExecute:(NSString*)sql {
    
    char *error = NULL;
    int result = sqlite3_exec(_db, [sql UTF8String], NULL, NULL, &error);
    if(error){
        NSLog(@"dbExecute error: %s",error);
    }
    return result == SQLITE_OK;
}

-(sqlite3_stmt *)dbPrepareStmt:(NSString*)sql {
    
    if(![self dbOpen] || ![self dbInitialize]) return NULL;
    
    sqlite3_stmt *stmt = (sqlite3_stmt*)CFDictionaryGetValue(_dbStmtCache, (__bridge const void *)(sql));
    if(!stmt){
        int result = sqlite3_prepare_v2(_db, [sql UTF8String], -1, &stmt, NULL);
        if(result != SQLITE_OK){
            return NULL;
        }
    }else{
        sqlite3_reset(stmt);
    }
    return stmt;
}



-(BOOL)dbSaveKey:(NSString*)key data:(NSData*)data fileName:(NSString*)fileName {
    
    NSString *sql = [NSString stringWithFormat:@"insert or replace into %@ (key, filename, size, inline_data, modification_time, last_access_time) values (?1, ?2, ?3, ?4, ?5, ?6);",kTableName];
    
    sqlite3_stmt *stmt = [self dbPrepareStmt:sql];
    if(!stmt) return NO;
    
    int timestamp = (int)time(NULL);
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    sqlite3_bind_text(stmt, 2, fileName.UTF8String, -1, NULL);
    sqlite3_bind_int(stmt, 3, (int)data.length);
    if(fileName.length == 0){
        sqlite3_bind_blob(stmt, 4, data.bytes, (int)data.length, 0);
    }else{
        sqlite3_bind_blob(stmt, 4, NULL, 0, 0);
    }
    sqlite3_bind_int(stmt, 5, timestamp);
    sqlite3_bind_int(stmt, 6, timestamp);
    
    int result = sqlite3_step(stmt);
    if(result != SQLITE_DONE){
        NSLog(@"insert error: %s",sqlite3_errmsg(_db));
        return NO;
    }
    return YES;
}

-(NSString*)dbGetFileNameWithKey:(NSString*)key {
    
    NSString *sql = [NSString stringWithFormat:@"select filename from %@ where key = ?1;",kTableName];
    sqlite3_stmt *stmt = [self dbPrepareStmt:sql];
    if(!stmt)return nil;
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    int result = sqlite3_step(stmt);
    if(result == SQLITE_ROW){
        char *filename = (char *)sqlite3_column_text(stmt, 0);
        if(filename && *filename != 0){
            return [NSString stringWithUTF8String:filename];
        }
    }else{
        if(result != SQLITE_DONE){
            NSLog(@"%s line:%d query error : %s",__FUNCTION__,__LINE__,sqlite3_errmsg(_db));
        }
    }
    return nil;
}

-(BOOL)dbDeleteItemWithKey:(NSString*)key {
    
    NSString *sql = [NSString stringWithFormat:@"delete from %@ where key = ?1;",kTableName];
    sqlite3_stmt *stmt = [self dbPrepareStmt:sql];
    if(!stmt)return nil;
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    int result = sqlite3_step(stmt);
    if(result != SQLITE_DONE){
        NSLog(@"%s line:%d query error : %s",__FUNCTION__,__LINE__,sqlite3_errmsg(_db));
    }
    return YES;
}

-(BOOL)dbDeleteItemWithKeys:(NSArray*)keys {
    
    NSString *sql = [NSString stringWithFormat:@"delete from %@ where key in (%@);",kTableName,[self dbJoinedKeys:keys]];
    sqlite3_stmt *stmt = [self dbPrepareStmt:sql];
    if(!stmt)return nil;
    [self dbBindJoinedKeys:keys stmt:stmt fromIndex:1];
    
    int result = sqlite3_step(stmt);
    if(result != SQLITE_DONE){
        NSLog(@"%s line:%d query error : %s",__FUNCTION__,__LINE__,sqlite3_errmsg(_db));
    }
    return YES;
}

-(NSData*)dbGetDataWithKey:(NSString*)key {
    
    NSString *sql = [NSString stringWithFormat:@"select inline_data from %@ where key = ?1;",kTableName];
    sqlite3_stmt *stmt = [self dbPrepareStmt:sql];
    if(!stmt)return nil;
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    int result = sqlite3_step(stmt);
    if(result == SQLITE_ROW){
        
        const void *inline_data = sqlite3_column_blob(stmt, 0);
        int inline_data_bytes = sqlite3_column_bytes(stmt, 0);
        if (!inline_data || inline_data_bytes <= 0) return nil;
        return [NSData dataWithBytes:inline_data length:inline_data_bytes];
        
    }else{
        NSLog(@"%s line:%d query error : %s",__FUNCTION__,__LINE__,sqlite3_errmsg(_db));
        return nil;
    }
}

-(FWKDStorageItem*)dbGetItemWithKey:(NSString*)key excludeData:(BOOL)excludeData {
    
    NSString *sql = excludeData ? [NSString stringWithFormat:@"select key, filename, size, modification_time, last_access_time from %@ where key = ?1;",kTableName] : [NSString stringWithFormat:@"select key, filename, size, inline_data, modification_time, last_access_time from %@ where key = ?1;",kTableName];
    sqlite3_stmt *stmt = [self dbPrepareStmt:sql];
    if(!stmt)return nil;
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    int result = sqlite3_step(stmt);
    
    FWKDStorageItem *item = nil;
    if(result == SQLITE_ROW){
        item = [self dbGetItemForStmt:stmt excludeData:excludeData];
    }else{
        if(result != SQLITE_DONE){
            NSLog(@"%s line:%d query error : %s",__FUNCTION__,__LINE__,sqlite3_errmsg(_db));
        }
    }
    return item;
}


-(FWKDStorageItem*)dbGetItemForStmt:(sqlite3_stmt*)stmt excludeData:(BOOL)excludeData {
    
    int i = 0;
    char *key = (char *)sqlite3_column_text(stmt, i++);
    char *filename = (char *)sqlite3_column_text(stmt, i++);
    int size = sqlite3_column_int(stmt, i++);
   

    const void *inline_data = excludeData ? NULL:sqlite3_column_blob(stmt, i);
    int inline_data_bytes = excludeData ? 0 : sqlite3_column_bytes(stmt, i++);
    
    int modTime = sqlite3_column_int(stmt, i++);
    int accessTime = sqlite3_column_int(stmt, i);
    
    FWKDStorageItem *item = [[FWKDStorageItem alloc]init];
    item.key = [NSString stringWithUTF8String:key];
    if(filename && *filename != 0)item.fileName = [NSString stringWithUTF8String:filename];
    item.size = size;
    if(inline_data && inline_data_bytes > 0)item.data = [NSData dataWithBytes:inline_data length:inline_data_bytes];
    item.modTime = modTime;
    item.accessTime = accessTime;
    return item;
}

-(NSMutableArray<FWKDStorageItem*> *)dbGetItemForKeys:(NSArray<NSString*> *)keys excludeData:(BOOL)excludeData{
    
    NSString *sql = excludeData ? [NSString stringWithFormat:@"select key, filename, size, modification_time, last_access_time from %@ where key in (%@);",kTableName,[self dbJoinedKeys:keys]] : [NSString stringWithFormat:@"select key, filename, size, inline_data, modification_time, last_access_time from %@ where key in (%@);",kTableName,[self dbJoinedKeys:keys]];
   
    sqlite3_stmt *stmt = [self dbPrepareStmt:sql];
    if(!stmt)return nil;
    [self dbBindJoinedKeys:keys stmt:stmt fromIndex:1];
    
    NSMutableArray *items = [NSMutableArray new];
    do{
        int result = sqlite3_step(stmt);
        if(result == SQLITE_ROW){
            FWKDStorageItem *item = [self dbGetItemForStmt:stmt excludeData:excludeData];
            if(item) [items addObject:item];
            
        }else if(result == SQLITE_DONE){
            break;
        }else{
            break;
        }
    }while(1);    
    return items;
}

-(NSString*)dbJoinedKeys:(NSArray*)keys {
    
    NSMutableString *string = [NSMutableString new];
    for (NSUInteger i = 0,max = keys.count; i < max; i++) {
        [string appendString:@"?"];
        if (i + 1 != max) {
            [string appendString:@","];
        }
    }
    return string;
}

-(void)dbBindJoinedKeys:(NSArray*)keys stmt:(sqlite3_stmt*)stmt fromIndex:(int)index {
    
    for (NSString *key in keys) {
        sqlite3_bind_text(stmt, index++, key.UTF8String, -1, NULL);
    }
}

-(NSArray*)dbGetFilenamesLargeThanSize:(int)size {
    
    NSString *sql = [NSString stringWithFormat:@"select filename from %@ where size > ?1 and filename is not null;",kTableName];
    sqlite3_stmt *stmt = [self dbPrepareStmt:sql];
    if(!stmt)return nil;
    sqlite3_bind_int(stmt, 1, size);
     
    NSMutableArray *temp = [NSMutableArray new];
    do{
        int result = sqlite3_step(stmt);
        if(result == SQLITE_ROW){
            char *filename = (char *)sqlite3_column_text(stmt, 0);
            if(filename && *filename != 0){
                 NSString *filenameString = [NSString stringWithUTF8String:filename];
                [temp addObject:filenameString];
            }
        }else if(result == SQLITE_DONE){
            break;
        }else{
            break;
        }
    }while(1); 
    return temp.count ? temp : nil;
}

-(NSArray*)dbGetFilenamesEarlierThanTime:(int)time {
    
    NSString *sql = [NSString stringWithFormat:@"select filename from %@ where last_access_time < ?1 and filename is not null;",kTableName];
    sqlite3_stmt *stmt = [self dbPrepareStmt:sql];
    if(!stmt)return nil;
    sqlite3_bind_int(stmt, 1, time);
    
    NSMutableArray *temp = [NSMutableArray new];
    do{
        int result = sqlite3_step(stmt);
        if(result == SQLITE_ROW){
            char *filename = (char *)sqlite3_column_text(stmt, 0);
            if(filename && *filename != 0){
                NSString *filenameString = [NSString stringWithUTF8String:filename];
                [temp addObject:filenameString];
            }
        }else if(result == SQLITE_DONE){
            break;
        }else{
            break;
        }
    }while(1); 
    return temp.count ? temp : nil;
}



-(BOOL)dbDeleteItemsLargeThanSize:(int)size {
    
    NSString *sql = [NSString stringWithFormat:@"delete from %@ where size > ?1",kTableName];
    sqlite3_stmt *stmt = [self dbPrepareStmt:sql];
    if(!stmt)return nil;
    sqlite3_bind_int(stmt, 1, size);
    int result = sqlite3_step(stmt);
    if(result != SQLITE_DONE){
        NSLog(@"%s line:%d query error : %s",__FUNCTION__,__LINE__,sqlite3_errmsg(_db));
        return NO;
    }
    return YES;
}

-(BOOL)dbDeleteItemsEarlierThanTime:(int)time {
    
    NSString *sql = [NSString stringWithFormat:@"delete from %@ where last_access_time < ?1",kTableName];
    sqlite3_stmt *stmt = [self dbPrepareStmt:sql];
    if(!stmt)return nil;
    sqlite3_bind_int(stmt, 1, time);
    int result = sqlite3_step(stmt);
    if(result != SQLITE_DONE){
        NSLog(@"%s line:%d query error : %s",__FUNCTION__,__LINE__,sqlite3_errmsg(_db));
        return NO;
    }
    return YES;
}

-(BOOL)dbUpadteAccessTimeWithKey:(NSString*)key {
    
    NSString *sql = [NSString stringWithFormat:@"update %@ set last_access_time = ?1 where key = ?2;",kTableName];
    sqlite3_stmt *stmt = [self dbPrepareStmt:sql];
    if(!stmt)return nil;
    sqlite3_bind_int(stmt, 1, (int)time(NULL));
    sqlite3_bind_text(stmt, 2, key.UTF8String, -1, NULL);
    int result = sqlite3_step(stmt);
    if(result != SQLITE_DONE){
        NSLog(@"%s line:%d sqlite update error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
        return NO;
    }
    return YES;
}

-(BOOL)dbUpadteAccessTimeWithKeys:(NSArray*)keys {
    
    int t = (int)time(NULL);
    NSString *sql = [NSString stringWithFormat:@"update %@ set last_access_time = %d where key in (%@);",kTableName,t,[self dbJoinedKeys:keys]];
    sqlite3_stmt *stmt = [self dbPrepareStmt:sql];
    if(!stmt)return nil;
    [self dbBindJoinedKeys:keys stmt:stmt fromIndex:1];
    int result = sqlite3_step(stmt);
    if(result != SQLITE_DONE){
        NSLog(@"%s line:%d sqlite update error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
        return NO;
    }
    return YES;
}

-(int)dbGetTotalItemSize{
    
    NSString *sql = [NSString stringWithFormat:@"select sum(size) from  %@;",kTableName];
    sqlite3_stmt *stmt = [self dbPrepareStmt:sql];
    if(!stmt)return -1;
    int result = sqlite3_step(stmt);
    if(result != SQLITE_ROW){
        return -1;
    }
    return sqlite3_column_int(stmt, 0);
}

-(int)dbGetTotalItemsCount {
    NSString *sql = [NSString stringWithFormat:@"select count(key) from %@;",kTableName];
    sqlite3_stmt *stmt = [self dbPrepareStmt:sql];
    if(!stmt)return -1;
    int result = sqlite3_step(stmt);
    if(result != SQLITE_ROW){
        return -1;
    }
    return sqlite3_column_int(stmt, 0);
}

-(NSMutableArray*)dbGetItemsByAccessTimeASCWithLimit:(int)limit {
    
    NSString *sql = [NSString stringWithFormat:@"select key, filename, size from %@ order by last_access_time asc limit ?1",kTableName];
    sqlite3_stmt *stmt = [self dbPrepareStmt:sql];
    if(!stmt)return nil;
    sqlite3_bind_int(stmt, 1, limit);
    
    NSMutableArray *temp = [NSMutableArray new];
    do{
        int result = sqlite3_step(stmt);
        if(result == SQLITE_ROW){
            
            char *key = (char*)sqlite3_column_text(stmt, 0);
            char *filename = (char*)sqlite3_column_text(stmt, 1);
            int size = sqlite3_column_int(stmt, 2);
            
            FWKDStorageItem *item = [[FWKDStorageItem alloc]init];
            item.key = [NSString stringWithUTF8String:key];
            if(filename && *filename != 0) item.fileName = [NSString stringWithUTF8String:filename];
            item.size = size;
            [temp addObject:item];
            
        }else if(result == SQLITE_DONE){
            break;
        }else{
            break;
        }
    }while (1);
    
    return temp.count > 0 ? temp : nil;
}

-(int)dbItemExistsForKey:(NSString*)key {
    
    NSString *sql = [NSString stringWithFormat:@"select count(key) from %@ where key = ?1;",kTableName];
    sqlite3_stmt *stmt = [self dbPrepareStmt:sql];
    if(!stmt)return -1;
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    int result = sqlite3_step(stmt);
    if(result != SQLITE_ROW){
        return -1;
    }
    return sqlite3_column_int(stmt, 0);
}

#pragma mark - file

-(BOOL)fileWriteWithName:(NSString*)fileName data:(NSData*)data {
    
    NSString *path = [_dataPath stringByAppendingPathComponent:fileName];
    return [data writeToFile:path atomically:NO];
}

-(BOOL)fileDeleteWithName:(NSString*)fileName {
    
    NSString *path = [_dataPath stringByAppendingPathComponent:fileName];
    return [[NSFileManager defaultManager]removeItemAtPath:path error:NULL];
}

-(NSData*)fileReadWithName:(NSString*)fileName{
    
    NSString *path = [_dataPath stringByAppendingPathComponent:fileName];
    return [NSData dataWithContentsOfFile:path];
}


- (BOOL)fileMoveAllToTrash {
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuid = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    NSString *tmpPath = [_trashPath stringByAppendingPathComponent:(__bridge NSString *)(uuid)];
    BOOL suc = [[NSFileManager defaultManager] moveItemAtPath:_dataPath toPath:tmpPath error:nil];
    if (suc) {
        suc = [[NSFileManager defaultManager] createDirectoryAtPath:_dataPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    CFRelease(uuid);
    return suc;
}

- (void)fileEmptyTrashInBackground {
    NSString *trashPath = _trashPath;
    dispatch_queue_t queue = _trashQueue;
    dispatch_async(queue, ^{
        NSFileManager *manager = [NSFileManager new];
        NSArray *directoryContents = [manager contentsOfDirectoryAtPath:trashPath error:NULL];
        for (NSString *path in directoryContents) {
            NSString *fullPath = [trashPath stringByAppendingPathComponent:path];
            [manager removeItemAtPath:fullPath error:NULL];
        }
    });
}

#pragma mark - private

/**
 Delete all files and empty in background.
 Make sure the db is closed.
 */
- (void)reset {
    
    NSError *error = nil;
    
    NSString *dbPath = [_path stringByAppendingPathComponent:kDbFileName];
    if([[NSFileManager defaultManager]fileExistsAtPath:dbPath] && [[NSFileManager defaultManager] removeItemAtPath:dbPath error:&error] ){
        NSLog(@"maincache.db delete success");
    }
    
    
    NSString *dbshmPath = [_path stringByAppendingPathComponent:kDbShmFileName];
    if([[NSFileManager defaultManager]fileExistsAtPath:dbshmPath] && [[NSFileManager defaultManager] removeItemAtPath:dbshmPath error:&error]){
       
        NSLog(@"maincache.db-shm delete success");
    }
    
    NSString *dbwalPath = [_path stringByAppendingPathComponent:kDbWalFileName];
    if([[NSFileManager defaultManager]fileExistsAtPath:dbwalPath] && [[NSFileManager defaultManager] removeItemAtPath:dbwalPath error:&error]){
        NSLog(@"maincache.db-wal delete success");
    }

    [self fileMoveAllToTrash];
    [self fileEmptyTrashInBackground];
}


#pragma mark - public

-(BOOL)saveItem:(FWKDStorageItem*)item {
    return [self saveItemWithKey:item.key data:item.data fileName:item.fileName];
}

-(BOOL)saveItemWithKey:(NSString*)key data:(NSData*)data {
    return [self saveItemWithKey:key data:data fileName:nil];
}

-(BOOL)saveItemWithKey:(NSString*)key data:(NSData*)data fileName:(NSString *)fileName {
    
    if(key.length == 0 || data.length == 0){
        return NO;
    }
    
    if(fileName.length){
        
        if(![self fileWriteWithName:fileName data:data]){
            return NO;
        }
        
        if(![self dbSaveKey:key data:data fileName:fileName]){
            [self fileDeleteWithName:fileName];
        }
        return YES;
        
    }else{
        
        return [self dbSaveKey:key data:data fileName:nil];
    }
}

-(BOOL)removeItemForKey:(NSString*)key {
    
    if(key.length == 0) return NO;
    NSString *fileName = [self dbGetFileNameWithKey:key];
    if(fileName.length > 0){
        [self fileDeleteWithName:fileName];
    }
    return [self dbDeleteItemWithKey:key];
}

-(BOOL)removeItemForKeys:(NSArray<NSString *> *)keys {
    
    if(keys.count == 0)return NO;
    for (NSString *key in keys) {
        NSString *fileName = [self dbGetFileNameWithKey:key];
        if(fileName.length > 0){
            [self fileDeleteWithName:fileName];
        }
    }
    return [self dbDeleteItemWithKeys:keys];
}

-(BOOL)removeItemsLargeThanSize:(int)size {
    
    if(size == INT_MAX){
        return YES;
    }
    if(size <= 0){
        return [self removeAllItems];
    }
    NSArray *filenames = [self dbGetFilenamesLargeThanSize:size];
    for(NSString *filename in filenames){
        [self fileDeleteWithName:filename];
    }
    return [self dbDeleteItemsLargeThanSize:size];
}

- (BOOL)removeItemsEarlierThanTime:(int)time {
    
    if(time == INT_MAX){
        // all time is fit.
        return [self removeAllItems];
    }
    if(time <= 0){
        return YES;
    }
    NSArray *filenames = [self dbGetFilenamesEarlierThanTime:time];
    for(NSString *filename in filenames){
        [self fileDeleteWithName:filename];
    }
    return [self dbDeleteItemsEarlierThanTime:time];
}

-(BOOL)removeItemsFitSize:(int)size {
    
    if(size <= 0){
        return YES;
    }
    if(size == INT_MAX){
        return [self removeAllItems];
    }
    
    int totalSize = [self dbGetTotalItemSize];
    if(totalSize <= size){
        return YES;
    }
    NSArray *array = nil;
    int count = 16;
    BOOL suc = NO;
    do {
        array = [self dbGetItemsByAccessTimeASCWithLimit:count];
        for (FWKDStorageItem *obj in array) {
            
             if(totalSize > size){
                 
                 if(obj.fileName.length>0){
                     [self fileDeleteWithName:obj.fileName];
                 }
                 suc = [self dbDeleteItemWithKey:obj.key];
                 totalSize -= obj.size;
                 
             }else{
                 
                 break;
             }
            
             if(!suc)break;
        }
    } while (totalSize > size && array.count > 0 && suc);
    
    return suc;
}


-(BOOL)removeItemsFitCount:(int)maxCount {
    
    if(maxCount == 0){
        return [self removeAllItems];
    }
    
    if(maxCount == INT_MAX){
        return YES;
    }
    
    int totalCount = [self dbGetTotalItemsCount];
    if(totalCount <= maxCount){
        return YES;
    }
    
    NSArray *array = nil;
    int count = 2;
    BOOL suc = NO;
    do {
        array = [self dbGetItemsByAccessTimeASCWithLimit:count];
        for (FWKDStorageItem *obj in array) {
            
            if(totalCount > maxCount){
                
                if(obj.fileName.length>0){
                    [self fileDeleteWithName:obj.fileName];
                }
                suc = [self dbDeleteItemWithKey:obj.key];
                totalCount--;
                
            }else{
                
                break;
            }
            
            if(!suc)break;
        }
    } while (totalCount > maxCount && array.count > 0 && suc);
    
    return suc;
}


-(BOOL)removeAllItems {
    
    if (![self dbClose]) {
        return NO;
    }

    [self reset];
  
    if(![self dbOpen]){
        return NO;
    }
    
    if(![self dbInitialize]){
        return NO;
    }
    return YES;
}

-(NSData*)getItemDataForKey:(NSString*)key {
    
    if(key.length == 0) return nil;
    NSData *data = nil;
    NSString *fileName = [self dbGetFileNameWithKey:key];
    if(fileName.length>0){
        data = [self fileReadWithName:fileName];
        if(!data){
            [self dbDeleteItemWithKey:key];
            data = nil;
        }
    }else{
        data = [self dbGetDataWithKey:key];
    }
    
    if(data){
        [self dbUpadteAccessTimeWithKey:key];
    }
    return data;
}

-(FWKDStorageItem*)getItemForKey:(NSString*)key {
    
    if(key.length==0)return nil;
    FWKDStorageItem  *item = [self dbGetItemWithKey:key excludeData:NO];
    if(item.fileName.length > 0){
        item.data = [self fileReadWithName:item.fileName];
        if(!item.data){
            [self dbDeleteItemWithKey:key];
            item = nil;
        }
    }
    if(item){
        [self dbUpadteAccessTimeWithKey:key];
    }
    return item;
}

-(FWKDStorageItem*)getItemExcludeDataForKey:(NSString*)key {
    
    if(key.length==0)return nil;
    return [self dbGetItemWithKey:key excludeData:YES];
}

-(NSArray<FWKDStorageItem*> *)getItemForKeys:(NSArray<NSString*> *)keys {
    
    if(keys.count==0)return nil;
    NSMutableArray *items = [self dbGetItemForKeys:keys excludeData:NO];
    
    NSInteger max = items.count;
    for (int i=0; i<max; i++) {
        
        FWKDStorageItem *item = items[i];
        if(item.fileName.length > 0){
            item.data = [self fileReadWithName:item.fileName];
            if(!item.data){
                if(item.key)[self dbDeleteItemWithKey:item.key];
                [items removeObjectAtIndex:i];
                max--;
                i--;
            }
        }
    }
    
    if(items.count > 0){
        [self dbUpadteAccessTimeWithKeys:keys];
    }
    return (items.count == 0) ? nil : items;
}

-(NSArray<FWKDStorageItem*> *)getItemExcludeDataForKeys:(NSArray<NSString*> *)keys {
    
    if(keys.count==0)return nil;
    NSMutableArray *items = [self dbGetItemForKeys:keys excludeData:YES];
    return (items.count == 0) ? nil : items;
}

-(NSDictionary<NSString*,NSData*> *)getItemDataForKeys:(NSArray<NSString*> *)keys {
    
    if(keys.count==0)return nil;
    NSArray *items = [self getItemForKeys:keys];
    NSMutableDictionary *dictionay = [NSMutableDictionary new];
    for (FWKDStorageItem *item in items) {
        if(item.key && item.data){
            [dictionay setObject:item.data forKey:item.key];
        }
    }
    return dictionay.count ? dictionay : nil;
}

-(BOOL)itemExistsForKey:(NSString*)key {
    
    if(key.length == 0) return NO;
    int count = [self dbItemExistsForKey:key];
    NSLog(@"count:%d",count);
    return count>0;
}

-(int)getItemsCount {
    
    int count = [self dbGetTotalItemsCount];
    return count;
}

-(int)getItemsSize {
    
    int size = [self dbGetTotalItemSize];
    return size;
}

@end














