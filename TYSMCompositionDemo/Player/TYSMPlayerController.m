//
//  TYSMPlayer.m
//  MLife
//
//  Created by jele lam on 31/1/2020.
//  Copyright © 2020 CookiesJ. All rights reserved.
//

#import "TYSMPlayerController.h"
@interface TYSMPlayerController () <AVPlayerItemOutputPullDelegate>
@property (nonatomic, strong) id<TYSMPlayerDelegate> delegate;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerItemVideoOutput *playerOutput;
@property (nonatomic, strong) dispatch_queue_t player_queue;
@property (nonatomic, assign) TYSMPlayerFPS fps;
@property (nonatomic, strong) AVAssetImageGenerator *generator;
@end

@implementation TYSMPlayerController
- (instancetype)initWithDelegate:(id<TYSMPlayerDelegate>)delegate {
    if (self = [super init]) {
        self.delegate = delegate;
        self.player_queue = dispatch_queue_create("TYSM_player_queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)configureFilePath:(NSString *)filePath FPS:(TYSMPlayerFPS)fps{
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:filePath]];
    [self configureAsset:asset FPS:fps];
}

- (void)configureAsset:(AVAsset *)asset FPS:(TYSMPlayerFPS)fps {
    self.fps = fps;
    [self configurePlayerItemWithAsset:asset];
}

- (void)configurePlayerItemWithAsset:(AVAsset *)asset {
    if (self.playerItem) {
        [self.playerItem removeOutput:self.playerOutput];
        [self.playerItem removeObserver:self forKeyPath:@"status"];
        [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    [self.playerItem addOutput:self.playerOutput];

    [self.playerItem addObserver:self
                      forKeyPath:@"status"
                         options:NSKeyValueObservingOptionNew
                         context:nil];// 监听status属性
    
    [self.playerItem addObserver:self
                      forKeyPath:@"loadedTimeRanges"
                         options:NSKeyValueObservingOptionNew
                         context:nil];// 监听loadedTimeRanges属性
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayDidEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
    

    self.player = [AVPlayer playerWithPlayerItem:_playerItem];
    
    // 创建AVAssetImageGenerator对象
    self.generator = [[AVAssetImageGenerator alloc] initWithAsset:self.playerItem.asset];
    self.generator.maximumSize = CGSizeMake(kTimeScale, 0);
    self.generator.appliesPreferredTrackTransform = YES;
    self.generator.requestedTimeToleranceBefore = kCMTimeZero;
    self.generator.requestedTimeToleranceAfter = kCMTimeZero;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        
        switch ([playerItem status]) {
                
            case AVPlayerItemStatusUnknown:
                NSLog(@"AVPlayerStatusUnknown");
                break;
            case AVPlayerItemStatusReadyToPlay:
            {
                NSLog(@"AVPlayerStatusReadyToPlay");

                [self monitoringPlayback:self.playerItem];// 监听播放状态
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(playerComponentMediaInfo:)]) {
                    [self.delegate playerComponentMediaInfo:[self getMediaInfo]];
                }
            }
                break;
            case AVPlayerItemStatusFailed:
            {
                NSLog(@"AVPlayerStatusFailed");
            }
                break;
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {

    }
}

- (void)moviePlayDidEnd:(NSNotification *)noti {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playToEndTime)]) {
        [self.delegate playToEndTime];
    }
}

/**
 利用 AVPlayerItemVideoOutput 获取一帧 CVPixelBuffer 数据
 出于内存管理考虑，本方法内部手动释放每一帧 CVPixelBuffer。
 外部在使用一帧 CVPixelBuffer 时可以适当调用 CVPixelBufferRetain() 避免崩溃
 @param time 指定时间
 */
- (void)getVideoInputCVPixelBufferWithCMTime:(CMTime)time {
    if (self.delegate && [self.delegate respondsToSelector:@selector(outputCVPixelBuffer:currentTime:)]) {
        if ([self.playerOutput hasNewPixelBufferForItemTime:time]) {
            CVPixelBufferRef pixelBuff = [self.playerOutput copyPixelBufferForItemTime:time itemTimeForDisplay:&time];
            [self.delegate outputCVPixelBuffer:pixelBuff currentTime:time];
            CVPixelBufferRelease(pixelBuff);
            
        }
    }
}

- (void)monitoringPlayback:(AVPlayerItem *)playerItem {
    
    __weak typeof(self)WEAKSELF = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, self.fps) queue:self.player_queue usingBlock:^(CMTime time) {
        
        if (WEAKSELF.isPlaying) {
            [WEAKSELF getVideoInputCVPixelBufferWithCMTime:time];
        }
        
        if (WEAKSELF.delegate && [WEAKSELF.delegate respondsToSelector:@selector(playerComponentPeriodicTime:)]) {
            [WEAKSELF.delegate playerComponentPeriodicTime:CMTimeGetSeconds(time)];
        }
    }];
}

- (NSDictionary *)getMediaInfo {
    return @{
        @"duration" : @(CMTimeGetSeconds(self.playerItem.duration)),
        @"resolution" : NSStringFromCGSize(self.playerItem.presentationSize),
        @"commonMetadata":self.playerItem.asset.commonMetadata,
        @"tracks": self.playerItem.tracks,
    };
}

#pragma mark - source
- (AVAsset *)getPlayerAsset {
    return self.playerItem.asset;
}

#pragma mark - player control

- (BOOL)isPause {
    return self.player.timeControlStatus == AVPlayerTimeControlStatusPaused;
}

- (BOOL)isPlaying {
    return self.player.timeControlStatus == AVPlayerTimeControlStatusPlaying;
}

- (void)play {
    if ([self isPause]) {
        [self.player play];
    }
}

- (void)pause {
    if ([self isPause] == NO) {
        [self.player pause];
    }
}

- (void)seekToTime:(CMTime)time {
    __weak typeof(self)weakself = self;
    [self.playerItem seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        if (finished) {
//            [weakself getVideoInputCVPixelBufferWithCMTime:time];
        }
    }];
}

#pragma mark - Edit
- (void)cancelAllCGImageGeneration {
    [self.generator cancelAllCGImageGeneration];
}

- (void)getVideoFrameWithInterval:(NSInteger)interval processing:(void (^)(UIImage * _Nonnull, NSInteger,NSInteger))block {

    if (interval == 0) {
        interval = 1;
    }

    // 添加需要帧数的时间集合
    NSMutableArray <NSValue *> *framesArray = [NSMutableArray array];
    for (int i = 0; i < CMTimeGetSeconds(self.playerItem.duration) / interval; i++) {
        CMTime time = CMTimeMakeWithSeconds(i*interval, kTimeScale);
        NSValue *value = [NSValue valueWithCMTime:time];
        [framesArray addObject:value];
    }
    
    __block long step = 0;
    NSInteger count = framesArray.count;
    [self.generator generateCGImagesAsynchronouslyForTimes:framesArray completionHandler:^(CMTime requestedTime, CGImageRef img, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        
        if (result == AVAssetImageGeneratorSucceeded) {
            
            UIImage *image = [UIImage imageWithCGImage:img];
            dispatch_async(dispatch_get_main_queue(), ^{
                block(image,step,count);
                step++;
            });
        }
        
        if (result == AVAssetImageGeneratorFailed) {
            NSLog(@"Failed with error: %@", [error localizedDescription]);
        }
        
        if (result == AVAssetImageGeneratorCancelled) {
            NSLog(@"AVAssetImageGeneratorCancelled");
        }
        
    }];

}

#pragma mark - delegate
- (void)outputSequenceWasFlushed:(AVPlayerItemOutput *)output {
    NSLog(@"%@ => %@",[NSThread currentThread],@(output.suppressesPlayerRendering));
    [self getVideoInputCVPixelBufferWithCMTime:self.player.currentTime];
    
}

- (void)outputMediaDataWillChange:(AVPlayerItemOutput *)sender {
    NSLog(@"%@ => %@",[NSThread currentThread],@(sender.suppressesPlayerRendering));
}

#pragma mark - loadlazy
- (AVPlayerItemVideoOutput *)playerOutput {
    if (_playerOutput == nil) {
        NSDictionary *settings = @{(id)kCVPixelBufferPixelFormatTypeKey:
                                       [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                   };
        _playerOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:settings];
        dispatch_queue_t queue = dispatch_queue_create("output_queue", DISPATCH_QUEUE_SERIAL);
        [_playerOutput setDelegate:self queue:queue];
    }
    return _playerOutput;
}
@end
