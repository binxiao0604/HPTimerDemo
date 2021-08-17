//
//  ViewController.m
//  DispatchSourceDemo
//
//  Created by ZP on 2021/8/17.
//

#import "ViewController.h"
#import "HPTimer.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (nonatomic, strong) dispatch_source_t source;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, assign) NSUInteger completed;
@property (nonatomic) BOOL isRunning;

@property (nonatomic, strong) HPTimer *timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self testDispatchSource];
    [self testTimer];
}

- (void)testTimer {
    //1.
    self.timer = [HPTimer scheduledTimerWithTimeInterval:3 handler:^{
        NSLog(@"timer 回调");
    }];
    
//    //2.
//    self.timer = [[HPTimer alloc] initTimerWithTimeInterval:5 queue:dispatch_get_main_queue() leeway:0 repeats:YES handler:^{
//        NSLog(@"block 回调");
//    }];
//
//    [self.timer start];
}

- (void)testDispatchSource {
    /*
    type: dispatch 源可处理的事件。 DISPATCH_SOURCE_TYPE_TIMER  DISPATCH_SOURCE_TYPE_DATA_ADD
        DISPATCH_SOURCE_TYPE_DATA_ADD:
            将所有触发结果相加，最后统一执行响应。
            间隔的时间越长，则每次触发都会响应；如果间隔的时间很短，则会将触发后的结果相加后统一触发。
    handle:可以理解为句柄、索引或id，如果要监听进程，需要传入进程的ID。
    mask:可以理解为描述，提供更详细的描述，让它知道具体要监听什么
    queue:处理源的队列
    */
    
    self.completed = 0;
    self.queue = dispatch_queue_create("HotpotCat", NULL);
    self.source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
    //设置句柄
    dispatch_source_set_event_handler(self.source, ^{
        NSLog(@"%@",[NSThread currentThread]);
        NSUInteger value = dispatch_source_get_data(self.source);
        if (value > 1) {
            NSLog(@"value > 1 : %@",@(value));
        }
        self.completed += value;
        double progress = self.completed / 100.0;
        NSLog(@"progress: %.2f",progress);
        self.progressView.progress = progress;
    });
    self.isRunning = YES;
    //创建后默认是挂起状态
    dispatch_resume(self.source);
}

- (IBAction)didClickPauseButtonAction:(id)sender {
    if (self.isRunning) {
        dispatch_suspend(self.source);
        dispatch_suspend(self.queue);
        NSLog(@"pause");
        self.isRunning = NO;
        [sender setTitle:@"pause" forState:UIControlStateNormal];
    } else {
        dispatch_resume(self.source);
        dispatch_resume(self.queue);
        NSLog(@"running");
        self.isRunning = YES;
        [sender setTitle:@"running" forState:UIControlStateNormal];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"start");
    for (NSInteger i = 0; i < 100; i++) {
        dispatch_async(self.queue, ^{
            NSLog(@"merge");
            //加不加 sleep 影响 handler 的执行次数。
            sleep(1);
            dispatch_source_merge_data(self.source, 1);//+1
        });
    }
}



@end
