//
//  ADVideoRecorder.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/8/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface ADVideoRecorder : NSObject

@property (nonatomic, assign) UIDeviceOrientation orientation;
@property (nonatomic, assign) BOOL isUsingFrontCamera;

/**
 * Create the recorder with an initial URL to record to
 */
- (instancetype)initWithRecordingURL:(NSURL *)url;

/**
 * Tell the assetWrtier frames are going to be coming in. Free to append
 * frames after this call.
 */
- (void)startRecordingWithSourceTime:(CMTime)sourceTime;

/**
 * Finish writing the file
 */
- (void)stopRecordingWithCompletionHandler:(void (^) (void))handler;

/**
 * Should be called when a new URL is going to be recorded to.
 */
- (void)prepareToRecordWithNewURL:(NSURL *)url;

/**
 * The method called to append frames to the video
 */
- (void)appendFrameFromPixelBuffer:(CVPixelBufferRef)pixelBuffer withPresentationTime:(CMTime)presentationTime;

/**
 * Append audio frame
 */
- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end
