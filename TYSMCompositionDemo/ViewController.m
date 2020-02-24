//
//  ViewController.m
//  TYSMCompositionDemo
//
//  Created by jele lam on 23/2/2020.
//  Copyright © 2020 CookiesJ. All rights reserved.
//

#import "ViewController.h"
#import "TYSMPlayerGLView.h"
#import "TYSMPlayerController.h"
#import "TYSMMediaEditView.h"
#import "TYSMTranscoder.h"

@interface ViewController () <TYSMPlayerDelegate,TYSMMediaEditViewDelegate>
/// 画面展示
@property (weak, nonatomic) IBOutlet TYSMPlayerGLView *playerGLView;
/// 播放器组件
@property (nonatomic, strong) TYSMPlayerController *playerController;

/// 多媒体创作
@property (nonatomic, strong) AVMutableComposition *mComposition;
/// 视频创作轨道
@property (nonatomic, strong) AVMutableCompositionTrack *mCompositionVideoTrack;
/// 音频创作轨道
@property (nonatomic, strong) AVMutableCompositionTrack *mCompositionAudioTrack;

/// 底部编辑 view
@property (weak, nonatomic) IBOutlet TYSMMediaEditView *mediaEditView;

/// 转码器
@property (nonatomic, strong) TYSMTranscoder *transcoder;
@end

@implementation ViewController

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
//    [self.playerGLView configureOpenGLES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mComposition = [AVMutableComposition composition];
    // 创建视频创作轨道
    self.mCompositionVideoTrack = [self.mComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    // 创建音频创作轨道
    self.mCompositionAudioTrack = [self.mComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    
    // Create the audio composition track.
    NSString *videoPathA = [[NSBundle mainBundle] pathForResource:@"A" ofType:@"MOV"];
    NSString *videoPathB = [[NSBundle mainBundle] pathForResource:@"B" ofType:@"MP4"];
    
    AVAsset *assetA = [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPathA]];
    AVAsset *assetB = [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPathB]];
    
    // Get the first video track from each asset.
    AVAssetTrack *videoAssetTrackA = [[assetA tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVAssetTrack *videoAssetTrackB = [[assetB tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    AVAssetTrack *audioAssetTrackA = [[assetA tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    AVAssetTrack *audioAssetTrackB = [[assetB tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    // Add them both to the composition.
    NSError *error = nil;
    
    [self.mCompositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,videoAssetTrackA.timeRange.duration)
                                         ofTrack:videoAssetTrackA
                                          atTime:kCMTimeZero
                                           error:&error];
        NSAssert1(error == nil, @"%@", error);

    // 在 videoAssetTrackA 后面插入 videoAssetTrackB
    [self.mCompositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,videoAssetTrackB.timeRange.duration)
                                         ofTrack:videoAssetTrackB
                                          atTime:videoAssetTrackA.timeRange.duration
                                           error:&error];
    NSAssert1(error == nil, @"%@", error);

    
    // 同理也可以按顺序批量添加多个轨道
    NSArray <NSValue *> * timeRanges =@[
        [NSValue valueWithCMTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrackA.timeRange.duration)],
        [NSValue valueWithCMTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrackB.timeRange.duration)]
    ];
    NSArray <AVAssetTrack *> *audioTracks = @[audioAssetTrackA,audioAssetTrackB];
    
    [self.mCompositionAudioTrack insertTimeRanges:timeRanges
                                         ofTracks:audioTracks
                                           atTime:kCMTimeZero
                                            error:&error];
    NSAssert1(error == nil, @"%@", error);

    NSLog(@"总长：%@",[NSValue valueWithCMTime:self.mComposition.duration]);
    self.playerController = [[TYSMPlayerController alloc] initWithDelegate:self];
    
    [self.playerController configureAsset:[self.mComposition copy] FPS:TYSMPlayerFPS30];
    
    self.mediaEditView.delegate = self;
    // Do any additional setup after loading the view.
}

#pragma mark - edit
- (void)removeFromTimeRange:(CMTimeRange)timeRange {
    
//    [self.mCompositionVideoTrack removeTimeRange:timeRange];
//    [self.mCompositionAudioTrack removeTimeRange:timeRange];
    // ↓↓↓ 两种方法都可以用 ↑↑↑
    [self.mComposition removeTimeRange:timeRange];
    
    [self.playerController configureAsset:[self.mComposition copy] FPS:TYSMPlayerFPS30];
}

- (void)appendFromAsset:(AVAsset *)asset {
    
    //    与之不同的是，用 self.mComposition 直接追加视频 insertTimeRange 的话，
    //    默认是以添加轨道的形式 addMutableTrackWithMediaType ，可以看到数组会有两个以上的轨道。
    //    [self.mComposition insertTimeRange:timeRange ofAsset:asset atTime:self.mComposition.duration error:&error];
    
    CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    CMTime atTime = self.mComposition.duration;
    NSError *error = nil;
    NSLog(@"总长：%@",[NSValue valueWithCMTime:atTime]);

    AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVAssetTrack *audioAssetTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    [self.mCompositionVideoTrack insertTimeRange:timeRange ofTrack:videoAssetTrack atTime:atTime error:&error];
    NSAssert1(error == nil, @"%@", error);
    [self.mCompositionAudioTrack insertTimeRange:timeRange ofTrack:audioAssetTrack atTime:atTime error:&error];
    NSAssert1(error == nil, @"%@", error);

    [self.playerController configureAsset:[self.mComposition copy] FPS:TYSMPlayerFPS30];
}

#pragma mark - 底部编辑view delegate
- (void)handlePlayerButton:(BOOL)isPlay {
    if (isPlay) {
        [self.playerController play];
    } else {
        [self.playerController pause];
    }
}

- (void)handleScrollOffset:(CGFloat)offset {
    [self.playerController seekToTime:CMTimeMakeWithSeconds(offset/100*5, kTimeScale)];
}

- (void)handleSplitRange {
    [self handlePlayerButton:NO];
    [self removeFromTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(20, kTimeScale))];
}

- (void)handleAppendVideo {
    NSString *videoPathA = [[NSBundle mainBundle] pathForResource:@"A" ofType:@"MOV"];
    AVAsset *assetA = [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPathA]];
    
    [self appendFromAsset:assetA];
    
}
#pragma mark - 播放器控制器 delegate
- (void)outputCVPixelBuffer:(CVPixelBufferRef)pixelBuffer currentTime:(CMTime)currentTime {
    [_playerGLView displayPixelBuffer:pixelBuffer];
}

// 回调信息
- (void)playerComponentMediaInfo:(NSDictionary *)info {
    NSLog(@"%@",info);
    NSMutableArray <UIImage *>*imageArray = [NSMutableArray array];
    
    // 生成底部 幻灯片
    [self.playerController getVideoFrameWithInterval:5 processing:^(UIImage * _Nonnull image, NSInteger idx, NSInteger count) {
        [imageArray addObject:image];
        if (count-1 == idx) {
            [self.mediaEditView buildScrubber:imageArray];
            [self.playerController play];
        }
    }];
}

- (void)playerComponentPeriodicTime:(CGFloat)time {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mediaEditView updateTimeLabel:[self convertTime:time]];
        [self.mediaEditView setScroll:time*10*2];
    });
}

- (void)playToEndTime {
    [self.playerController seekToTime:kCMTimeZero];
}

#pragma mark - util
- (NSString *)convertTime:(CGFloat)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"mm:ss.SS"];
    NSString *showtimeNew = [formatter stringFromDate:d];
    return showtimeNew;
}

- (CGFloat )convertString:(NSString *)timeString{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"mm:ss.SS"];
    NSDate *date = [formatter dateFromString:timeString];
    NSLog(@"%@",[self convertTime:[date timeIntervalSinceNow]]);
    return [[formatter dateFromString:timeString] timeIntervalSince1970];
}

- (IBAction)tapTranscodeButton:(UIBarButtonItem)sender {
    
    NSString *outputPath = [NSTemporaryDirectory() stringByAppendingString:@"output.mp4"];
    NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];

    [self.mediaEditView setUserInteractionEnabled:NO];
    [sender setEnabled:NO];
    // 暂停
    [self handlePlayerButton:NO];
    
    
    self.transcoder = [[TYSMTranscoder alloc] initWithAsset:[self.mComposition copy] toFileURL:outputURL];
    
    __weak typeof(self)weakself = self;
    [self.transcoder startTranscode:^(NSString * _Nonnull outputFilePath) {
        [weakself.transcoder saveToAlbumWithFilePath:outputFilePath];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.mediaEditView setUserInteractionEnabled:YES];
            [weakself.mediaEditView updateProgress:0];
            [sender setEnabled:YES];
        });
    } videoProgress:^(double progress) {
        NSLog(@"%.1lf",progress);
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.mediaEditView updateProgress:progress/100];
        });
    } audioProgress:^(double progress) {
        NSLog(@"%.1lf",progress);
    }];
}
@end
