//
//  TYSMPlayer.h
//  MLife
//
//  Created by jele lam on 31/1/2020.
//  Copyright © 2020 CookiesJ. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

typedef NS_CLOSED_ENUM(int32_t, TYSMPlayerFPS) {
    TYSMPlayerFPS30 = 30,
    TYSMPlayerFPS24 = 24,
    TYSMPlayerFPS60 = 60,
    TYSMPlayerFPS120 = 120,
    TYSMPlayerFPS240 = 240
};

@protocol TYSMPlayerDelegate <NSObject>
/**
 输出一帧 CVPixelBuffer
 */
- (void)outputCVPixelBuffer:(CVPixelBufferRef _Nonnull )pixelBuffer currentTime:(CMTime)currentTime;

@optional

/** 实时回调当前播放的时间  */
- (void)playerComponentPeriodicTime:(CGFloat)time;

/** 返回视频参数信息 */
- (void)playerComponentMediaInfo:(NSDictionary *_Nonnull)info;

/** 播放到结束时间回调 */
- (void)playToEndTime;

@end

NS_ASSUME_NONNULL_BEGIN

@interface TYSMPlayerController : NSObject

- (instancetype)initWithDelegate:(id<TYSMPlayerDelegate>)delegate;

/** 播放路径
 @param filePath 文件路径
 @param fps 播放帧率。严格意义上说只是按 CMTime 的要求每秒包含多少个图片。
 */
- (void)configureFilePath:(NSString *)filePath FPS:(TYSMPlayerFPS)fps;

/** 播放资源
@param asset 资源
@param fps 播放帧率。严格意义上说只是按 CMTime 的要求每秒包含多少个图片。
*/

- (void)configureAsset:(AVAsset *)asset FPS:(TYSMPlayerFPS)fps;



- (void)play;
- (void)pause;
- (BOOL)isPause;
- (BOOL)isPlaying;

/**
 跳转到指定时间
 @param time 时间
 */
- (void)seekToTime:(CMTime)time;

/** 获得视频帧图像
 @param interval 指定秒数间隔获取一张图片 默认 1 秒
 @param block 异步实时回调一张图片
 */
- (void)getVideoFrameWithInterval:(NSInteger)interval processing:(void(^)(UIImage *image,NSInteger idx,NSInteger count))block;

/**
 中止获取视频帧图像任务
 */
- (void)cancelAllCGImageGeneration;
@end

NS_ASSUME_NONNULL_END
