//
//  FWPerformanceInfo.h
//  LearnDemo
//
//  Created by Lizhi on 2017/12/15.
//  Copyright © 2017年 WSX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FWPerformanceInfo : NSObject

/**
 *  获取应用当前的刷新帧率，为 0 到 60 之间的数
 */
@property (nonatomic, assign) float fps;

/**
 *  获取当前应用的 CPU 占用率 0 ~ 100
 */
@property (nonatomic, assign) float usedCpu;

/**
 *  获取当前应用使用的内存值，单位为字节 byte
 */
@property (nonatomic, assign) float usedMemory;

-(NSString*)descriptionInMultiLines;

-(NSString*)descriptionInOneLine;

@end
