//
//  HPTimer.m
//  DispatchSourceDemo
//
//  Created by ZP on 2021/8/17.
//

#import "HPTimer.h"

typedef NS_ENUM(NSUInteger, HPTimerStatus) {
    HPTimerSuspend = 0,
    HPTimerResume = 1,
    HPTimerCanceled = 99,
};

@interface HPTimer()

@property (nonatomic, strong) dispatch_source_t timer;

@property (nonatomic, assign) BOOL isAutoFirstCallback;
@property (nonatomic, assign) BOOL isResumeCallback;
@property (nonatomic, assign) BOOL isStarted;
@property (nonatomic, assign) HPTimerStatus timerStatus;

@end

@implementation HPTimer

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)interval handler:(dispatch_block_t)handler {
    return [self scheduledTimerWithTimeInterval:interval queue:dispatch_get_global_queue(0, 0) leeway:0 repeats:YES handler:handler];
}

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)interval queue:(dispatch_queue_t)queue leeway:(NSTimeInterval)leeway repeats:(BOOL)repeats handler:(dispatch_block_t)handler {
    HPTimer *timer = [[self alloc] initTimerWithTimeInterval:interval queue:queue leeway:leeway repeats:repeats handler:handler];
    [timer start];
    return timer;
}

- (instancetype)initTimerWithTimeInterval:(NSTimeInterval)interval queue:(dispatch_queue_t)queue leeway:(NSTimeInterval)leeway repeats:(BOOL)repeats handler:(dispatch_block_t)handler {
    /*
    source:事件源
    start:控制计时器第一次触发的时刻。
          - 参数类型是 dispatch_time_t（opaque类型），不能直接操作它。需要 dispatch_time 和 dispatch_walltime 函数来创建。
          - 常量 DISPATCH_TIME_NOW 和 DISPATCH_TIME_FOREVER 很有用。
          - 当使用dispatch_time 或者 DISPATCH_TIME_NOW 时，系统会使用默认时钟来进行计时。然而当系统休眠的时候，默认时钟是不走的，也就会导致计时器停止。使用 dispatch_walltime 可以让计时器按照真实时间间隔进行计时。
    interval:间隔时间
    leeway:计时器触发的精准程度，就算指定为0系统也无法保证完全精确的触发时间，只是会尽可能满足这个需求。
    */
    
    if (self == [super init]) {
        self.isAutoFirstCallback = YES;
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_source_set_timer(self.timer, dispatch_walltime(NULL, 0), interval * NSEC_PER_SEC, leeway * NSEC_PER_SEC);
        //解决与handler互相持有
        __weak typeof(self) weakSelf = self;
        //启动事件
        dispatch_source_set_registration_handler(self.timer, ^{
            if (weakSelf.startBlock) {
                weakSelf.startBlock();
            }
        });

        //事件回调，这个函数在执行完之后 block 会立马执行一遍。后面隔一定时间间隔再执行一次。
        dispatch_source_set_event_handler(self.timer, ^{
            //忽略 handler 设置完马上回调
            if (weakSelf.isAutoFirstCallback) {
                @synchronized(weakSelf) {
                    weakSelf.isAutoFirstCallback = NO;
                }
                return;
            }
            //忽略挂起恢复后的立马回调
            if (!weakSelf.resumeCallbackEnable && weakSelf.isResumeCallback) {
                @synchronized(weakSelf) {
                    weakSelf.isResumeCallback = NO;
                }
                return;
            }
            if (handler) {
                handler();
            }
            if (!repeats) {
                //repeats 为 NO 执行一次后取消
                [weakSelf cancel];
            }
        });

        //取消回调
        dispatch_source_set_cancel_handler(self.timer, ^{
            if (weakSelf.cancelBlock) {
                weakSelf.cancelBlock();
            }
        });
    }
    return self;
}

- (void)start {
    //为了与isResumeCallback区分开
    @synchronized(self) {
        if (!self.isStarted && self.timerStatus == HPTimerSuspend) {
            self.isStarted = YES;
            self.timerStatus = HPTimerResume;
            dispatch_resume(self.timer);
        }
    }
}

- (void)suspend {
    //挂起，挂起的时候不能设置timer为nil
    @synchronized(self) {
        if (self.timerStatus == HPTimerResume) {
            self.timerStatus = HPTimerSuspend;
            dispatch_suspend(self.timer);
        }
    }
}

- (void)resume {
    //恢复
    @synchronized(self) {
        if (self.timerStatus == HPTimerSuspend) {
            self.isResumeCallback = YES;
            self.timerStatus = HPTimerResume;
            dispatch_resume(self.timer);
        }
    }
}

- (void)cancel {
    //取消
    @synchronized(self) {
        if (self.timerStatus != HPTimerCanceled) {
            //先恢复再取消
            if (self.timerStatus == HPTimerSuspend) {
                [self resume];
            }
            self.timerStatus = HPTimerCanceled;
            dispatch_source_cancel(self.timer);
            _timer = nil;
        }
    }
}

- (void)dealloc {
    [self cancel];
}

@end
