//
//  CameraStreamViewController.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/8/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, ADVideoQuality)
{
    ADVideoQualityLow = 1,
    ADVideoQualityStandard
};

#define VIDEO_FRAME_RATE 30

@interface ADCameraStreamViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (nonatomic, assign) BOOL isUsingFrontFacingCamera;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;
@property (nonatomic) dispatch_queue_t videoDataOutputQueue;

@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic, strong) AVCaptureConnection *audioConnection;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

// The specified videoQuality and frameRate
@property (nonatomic, assign) ADVideoQuality videoQuality;

// Returns a string representing the name of the video quality passed in
+ (NSString *)nameForVideoQuality:(ADVideoQuality)videoQuality;

// Returns a string to describe the video quality passed in
+ (NSString *)descriptionForVideoQuality:(ADVideoQuality)videoQuality;

@end
