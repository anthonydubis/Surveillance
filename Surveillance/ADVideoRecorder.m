//
//  ADVideoRecorder.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/8/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADVideoRecorder.h"
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>

@interface ADVideoRecorder ()

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;

@property (nonatomic, strong) AVAssetWriterInput *audioWriterInput;

@end

@implementation ADVideoRecorder

- (id)initWithRecordingURL:(NSURL *)url
{
    if (self = [super init]) {
        [self setupAssetWriterComponentsWithRecordingURL:url];
        return self;
    } else {
        return nil;
    }
}

/*
 * Creates the asset writer components to record frames on demand.
 * Must be done together and before the assetWriter begins writing
 */
- (void)setupAssetWriterComponentsWithRecordingURL:(NSURL *)url
{
    NSError *error = nil;
    // Moved this into lazily instantiated getters
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:640], AVVideoWidthKey,
                                    [NSNumber numberWithInt:480], AVVideoHeightKey,
                                    AVVideoCodecH264, AVVideoCodecKey, nil];
    
    self.assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    
#warning This can't be a permanent solution
    // Default video orietnation, at least for front facing camera, is landscapeLeft.
    // Specify that the video should be rotated when played
    self.assetWriterInput.transform = CGAffineTransformMakeRotation(M_PI / 2);
    
    /* We're going to push pixel buffers to it, so will need a
     AVAssetWriterPixelBufferAdaptor, to expect the same 32BGRA input as I've
     asked the AVCaptureVideDataOutput to supply */
    self.pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc]
                               initWithAssetWriterInput:self.assetWriterInput
                               sourcePixelBufferAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                            [NSNumber numberWithInt:kCVPixelFormatType_32BGRA],kCVPixelBufferPixelFormatTypeKey, nil]];
    
    // Create the audioWriterInput
    AudioChannelLayout acl;
    bzero(&acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    
    NSDictionary*  audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                          [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,
                                          [NSNumber numberWithFloat: 44100.0], AVSampleRateKey,
                                          [NSData dataWithBytes: &acl length: sizeof( AudioChannelLayout ) ], AVChannelLayoutKey,
                                          [NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
                                          nil];
    
    _audioWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
    
    self.assetWriter = [[AVAssetWriter alloc] initWithURL:url
                                                 fileType:AVFileTypeMPEG4
                                                    error:&error];
    [self.assetWriter addInput:self.assetWriterInput];
    [self.assetWriter addInput:self.audioWriterInput];
    
    /* we need to warn the input to expect real time data incoming, so that it tries
     to avoid being unavailable at inopportune moments */
    self.assetWriterInput.expectsMediaDataInRealTime = YES;
    _audioWriterInput.expectsMediaDataInRealTime = YES;
}

- (void)startRecordingWithSourceTime:(CMTime)sourceTime
{
    [self.assetWriter startWriting];
    [self.assetWriter startSessionAtSourceTime:sourceTime];
    self.dateTimeRecordingBegan = [NSDate date];
}

- (void)stopRecordingWithCompletionHandler:(void (^)(void))handler
{
    [self.assetWriterInput markAsFinished];
    [self.assetWriter finishWritingWithCompletionHandler:^{
        handler();
    }];
}

- (void)prepareToRecordWithNewURL:(NSURL *)url
{
    [self setupAssetWriterComponentsWithRecordingURL:url];
}

- (void)appendFrameFromPixelBuffer:(CVPixelBufferRef)pixelBuffer withPresentationTime:(CMTime)presentationTime
{
    if (self.assetWriterInput.isReadyForMoreMediaData) {
        [self.pixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:presentationTime];
    }
}

- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (_audioWriterInput.isReadyForMoreMediaData) {
        [_audioWriterInput appendSampleBuffer:sampleBuffer];
    }
}

@end
