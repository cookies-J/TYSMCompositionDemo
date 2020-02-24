//
//  TYSMEncoder.h
//  MLife
//
//  Created by jele lam on 1/2/2020.
//  Copyright © 2020 CookiesJ. All rights reserved.
//

#import <AVFoundation/AVAssetWriter.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_CLOSED_ENUM(NSInteger, AssetWriterInputType) {
    AssetWriterInputTypeVideo,
    AssetWriterInputTypeAudio
};

@interface TYSMEncoder : NSObject

// 往一个文件写入新的 视频 媒体样本
@property (nonatomic, strong, readonly) AVAssetWriterInput *writerInputV;
// 往一个文件写入新的 音频 媒体样本
@property (nonatomic, strong, readonly) AVAssetWriterInput *writerInputA;

/** 初始化编码器
 @param URL 本地文件保存地址
 */
- (instancetype)initWithFileURL:(NSURL *)URL;

/** 写入一帧 video 数据
 @param pixelBuffer 图像数据
 @param time 时间
 */
- (void)appendCVPixelBuffer:(CVPixelBufferRef)pixelBuffer presentationTime:(CMTime)time;

/** 常规方式分数据类型写入数据
 @param type video、audio
 */

- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer fromInputType:(AssetWriterInputType)type;

/**
 完成 video 写入任务
 */
- (void)finishWritingVideo;

/**
 完成 Audio 写入任务
 */
- (void)finishWritingAudio;

/**
 完成所有写入任务
 @params completionHandler 返回完成状态 YES or NO
 */
- (void)finishAllWritingWithCompletionHandler:(void(^)(BOOL isCompleted))completionHandler;
@end

NS_ASSUME_NONNULL_END
