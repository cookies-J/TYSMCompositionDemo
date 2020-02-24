//
//  TYSMTranscoder.h
//  MLife
//
//  Created by jele lam on 1/2/2020.
//  Copyright © 2020 CookiesJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TYSMTranscoder : NSObject
/** 初始化转码类
 @param asset 源视频资源
 @param url 转码保存路径
 */
- (instancetype)initWithAsset:(AVAsset *)asset toFileURL:(NSURL *)url;

/**
 开始转码
 @param completion 完成回调
 @param videoProgress 回调 视频 转码进度
 @param audioProgress 回调 音频 转码进度
 */
- (void)startTranscode:(void(^)(NSString *outputFilePath))completion
         videoProgress:(void(^)(double progress))videoProgress
         audioProgress:(void(^)(double progress))audioProgress;

/**
 将转码完成的视频文件保存到相册
 @param filePath 视频文件路径
 */
- (void)saveToAlbumWithFilePath:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
