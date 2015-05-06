//
//  ObservationViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/1/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ObservationViewController.h"
#import <opencv2/highgui/cap_ios.h>
#import <opencv2/highgui/ios.h>

@interface ObservationViewController () <CvVideoCameraDelegate>
{
    BOOL isMonitoring;
    BOOL isRecording;
}

@property (nonatomic, strong) CvVideoCamera *videoCamera;
@property (nonatomic, assign) cv::Mat background;

@end

@implementation ObservationViewController

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (!self.videoCamera) {
        self.videoCamera = [[CvVideoCamera alloc] initWithParentView:self.imageView];
        self.videoCamera.delegate = self;
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
        self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
        self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
        self.videoCamera.defaultFPS = 30;
        self.videoCamera.grayscaleMode = NO;
        // self.videoCamera.recordVideo = NO;
        // [self.videoCamera start];
        [self performSelector:@selector(beginMonitoring) withObject:nil afterDelay:3.0];
    }
}

- (void)beginMonitoring
{
    [self.videoCamera lockFocus];
    isMonitoring = YES;
    AudioServicesPlaySystemSound(1005);
}

#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
- (void)processImage:(cv::Mat&)image;
{
    if (isMonitoring) {
        cv::Mat gray;
        cv::cvtColor(image, gray, CV_RGB2GRAY);
        // cv::Mat img_blur;
        // cv::blur(image, img_blur, cv::Size(4,4));
        
        if (self.background.empty()) {
            self.background = gray.clone();
        } else {
            cv::Mat diff;
            cv::absdiff(gray, self.background, diff);
            cv::threshold(diff, diff, 50, 255, cv::THRESH_TOZERO);
            // cv::threshold(diff[0], diff[0], 30, 255, cv::THRESH_TOZERO);
            unsigned long diffVal = sum(diff)[0];
            NSLog(@"%lu with cutoff %i", diffVal, self.motionSensitivity);
            /*
            if (diffVal > self.motionSensitivity) {
                if (!isRecording) {
                    [self.videoCamera stop];
                    self.videoCamera.recordVideo = YES;
                    [self.videoCamera start];
                    isRecording = YES;
                }
             
                dispatch_async(dispatch_get_main_queue(), ^{
                    AudioServicesPlaySystemSound(1005);
                    [UIAlertView showWithTitle:@"Motion Detected"
                                       message:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil
                                      tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                          [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                                      }];
                });
             
            }
              */
        }
    }
}
#endif

@end
