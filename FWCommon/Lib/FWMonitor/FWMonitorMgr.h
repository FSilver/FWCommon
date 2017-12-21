//
//  FWMonitorMgr.h
//  LearnDemo
//
//  Created by Lizhi on 2017/12/14.
//  Copyright © 2017年 WSX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FWPerformanceInfo.h"

@interface FWMonitorMgr : NSObject

+(instancetype)sharedInstance;

-(void)start;
-(void)stop;
-(BOOL)isRunning;
-(void)reciveInfo:(void(^)(FWPerformanceInfo* info))performance;
-(void)reciveANR:(void(^)(NSArray<NSString*>* anrs))anrs;
-(void)cleanANRs;

@end
