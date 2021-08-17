//
//  HPTimer.h
//  DispatchSourceDemo
//
//  Created by ZP on 2021/8/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HPTimer : NSObject

@property (nonatomic, assign) BOOL resumeCallbackEnable;
@property (nonatomic, copy) dispatch_block_t cancelBlock;
@property (nonatomic, copy) dispatch_block_t startBlock;


+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)interval handler:(dispatch_block_t)handler;

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)interval queue:(dispatch_queue_t)queue leeway:(NSTimeInterval)leeway repeats:(BOOL)repeats handler:(dispatch_block_t)handler;

- (instancetype)initTimerWithTimeInterval:(NSTimeInterval)interval queue:(dispatch_queue_t)queue leeway:(NSTimeInterval)leeway repeats:(BOOL)repeats handler:(dispatch_block_t)handler;

- (void)start;

- (void)suspend;

- (void)resume;

- (void)cancel;

@end

NS_ASSUME_NONNULL_END
