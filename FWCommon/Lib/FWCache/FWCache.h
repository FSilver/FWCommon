//
//  FWCache.h
//  UIViewTest
//
//  Created by silver on 2017/8/30.
//  Copyright © 2017年 Fsilver. All rights reserved.
//

#import <Foundation/Foundation.h>

/***
 FWCache is a thread-safe cache.
 Used 'FWMemoryCache' to stored in memory.
 Used 'FWDiskCache' to stored in disk.
 ***/
@interface FWCache : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
-(id)initWithPath:(NSString*)path;
-(id)initWithName:(NSString*)name;

- (BOOL)containsObjectForKey:(NSString *)key;
- (void)containsObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key, BOOL contains))block;

- (id)objectForKey:(NSString *)key;
-(void)objectForKey:(NSString *)key withBlock:(void(^)(NSString *key,id<NSCopying>object))block;

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key;
- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key withBlock:(void(^)(void))block;

-(void)removeObjectForKey:(NSString*)key;
-(void)removeObjectForKey:(NSString*)key withBlock:(void(^)(NSString *key))block;

-(void)removeAllObject;
-(void)remvoeAllObjectsWithBlock:(void(^)(void))block;

@end
