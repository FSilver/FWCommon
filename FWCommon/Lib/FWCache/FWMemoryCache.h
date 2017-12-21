//
//  FWMemoryCache.h
//  UIViewTest
//
//  Created by silver on 2017/8/30.
//  Copyright © 2017年 Fsilver. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FWMemoryCache : NSObject

@property(nonatomic,assign)NSUInteger countLimit;
@property(nonatomic,assign)NSTimeInterval expiredTimeLimit;
@property(nonatomic,assign) NSTimeInterval autoTrimInterval;

-(BOOL)containsObjectForKey:(id)key;

-(id)objectForKey:(NSString*)key;

-(void)setObject:(id)object forKey:(NSString*)key;

-(void)removeObjectForKey:(NSString*)key;

- (void)removeAllObjects;

- (void)trimToCount:(NSUInteger)count;

- (void)trimToTime:(NSTimeInterval)expiredTimeLimit;

@end
