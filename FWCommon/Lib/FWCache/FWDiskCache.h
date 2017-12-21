//
//  FWDiskCache.h
//  UIViewTest
//
//  Created by silver on 2017/8/28.
//  Copyright © 2017年 Fsilver. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 FWDiskCache is thread-safe cache that saved key-value paires by sqlite or file system.
 **/
@interface FWDiskCache : NSObject

@property(nonatomic,readonly)NSString *path;

/**
 If the object's data bytes is larger than this value ,data will be saved to file.
 Else data will be saved to sqlite.
 Default is 20480 (20kb).
 **/
@property(nonatomic,assign)int saveWayThreshold;

/**
 The maximum number of objects the cache should hold.
 If the cache goes over the limit,some of objects will be evicted later in background queue.
 **/
@property(nonatomic,assign)int countLimit;

/**
 The maximu total size of objects the cache should hold.
 If the cache goes over the limit,some of objects will be evicted later in background queue.
 **/
@property(nonatomic,assign)int sizeLimit;

/**
 The maximum expiry time of objects in cache
 If the cache goes over the limit,some of objects will be evicted later in background queue.
 **/
@property(nonatomic,assign)NSTimeInterval expiredTimeLimit;

/**
 The auto trim time interval in seconds. 
 Default is 60 (1 minute).
 **/
@property(nonatomic,assign)NSTimeInterval autoTrimTime;

@property(nonatomic,copy)NSData *(^customArchiveBlock)(id object);
@property(nonatomic,copy)id (^customUnArchiveBlock)(NSData* data);

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
-(instancetype)new UNAVAILABLE_ATTRIBUTE;

-(instancetype)initWithPath:(NSString*)path;

- (BOOL)containsObjectForKey:(NSString *)key;
- (void)containsObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key, BOOL contains))block;

-(void)setObject:(id<NSCoding>)object forKey:(NSString*)key;
-(void)setObject:(id<NSCoding>)object forKey:(NSString *)key withBlock:(void(^)(void))block;

-(id<NSCopying>)objectForKey:(NSString*)key;
-(void)objectForKey:(NSString *)key withBlock:(void(^)(NSString *key,id<NSCopying>object))block;

-(void)removeObjectForKey:(NSString*)key;
-(void)removeObjectForKey:(NSString*)key withBlock:(void(^)(NSString *key))block;

-(void)remvoeAllObjects;
-(void)remvoeAllObjectsWithBlock:(void(^)(void))block;

-(int)totalCount;
-(void)totalCountWithBlock:(void(^)(int count))block;

-(int)totalSize;
-(void)totalSizeWithBlock:(void(^)(int count))block;

#pragma mark - Limit

-(void)trimToCount:(int)count;
-(void)trimToCount:(int)count withBlock:(void(^)(void))block;

-(void)trimToSize:(int)size;
-(void)trimToSize:(int)size withBlock:(void(^)(void))block;

-(void)trimToExpiredTime:(int)expiredTime;
-(void)trimToExpiredTime:(int)expiredTime withBlock:(void(^)(void))block;

@end
