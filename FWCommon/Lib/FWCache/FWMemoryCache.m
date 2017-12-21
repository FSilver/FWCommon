
//
//  FWMemoryCache.m
//  UIViewTest
//
//  Created by silver on 2017/8/30.
//  Copyright © 2017年 Fsilver. All rights reserved.
//

#import "FWMemoryCache.h"
#import <pthread.h>
#import <UIKit/UIKit.h>

@interface FWLinkNode : NSObject

@property(nonatomic,strong)NSString *key;
@property(nonatomic,strong)id object;
@property(nonatomic,assign)int size;
@property(nonatomic,assign)NSTimeInterval time;
@property(nonatomic,weak)FWLinkNode *prev;
@property(nonatomic,weak)FWLinkNode *next;

@end

@implementation FWLinkNode
@end


@interface FWLinkMap : NSObject 

@property(nonatomic,strong)NSMutableDictionary *cacheDict;
@property(nonatomic,strong)FWLinkNode *head;
@property(nonatomic,strong)FWLinkNode *tail;

@property(nonatomic,assign)int totalCount;
@property(nonatomic,assign)int totalSize;

-(void)insertNodeToHead:(FWLinkNode*)node;
-(void)bringNodeToHead:(FWLinkNode*)node;
-(void)removeNode:(FWLinkNode*)node;
-(void)removeAll;

@end

@implementation FWLinkMap

-(id)init{
    
    self = [super init];
    if(self){
        
        _cacheDict = [NSMutableDictionary new];
        _totalCount = 0;
        _totalSize = 0;
        _head = nil;
        _tail = nil;
    }
    return self;
}

-(void)insertNodeToHead:(FWLinkNode*)node {
    
    [_cacheDict setObject:node forKey:node.key];
    _totalCount++;
    _totalSize += node.size;
    if(_head){
        
         node.next = _head;
        _head.prev = node;
        _head = node;
    }else{
        _head = _tail = node;
    }
}

-(void)bringNodeToHead:(FWLinkNode*)node {
    
    if(_head == node){
        return;
    }
    
    if(_tail == node){
        _tail = node.prev;
        _tail.next = nil;
        
    }else{
        
        node.prev.next = node.next;
        node.next.prev = node.prev;
    }
    
    node.prev = nil;
    node.next = _head;
    _head.prev = node;
    _head = node;
}

-(void)removeNode:(FWLinkNode *)node {
    
    [_cacheDict removeObjectForKey:node.key];
    _totalCount--;
    if(_head == node){
        node.next.prev = nil;
        _head = node.next;
    }
    
    if(_tail == node){
        node.prev.next = nil;
        _tail = node.prev;
        node = nil;
    }
    
    node.prev.next = node.next;
    node.next.prev = node.prev;
    node = nil;
}

-(void)removeAll {
    
    _totalCount = 0;
    _totalSize = 0;
    [_cacheDict removeAllObjects];
    _head = nil;
    _tail = nil;
}


@end

@implementation FWMemoryCache {
    
    FWLinkMap *_map;
    pthread_mutex_t _lock;
    dispatch_queue_t _queue;
    
}

-(id)init{
    
    self = [super init];
    if(self){
        
        _map = [[FWLinkMap alloc]init];
        pthread_mutex_init(&_lock, NULL);
        _queue = dispatch_queue_create("com.ibireme.cache.memory", DISPATCH_QUEUE_SERIAL);
        
        _autoTrimInterval = 60;
        _countLimit = INT_MAX;
        _expiredTimeLimit = INT_MAX;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidReceiveMemoryWarningNotification) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackgroundNotification) name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        [self trimRecursively];
    }
    return self;
}

-(void)appDidReceiveMemoryWarningNotification {
    
    [self removeAllObjects];
}

-(void)appDidEnterBackgroundNotification {
    [self removeAllObjects];
}


-(void)trimRecursively {
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_autoTrimInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self trimInBackground];
        [self trimRecursively];
    });
}

-(void)trimInBackground {
    
    dispatch_async(_queue, ^{
        [self trimToCount:_countLimit];
        [self trimToTime:_expiredTimeLimit];
    });
}


-(BOOL)containsObjectForKey:(id)key {
    if(!key) return NO;
    pthread_mutex_lock(&_lock);
    id obj = [_map.cacheDict objectForKey:key];
    pthread_mutex_unlock(&_lock);
    return obj?YES:NO;
}

-(id)objectForKey:(NSString*)key {
    
    if(!key) return nil;
    pthread_mutex_lock(&_lock);
    
    FWLinkNode *node = [_map.cacheDict objectForKey:key];
    if(node){
        node.time = (int)time(NULL);
        [_map bringNodeToHead:node];
    }
    pthread_mutex_unlock(&_lock);
    return node?node.object:nil;
}


-(void)setObject:(id)object forKey:(NSString*)key {
    
    if(!key) return;
    if(!object){
        [self removeObjectForKey:key];
        return;
    }
    
    pthread_mutex_lock(&_lock);
    
    FWLinkNode *node = [_map.cacheDict objectForKey:key];
    if(node){
        
        node.object = object;
        node.time = (int)time(NULL);
        [_map bringNodeToHead:node];
        
    }else{
        
        FWLinkNode *node = [FWLinkNode new];
        node.key = key;
        node.object = object;
        node.time = (int)time(NULL);
        [_map insertNodeToHead:node];
    }
    pthread_mutex_unlock(&_lock);
}

-(void)removeObjectForKey:(NSString*)key {
    
    if(!key) return;
    pthread_mutex_lock(&_lock);
    FWLinkNode *node = [_map.cacheDict objectForKey:key];
    if(node){
        [_map removeNode:node];
    }
    pthread_mutex_unlock(&_lock);
}

- (void)removeAllObjects {
    pthread_mutex_lock(&_lock);
    [_map removeAll];
    pthread_mutex_unlock(&_lock);
}


- (void)trimToCount:(NSUInteger)count {
    
    if(count == 0){
        [self removeAllObjects];
        return;
    }
    
    pthread_mutex_lock(&_lock);
    while (_map.totalCount > count) {
        
        FWLinkNode *node = _map.tail;
        [_map removeNode:node];
    }
    pthread_mutex_unlock(&_lock);
}

- (void)trimToTime:(NSTimeInterval)expiredTimeLimit {
    
    if(expiredTimeLimit <= 0){
        [self removeAllObjects];
        return;
    }
    
    if(expiredTimeLimit == INT_MAX){
        return;
    }
    int time1 = (int)time(NULL);
    int time2 = time1 - expiredTimeLimit;
    if(time2 <= 0){
        return;
    }
    
    pthread_mutex_lock(&_lock);
    while (1) {
        FWLinkNode *node = _map.tail;
        if(!node) break;
        if(node.time > time2){
            break;
        }else{
            [_map removeNode:node];
        }
    }
    pthread_mutex_unlock(&_lock);
    
}


@end



















































