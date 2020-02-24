//
//  TYSMEncoder.m
//  MLife
//
//  Created by jele lam on 1/2/2020.
//  Copyright © 2020 CookiesJ. All rights reserved.
//

#import "TYSMEncoder.h"

@interface TYSMEncoder ()
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdapter;
@end

@implementation TYSMEncoder {
    AVAssetWriterInput *_writerInputV;
    AVAssetWriterInput *_writerInputA;
}

/**
 初始化编码器
 
 @param URL 本地文件保存地址
 */
- (instancetype)initWithFileURL:(NSURL *)URL {
    if (self = [super init]) {
        
        NSError *error = nil;
        self.assetWriter = [AVAssetWriter assetWriterWithURL:URL fileType:AVFileTypeMPEG4 error:&error];
        
        if (error) {
            NSAssert1(error == nil, @"%@", error);
            return nil;
        }
        
        if (self.assetWriter == nil) {
            NSAssert(self.assetWriter, @"编码器初始化失败");
            return nil;
        }
        
        _writerInputV = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                           outputSettings:[self configureVideoSetting]
                         ];
        
        _writerInputV.expectsMediaDataInRealTime = YES;

        if ([self.assetWriter canAddInput:self.writerInputV]) {
            [self.assetWriter addInput:self.writerInputV];
        } else {
            NSLog(@"不能添加 AVAssetWriterInputVideo");
            return nil;
        }
        
        _writerInputA = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                           outputSettings:[self configureAudioSetting]
                         ];
        
        _writerInputA.expectsMediaDataInRealTime = YES;
        
        if ([self.assetWriter canAddInput:self.writerInputA]) {
            [self.assetWriter addInput:self.writerInputA];
        } else {
            NSLog(@"不能添加 AVAssetWriterInputAudio");
            return nil;
        }
        
        self.pixelBufferAdapter = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.writerInputV sourcePixelBufferAttributes:@{(NSString*)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
        }];
        
        
        if ([self.assetWriter startWriting] == NO) {
            NSAssert2([self.assetWriter startWriting] == YES,
                      @"%@,%@",
                      self.assetWriter.error.localizedDescription,
                      self.assetWriter.error.localizedRecoverySuggestion);
            return nil;
        }
        
        [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
    }
    return self;
}

#pragma mark - configure
/**
 配置 Video input
 目前所有参数都写固定
 */
- (NSDictionary *)configureVideoSetting {
    NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(1280*720*2),
                                             AVVideoExpectedSourceFrameRateKey: @(30),
                                             AVVideoProfileLevelKey : AVVideoProfileLevelH264HighAutoLevel,
                                             //                                             AVVideoCleanApertureKey : videoCleanApertureSettings,
    };
    
    AVVideoCodecType videoCodecKey;
    if (@available(iOS 11.0, *)) {
        videoCodecKey = AVVideoCodecTypeH264;
    } else {
        videoCodecKey = AVVideoCodecH264;
    }
    NSDictionary *compressionVideoSetting = @{
        AVVideoCodecKey                   : videoCodecKey,
        AVVideoWidthKey                   : @720,
        AVVideoHeightKey                  : @1280,
        AVVideoCompressionPropertiesKey   : compressionProperties
    };
    
    return compressionVideoSetting;
}

/**
配置 Audio input
目前所有参数都写固定
*/
- (NSDictionary *)configureAudioSetting {
    AudioChannelLayout stereoChannelLayout = {
        .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
        .mChannelBitmap = 0,
        .mNumberChannelDescriptions = 0
    };
    NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
    //写入音频配置
    NSDictionary *compressionAudioSetting = @{
        AVFormatIDKey         : [NSNumber numberWithUnsignedInt:kAudioFormatMPEG4AAC],
        AVEncoderBitRateKey   : [NSNumber numberWithInteger:128000],
        AVSampleRateKey       : [NSNumber numberWithInteger:44100],
        AVChannelLayoutKey    : channelLayoutAsData,
        AVNumberOfChannelsKey : [NSNumber numberWithUnsignedInteger:2]
    };
    return compressionAudioSetting;
}

#pragma mark - action

/** 写入一帧 video 数据
 @param pixelBuffer 图像数据
 @param time 时间
 */
- (void)appendCVPixelBuffer:(CVPixelBufferRef)pixelBuffer presentationTime:(CMTime)time {
    
    NSUInteger retryTime = 0;
    while (![self.writerInputV isReadyForMoreMediaData]) {
        usleep(1 * 1000);
        retryTime ++;
        if (retryTime > 30) {
            NSLog(@"丢帧了：%@ \n时间:%.f",self.assetWriter.error, CMTimeGetSeconds(time));
            return;
        }
    }

    if ([self.pixelBufferAdapter appendPixelBuffer:pixelBuffer withPresentationTime:time] == NO) {
        NSLog(@"写入失败 %.1f",CMTimeGetSeconds(time));
    } else {
//        NSLog(@"写入成功 时间： %.1f",CMTimeGetSeconds(time));
    }
    
}

/** 常规方式分数据类型写入数据
 @param type video、audio
 */
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer fromInputType:(AssetWriterInputType)type {
    
    switch (type) {
        case AssetWriterInputTypeVideo:
            if ([self.writerInputV appendSampleBuffer:sampleBuffer] == NO) {
                NSLog(@"%lu 写入失败",type);
            }
            break;
        case AssetWriterInputTypeAudio:
            if ([self.writerInputA appendSampleBuffer:sampleBuffer] == NO) {
                NSLog(@"%lu 写入失败",type);
            }
            break;
    }
}

- (void)finishWritingVideo {
    [self.writerInputV markAsFinished];
}

- (void)finishWritingAudio {
    [self.writerInputA markAsFinished];
}

- (void)finishAllWritingWithCompletionHandler:(void(^)(BOOL isCompleted))completionHandler {
    [self.assetWriter finishWritingWithCompletionHandler:^{
        switch (self.assetWriter.status) {
                
            case AVAssetWriterStatusUnknown:
                break;
            case AVAssetWriterStatusWriting:
                break;
            case AVAssetWriterStatusCompleted:
                [self.assetWriter cancelWriting];
                completionHandler(YES);
                break;
            case AVAssetWriterStatusFailed:
                NSLog(@"%@,%@",self.assetWriter.error.localizedDescription,self.assetWriter.error.localizedRecoverySuggestion);
                [self.assetWriter cancelWriting];
                completionHandler(NO);
                break;
            case AVAssetWriterStatusCancelled:
                NSLog(@"%@,%@",self.assetWriter.error.localizedDescription,self.assetWriter.error.localizedRecoverySuggestion);
                [self.assetWriter cancelWriting];
                completionHandler(NO);
                break;
        }
    }];
}
@end
