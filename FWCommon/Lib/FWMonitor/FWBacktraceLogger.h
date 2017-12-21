//
//  FWBacktraceLogger.h
//  LearnDemo
//
//  Created by Lizhi on 2017/12/15.
//  Copyright © 2017年 WSX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FWBacktraceLogger : NSObject

+ (NSString *)fw_backtraceOfAllThread;
+ (NSString *)fw_backtraceOfCurrentThread;
+ (NSString *)fw_backtraceOfMainThread;
+ (NSString *)fw_backtraceOfNSThread:(NSThread *)thread;

@end
