//
//  TYSMTranscoder.m
//  MLife
//
//  Created by jele lam on 1/2/2020.
//  Copyright © 2020 CookiesJ. All rights reserved.
//

#import "TYSMTranscoder.h"
#import "TYSMEncoder.h"
#import "TYSMDecoder.h"
#import <UIKit/UIImagePickerController.h>
#import <UIKit/UIImage.h>

@interface TYSMTranscoder ()
@property (nonatomic, strong) TYSMDecoder *decoder; // 硬解码器
@property (nonatomic, strong) TYSMEncoder *encoder; // 软解码器
@property (nonatomic,assign) UIBackgroundTaskIdentifier __block bgRunningTranscoderTaskID;  // 后台继续执行转码任务
@end

@implementation TYSMTranscoder {
    NSString * _outputFilePath;
    CMTime _duration;
}

- (instancetype)initWithAsset:(AVAsset *)asset toFileURL:(NSURL *)url {
    if (self = [super init]) {
        
        self.decoder = [[TYSMDecoder alloc] initWithAsset:asset];

        self.encoder = [[TYSMEncoder alloc] initWithFileURL:url];

        _outputFilePath = url.relativePath;
        _duration = asset.duration;
        
        if (self.decoder == nil && self.encoder == nil) {
            return nil;
        }
        
        [self.decoder startReader];

    }
    return self;
}


- (void)startTranscode:(void (^)(NSString *outputFilePath))completion videoProgress:(nonnull void (^)(double))videoProgress audioProgress:(nonnull void (^)(double))audioProgress {
    
    UIApplication *app = [UIApplication sharedApplication];

    _bgRunningTranscoderTaskID = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:self->_bgRunningTranscoderTaskID];
        self->_bgRunningTranscoderTaskID = UIBackgroundTaskInvalid;
    }];
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t transcode_video_queue = dispatch_queue_create("transcode_video_queue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t transcode_audio_queue = dispatch_queue_create("transcode_audio_queue", DISPATCH_QUEUE_SERIAL);
    
    dispatch_group_enter(group);
    
    [self.encoder.writerInputV requestMediaDataWhenReadyOnQueue:transcode_video_queue usingBlock:^{
        while ([self.encoder.writerInputV isReadyForMoreMediaData]) {
            CMSampleBufferRef buffer = [self.decoder.readerOutputV copyNextSampleBuffer];
            if (buffer) {
                @autoreleasepool {
//                    [self transformWithSampleBuffer:buffer];
                    [self.encoder appendSampleBuffer:buffer fromInputType:AssetWriterInputTypeVideo];
                    // 计算进度
                    CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(buffer);
                    if (videoProgress) {
                        videoProgress(CMTimeGetSeconds(currentTime) / CMTimeGetSeconds(self->_duration) * 100);
                    }
                }
                CFRelease(buffer);
                
            }
            else {
                [self.encoder finishWritingVideo];
                if (videoProgress) {
                    videoProgress(100.0);
                }
                dispatch_group_leave(group);
            }
        }
    }];
    
    dispatch_group_enter(group);
    [self.encoder.writerInputA requestMediaDataWhenReadyOnQueue:transcode_audio_queue usingBlock:^{
        while ([self.encoder.writerInputA isReadyForMoreMediaData]) {
            CMSampleBufferRef buffer = [self.decoder.readerOutputA copyNextSampleBuffer];
            if (buffer) {
                [self.encoder appendSampleBuffer:buffer fromInputType:AssetWriterInputTypeAudio];
                CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(buffer);
                if (audioProgress) {
                    audioProgress(CMTimeGetSeconds(currentTime) / CMTimeGetSeconds(self->_duration) * 100);
                }
                CFRelease(buffer);
            }
            else {
                [self.encoder finishWritingAudio];
                if (audioProgress) {
                    audioProgress(100.0);
                }
                dispatch_group_leave(group);
            }
        }
    }];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self.decoder finishAllReading];
        [self.encoder finishAllWritingWithCompletionHandler:^(BOOL isCompleted) {
            NSAssert(isCompleted,@"写入任务失败");
            completion(self->_outputFilePath);
            [[UIApplication sharedApplication] endBackgroundTask:self->_bgRunningTranscoderTaskID];
        }];
    });
}

#pragma mark - save to album
- (void)saveToAlbumWithFilePath:(NSString *)filePath {
    // 延迟 0.1 秒执行。解决保存失败提示 文件损坏 的问题
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
            UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        }
    });
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo {
    
    if (error == nil) {
        NSLog(@"保存成功");
    }else{
        NSLog(@"Finished saving video with error: %@", error);
        
    }
}
#pragma mark - private

// 旋转 SampleBuffer
- (void)transformWithSampleBuffer:(CMSampleBufferRef)buffer {
    
    CIImage *ciimage = [CIImage imageWithCVImageBuffer:CMSampleBufferGetImageBuffer(buffer)];
// 当前的视频是自动向右转 90 度。所以这里做一个左转操作，考虑场景简单，暂时这么处理
    CIImage *wImage = [ciimage imageByApplyingCGOrientation:kCGImagePropertyOrientationLeft];

    CVPixelBufferRef newPixcelBuffer = nil;
    
    CVPixelBufferLockBaseAddress(newPixcelBuffer, 0);
    
    CVPixelBufferCreate(kCFAllocatorDefault,
                        CGRectGetHeight(ciimage.extent) , CGRectGetWidth(ciimage.extent) ,
                        kCVPixelFormatType_32BGRA,
                        nil,
                        &newPixcelBuffer);
    
    [[CIContext context] render:wImage toCVPixelBuffer:newPixcelBuffer];

    CVPixelBufferUnlockBaseAddress(newPixcelBuffer, 0);
    
    [self.encoder appendCVPixelBuffer:newPixcelBuffer presentationTime:CMSampleBufferGetPresentationTimeStamp(buffer)];
    // release
    CVPixelBufferRelease(newPixcelBuffer);
}
@end
