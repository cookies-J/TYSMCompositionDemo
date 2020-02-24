//
//  TYSMDecoder.m
//  MLife
//
//  Created by jele lam on 1/2/2020.
//  Copyright © 2020 CookiesJ. All rights reserved.
//

#import "TYSMDecoder.h"
#import <UIKit/UIGeometry.h>

@interface TYSMDecoder ()
@property (nonatomic, strong) AVAssetReader *assetReader;
@end

@implementation TYSMDecoder {
    AVAssetReaderTrackOutput *_readerOutputV;
    AVAssetReaderTrackOutput *_readerOutputA;
    CGSize _dimensions;
}

- (instancetype)initWithAsset:(AVAsset *)asset {
    if (self = [super init]) {
        
        NSError *error = nil;
        self.assetReader = [AVAssetReader assetReaderWithAsset:asset error:&error];
        
        if (error) {
            NSAssert1(error == nil, @"%@", error);
            return nil;
        }
        
        if (self.assetReader == nil) {
            NSAssert(self.assetReader, @"解码器初始化失败");
            return nil;
        }
        
    }
    return self;
}

- (void)configureReaderOutputV {
    AVAssetTrack *videoTrack = [[self.assetReader.asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    
    NSDictionary *videoSetting = @{
        (id)kCVPixelBufferPixelFormatTypeKey     : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
        (id)kCVPixelBufferIOSurfacePropertiesKey : [NSDictionary dictionary],
        (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange),
    };
    
    _readerOutputV = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:videoSetting];
    
    if ([self.assetReader canAddOutput:self.readerOutputV]) {
        [self.assetReader addOutput:self.readerOutputV];
    } else {
        assert("添加 readerOutputV 失败");
    }
}

- (void)configureReaderOutputA {
    AVAssetTrack *audioTrack = [[self.assetReader.asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    
    NSDictionary *audioSetting = @{AVFormatIDKey : [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM]};
    
    _readerOutputA = [[AVAssetReaderTrackOutput alloc] initWithTrack:audioTrack outputSettings:audioSetting];
    
    if ([self.assetReader canAddOutput:self.readerOutputA]) {
        [self.assetReader addOutput:self.readerOutputA];
    } else {
        assert("添加 readerOutputA 失败");
    }
}

- (void)startReader {
    
    [self configureReaderOutputV];
    [self configureReaderOutputA];
    
    if ([self.assetReader startReading] == NO) { NSLog(@"%@,%@",self.assetReader.error.localizedDescription,self.assetReader.error.localizedRecoverySuggestion);
    }
}

- (void)finishAllReading {
    [self.assetReader cancelReading];
}
@end
