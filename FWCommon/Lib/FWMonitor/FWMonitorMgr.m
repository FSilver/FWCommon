//
//  FWMonitorMgr.m
//  LearnDemo
//
//  Created by Lizhi on 2017/12/14.
//  Copyright © 2017年 WSX. All rights reserved.
//

#import "FWMonitorMgr.h"
#import <UIKit/UIKit.h>
#include <mach/mach.h>
#include <mach/task_info.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#import "FWBacktraceLogger.h"

static NSTimeInterval  anr_time_out_interval = 0.1;

typedef void (^DataBlock)(FWPerformanceInfo* info);
typedef void (^ANRBlock)(NSArray* anrs);

@interface FWMonitorMgr()
{
    //fps 相关
    CADisplayLink *_fpsLink;
    NSUInteger _count;
    NSTimeInterval _lastTime;
    float _fpsValue;
    
    //事件源: 0.5s一次的定时器
    dispatch_source_t  _loopSource;
    
    //性能汇总
    FWPerformanceInfo *_performanceInfo;
    
    //判断是否在运行
    BOOL _isRunning;
    
    //卡顿检测
    dispatch_queue_t  _anr_queue;
    dispatch_semaphore_t _semphore;
    NSMutableArray *_anrArray;
    BOOL _watch;
}
@property(nonatomic,copy)DataBlock dataBlock;
@property(nonatomic,copy)ANRBlock anrBlock;

@end

@implementation FWMonitorMgr

+(instancetype)sharedInstance
{
    static FWMonitorMgr *_mgr = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _mgr = [[FWMonitorMgr alloc]init];
    });
    return _mgr;
}


-(id)init
{
    self = [super init];
    if(self){
        _performanceInfo = [[FWPerformanceInfo alloc]init];
        _anr_queue = dispatch_queue_create("com.lizhi.fm.lz_event_monitor_queue", NULL);
        _semphore = dispatch_semaphore_create(0);
        _anrArray = [NSMutableArray array];
    }
    return self;
}

-(void)start {
    _isRunning = YES;
    [self startFpsDisplayLink];
    [self startLoopForMemoryAndCpu];
    [self startWatchANR];
}

-(void)stop {
    
    [self stopFpsDisplayLink];
    [self stopLoopForMemoryAndCpu];
    [self stopWatcch];
    _isRunning = NO;
}

-(BOOL)isRunning
{
    return _isRunning;
}

-(void)reciveInfo:(void(^)(FWPerformanceInfo* info))performance
{
    self.dataBlock = performance;
}

-(void)reciveANR:(void (^)(NSArray<NSString *> *))anrs
{
    self.anrBlock = anrs;
}

#pragma mark - 间隔循环获取 cpu  memroy

-(void)startLoopForMemoryAndCpu {
    
    if(_loopSource){
        return;
    }
    __weak typeof(self) _self = self;
    _loopSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    dispatch_source_set_timer(_loopSource, dispatch_walltime(NULL, 0), 0.5f * NSEC_PER_SEC, 0);//等待0s后开始，0.5s的间隔，0s的误差
    dispatch_source_set_event_handler(_loopSource, ^{
        __strong typeof(_self) self = _self;
    
        _performanceInfo.usedCpu = [self getUsedCPU];
        _performanceInfo.usedMemory = [self getUsedMemory];
        _performanceInfo.fps = _fpsValue;
        dispatch_async(dispatch_get_main_queue(), ^{
            if(self.dataBlock){
                self.dataBlock(_performanceInfo);
            }
        });
    });
    //开启source
    dispatch_resume(_loopSource);
}

-(void)stopLoopForMemoryAndCpu {
    
    if(_loopSource){
        dispatch_source_cancel(_loopSource);
        _loopSource = nil;
    }
}

#pragma mark - cpu 信息获取
- (float)getUsedCPU
{
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0)
        stat_thread += thread_count;
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    for (j = 0; j < thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->system_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
        
    } // for each thread
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    
    return tot_cpu;
}

#pragma mark - memory 信息获取
- (vm_size_t)getUsedMemory
{
    struct mach_task_basic_info info;
    mach_msg_type_number_t size = MACH_TASK_BASIC_INFO_COUNT;
    kern_return_t kerr = task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &size);
    return (kerr == KERN_SUCCESS) ? info.resident_size : 0; // size in bytes
}


#pragma mark - FPS 获取

- (void)startFpsDisplayLink
{
    if (!_fpsLink) {
        _fpsLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
        [_fpsLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)stopFpsDisplayLink
{
    if(_fpsLink){
        [_fpsLink invalidate];
        _fpsLink = nil;
    }
}

- (void)tick:(CADisplayLink *)displayLink
{
    if (0 == _lastTime) {
        _lastTime = displayLink.timestamp;
        return;
    }
    
    _count ++;
    NSTimeInterval delta = displayLink.timestamp - _lastTime;
    if (delta < 1) {
        return;
    }
    _fpsValue = _count / delta;
    _lastTime = displayLink.timestamp;
    _count = 0;
}


#pragma mark - 获取主线程 卡顿堆栈

-(void)startWatchANR
{
    _watch = YES;
    dispatch_async(_anr_queue, ^{
        while (_watch) {
            __block BOOL timeOut = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                timeOut = NO;
                dispatch_semaphore_signal(_semphore);
            });
            //等待主线程0.1s,若果主线程 执行某个人物超过了0.1s ，那么timeOut = YES,说明有卡顿
            [NSThread sleepForTimeInterval: anr_time_out_interval];
            if(timeOut){
                
                NSString *start = @"--------------ANR start--------------------";
                
                NSString *time = [self dateOfNow];
                NSString *perStr = [_performanceInfo descriptionInOneLine];
                
                NSString *main = @"\n\nMainThread:";
                NSString *mainThreadStr = [FWBacktraceLogger fw_backtraceOfMainThread];
                
                NSString *all = @"\nallThread:";
                NSString *allThreadStr = [FWBacktraceLogger fw_backtraceOfAllThread];
                
                NSString *end = @"--------------ANR end--------------------";
                
                NSString *text = [NSString stringWithFormat:@"\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n",start,time,perStr,main,mainThreadStr,all,allThreadStr,end];
                
                [_anrArray addObject:text];
                
                [self writeLog:text];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(self.anrBlock){
                        self.anrBlock(_anrArray);
                    }
                });
                dispatch_wait(_semphore, DISPATCH_TIME_FOREVER);
            }
        }
    });
}


-(void)cleanANRs
{
    [_anrArray removeAllObjects];
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.anrBlock){
            self.anrBlock(_anrArray);
        }
    });
}

-(void)stopWatcch
{
    _watch = NO;
}

-(NSString*)dateOfNow
{
    NSDate *currentDate = [NSDate date];
    //用于格式化NSDate对象
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //设置格式：zzz表示时区
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss SSS"];
    return [dateFormatter stringFromDate:currentDate];
}

-(void)writeLog:(NSString*)log
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    path = [path stringByAppendingPathComponent:[self dateOfNow]];
    [log writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
  
}



@end
