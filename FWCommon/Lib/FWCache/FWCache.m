//
//  FWCache.m
//  UIViewTest
//
//  Created by silver on 2017/8/30.
//  Copyright © 2017年 Fsilver. All rights reserved.
//

#import "FWCache.h"
#import "FWDiskCache.h"
#import "FWMemoryCache.h"

@interface FWCache()
{
    FWDiskCache *_diskCahce;
    FWMemoryCache *_memoryCache;
}

@end

@implementation FWCache

-(id)initWithPath:(NSString*)path {
    
    if (path.length == 0) return nil;
    self = [super init];
    if(!self) return nil;
    NSLog(@"%@",path);
    _diskCahce = [[FWDiskCache alloc]initWithPath:path];
    _memoryCache = [FWMemoryCache new];

    return self;
}

-(id)initWithName:(NSString*)name {
    
    if (name.length == 0) return nil;
    NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *path = [cacheFolder stringByAppendingPathComponent:name];
    return [self initWithPath:path];
}

- (BOOL)containsObjectForKey:(NSString *)key {
    
    return [_memoryCache containsObjectForKey:key] || [_diskCahce containsObjectForKey:key];
}

- (void)containsObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key, BOOL contains))block {
    if (!block) return;
    if ([_memoryCache containsObjectForKey:key]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            block(key,YES); 
        });
        
    }else{
        [_diskCahce containsObjectForKey:key withBlock:block];
    }
}

- (id)objectForKey:(NSString *)key {
    
    if(!key) return nil;
    id object = [_memoryCache objectForKey:key];
    if(!object){
        object = [_diskCahce objectForKey:key];
        if(object){
            [_memoryCache setObject:object forKey:key];
        }
    }
    return object;
}

-(void)objectForKey:(NSString *)key withBlock:(void(^)(NSString *key,id<NSCopying>object))block {
    
    id object = [_memoryCache objectForKey:key];
    if(object){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            block(key,object);
        });
    }else{
        [_diskCahce objectForKey:key withBlock:^(NSString *key, id<NSCopying> object) {
            if(key){
                [_memoryCache setObject:object forKey:key];
            }
            block(key,object);
        }];
    }
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key {
    
    [_memoryCache setObject:object forKey:key];
    [_diskCahce setObject:object forKey:key];
    
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key withBlock:(void(^)(void))block {
    [_memoryCache setObject:object forKey:key];
    [_diskCahce setObject:object forKey:key withBlock:block];
}

-(void)removeObjectForKey:(NSString*)key {
    
    [_memoryCache removeObjectForKey:key];
    [_diskCahce removeObjectForKey:key];
}

-(void)removeObjectForKey:(NSString*)key withBlock:(void(^)(NSString *key))block {
    
    [_memoryCache removeObjectForKey:key];
    [_diskCahce removeObjectForKey:key withBlock:block];
}

-(void)removeAllObject {
    [_memoryCache removeAllObjects];
    [_diskCahce remvoeAllObjects];
}
-(void)remvoeAllObjectsWithBlock:(void(^)(void))block {
    
    [_memoryCache removeAllObjects];
    [_diskCahce remvoeAllObjectsWithBlock:block];
}

@end
