//
//  FWPerformanceInfo.m
//  LearnDemo
//
//  Created by Lizhi on 2017/12/15.
//  Copyright © 2017年 WSX. All rights reserved.
//

#import "FWPerformanceInfo.h"

@implementation FWPerformanceInfo

-(NSString*)descriptionInMultiLines {
    
    return [NSString stringWithFormat:@"FPS:%.0f\nCPU: %.2f%%\nMem:%.2fM\n双击查看卡顿",self.fps,self.usedCpu,self.usedMemory/(1024*1024.0)];
}

-(NSString*)descriptionInOneLine {
    
    return [NSString stringWithFormat:@"FPS:%.0f    CPU: %.2f%%  Mem:%.2fM",self.fps,self.usedCpu,self.usedMemory/(1024*1024.0)];
}


@end
