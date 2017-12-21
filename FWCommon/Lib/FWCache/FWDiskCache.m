//
//  FWDiskCache.m
//  UIViewTest
//
//  Created by silver on 2017/8/28.
//  Copyright © 2017年 Fsilver. All rights reserved.
//

#import "FWDiskCache.h"
#import "FWKDStorage.h"
#import <CommonCrypto/CommonCrypto.h>
#import <UIKit/UIKit.h>

static NSString *FWNSStringMD5(NSString *string) {
    if (!string) return nil;
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0],  result[1],  result[2],  result[3],
            result[4],  result[5],  result[6],  result[7],
            result[8],  result[9],  result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

#pragma mark - 全局map创建

static  NSMutableDictionary *_map;
static  dispatch_semaphore_t _semaphore;

static void FWDiskCacheMapInit(){
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _map = [NSMutableDictionary new];
        _semaphore = dispatch_semaphore_create(1);
    });
}

static void FWDiskCacheMapSetObject(FWDiskCache *object){
    
    FWDiskCacheMapInit();
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    [_map setObject:object forKey:object.path];
    dispatch_semaphore_signal(_semaphore);
}

static FWDiskCache* FWDiskCacheMapGetObject(NSString *path){
    
    FWDiskCacheMapInit();
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    FWDiskCache *cache = [_map objectForKey:path];
    dispatch_semaphore_signal(_semaphore);
    return cache;
}


#define Lock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define UnLock() dispatch_semaphore_signal(self->_lock)

@implementation FWDiskCache{
    
    FWKDStorage *_kd;
    dispatch_semaphore_t _lock;
    dispatch_queue_t _queue;
}

-(instancetype)initWithPath:(NSString*)path {
    
    self = [super init];
    if(!self){
        return nil;
    }
    
    FWDiskCache *cache = FWDiskCacheMapGetObject(path);
    if(cache){
        return cache;
    }
    
    _path = path;
    _countLimit = INT_MAX;
    _sizeLimit = INT_MAX;
    _expiredTimeLimit = INT_MAX;
    _autoTrimTime = 60;
    _saveWayThreshold = 20480;
    _saveWayThreshold = 150;
    
    _kd = [[FWKDStorage alloc]initWithPath:path];
    _lock = dispatch_semaphore_create(1);
    _queue = dispatch_queue_create("com.fw.fwdiskcache", DISPATCH_QUEUE_CONCURRENT);
    FWDiskCacheMapSetObject(self);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appWillBeTerminated) name:UIApplicationWillTerminateNotification object:nil];
    
    [self _trimRecursively];
    
    return self;
}

-(void)_appWillBeTerminated {
    Lock();
    _kd = nil;
    UnLock();
}

-(void)_trimRecursively {
    
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_autoTrimTime * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        __strong typeof(weakSelf) self = weakSelf;
        [self _trimInBackground];
        [self _trimRecursively];
    }); 
}

-(void)_trimInBackground {
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        __strong typeof(weakSelf) self = weakSelf;
        if(!self) return;
        Lock();
        [self _trimCount:_countLimit];
        [self _trimSize:_sizeLimit];
        [self _trimTime:_expiredTimeLimit];
        UnLock();
    });
}


-(void)_trimCount:(int)countLimit{
    
    if(countLimit == INT_MAX) return;
    [_kd removeItemsFitCount:countLimit];
}

-(void)_trimSize:(int)sizeLimit{

    if(sizeLimit == INT_MAX) return;
    [_kd removeItemsFitSize:sizeLimit];
}

-(void)_trimTime:(int)timeLimit{
    
    if(timeLimit == INT_MAX) return;
    if (timeLimit <= 0){
        [_kd removeAllItems];
        return;
    }
    int timestamp = (int)time(NULL);
    if (timestamp <= timeLimit) return;
    int age = timestamp - timeLimit;
    [_kd removeItemsEarlierThanTime:age];
}

- (BOOL)containsObjectForKey:(NSString *)key {
    
    if (!key) return NO;
    Lock();
    BOOL contains = [_kd itemExistsForKey:key];
    UnLock();
    return contains;
}

- (void)containsObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key, BOOL contains))block {
    
    if (!block) return;
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        BOOL contains = [self containsObjectForKey:key];
        block(key, contains);
    });
    
}

-(void)setObject:(id<NSCoding>)object forKey:(NSString*)key {
    
    if(key.length == 0) return;
    if(!object){
        [self removeObjectForKey:key];
        return;
    }
    
    NSData *data = nil;
    if(_customArchiveBlock){
        
        data = _customArchiveBlock(object);
        
    }else{
       
        @try {
            data = [NSKeyedArchiver archivedDataWithRootObject:object];    
        } @catch (NSException *exception) {
            
        } 
        if(!data){
            return;
        }
    }
    
        
    NSString *fileName = nil;
    if(data.length > _saveWayThreshold){
        fileName = FWNSStringMD5(key);
    }
    Lock();
    [_kd saveItemWithKey:key data:data fileName:fileName];
    UnLock();
}

-(void)setObject:(id<NSCoding>)object forKey:(NSString *)key withBlock:(void(^)(void))block {
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        __strong typeof(weakSelf) self = weakSelf;
        [self setObject:object forKey:key];
        block();
    });
    
}

-(id)objectForKey:(NSString*)key {
    
    if(!key) return nil;
    
    Lock();
    FWKDStorageItem *item = [_kd getItemForKey:key];
    UnLock();
    if(!item.data) return nil;
    id<NSCopying>object = nil;
    
    if(_customUnArchiveBlock){
        object = _customUnArchiveBlock(item.data);
    }else{
        @try {
            object = [NSKeyedUnarchiver unarchiveObjectWithData:item.data];
        } @catch (NSException *exception) {
            
        } 
    }
    return object;
}

-(void)objectForKey:(NSString *)key withBlock:(void (^)(NSString *, id<NSCopying>))block {
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        __strong typeof(weakSelf) self = weakSelf;
        id object = [self objectForKey:key];
        block(key,object);
    });    
}

-(void)removeObjectForKey:(NSString*)key {
    
    if(!key)return;
    Lock();
    [_kd removeItemForKey:key];
    UnLock();
}

-(void)removeObjectForKey:(NSString*)key withBlock:(void(^)(NSString *key))block {
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        __strong typeof(weakSelf) self = weakSelf;
        [self removeObjectForKey:key];
        block(key);
    });
    
}

-(void)remvoeAllObjects {
    
    Lock();
    [_kd removeAllItems];
    UnLock();
}


-(void)remvoeAllObjectsWithBlock:(void(^)(void))block {
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        __strong typeof(weakSelf) self = weakSelf;
        [self remvoeAllObjects];
        block();
    });
}

-(int)totalCount {
    
    Lock();
    int count = [_kd getItemsCount];
    UnLock();
    return count;
}
-(void)totalCountWithBlock:(void(^)(int count))block {
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        __strong typeof(weakSelf) self = weakSelf;
        int count = [self totalCount];
        block(count);
    });

}

-(int)totalSize {
    
    Lock();
    int size = [_kd getItemsSize];
    UnLock();
    return size;
}

-(void)totalSizeWithBlock:(void(^)(int count))block {
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        __strong typeof(weakSelf) self = weakSelf;
        int size = [self totalSize];
        block(size);
    });
}

-(void)trimToCount:(int)count {
    
    Lock();
    [self _trimCount:count];
    UnLock();
    
}

-(void)trimToCount:(int)count withBlock:(void(^)(void))block {
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        __strong typeof(weakSelf) self = weakSelf;
        [self trimToCount:count];
        block();
    });
}

-(void)trimToSize:(int)size{
    
    Lock();
    [self _trimSize:size];
    UnLock();
    
}

-(void)trimToSize:(int)size withBlock:(void(^)(void))block {
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        __strong typeof(weakSelf) self = weakSelf;
        [self trimToSize:size];
        block();
    });
}

-(void)trimToExpiredTime:(int)expiredTime {
    
    Lock();
    [self _trimTime:expiredTime];
    UnLock();
}

-(void)trimToExpiredTime:(int)expiredTime withBlock:(void(^)(void))block {
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        __strong typeof(weakSelf) self = weakSelf;
        [self trimToExpiredTime:expiredTime];
        block();
    });
}


@end








