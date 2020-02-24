//
//  TYSMDecoder.h
//  MLife
//
//  Created by jele lam on 1/2/2020.
//  Copyright © 2020 CookiesJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TYSMDecoder : NSObject
/**
 初始化类
 @param asset 传入指定的视频 asset
 */
- (instancetype)initWithAsset:(AVAsset *)asset;

/**
 开始从 asset 读取样本数据
 */
- (void)startReader;

/**
完成所有读取任务
*/
- (void)finishAllReading;

// 读取 视频 轨道的媒体样本
@property (nonatomic, strong, readonly) AVAssetReaderTrackOutput *readerOutputV;
// 读取 音频 轨道的媒体样本
@property (nonatomic, strong, readonly) AVAssetReaderTrackOutput *readerOutputA;
@end

NS_ASSUME_NONNULL_END
