//
//  ADMotionDetector.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/7/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADMotionDetector.h"
#import <opencv2/highgui/cap_ios.h>

const int Significant_Difference_Threshold = 50;
const int High_Motion_Sensitivity   = 1000;
const int Medium_Motion_Sensitivity = 10000;
const int Low_Motion_Sensitivity    = 50000;

@interface ADMotionDetector()

@property (nonatomic, assign) cv::Mat background;

@end

@implementation ADMotionDetector

- (BOOL)isBackgroundSet
{
    return !self.background.empty();
}

/*
 * Sets the background that will be compared to for detecting motion
 */
- (void)setBackgroundWithPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    cv::Mat gray = [self grayMatFromPixelBuffer:pixelBuffer];
    self.background = gray.clone();
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

/*
 * Detect motion in this new pixelBufferRef. Motion is determined by taking the absolute difference of
 * this new frame from the background, thresholding the values to eliminate small differences, 
 * then summing all of the pixel values to determine the overall change.
 */
- (BOOL)didMotionOccurInPixelBufferRef:(CVPixelBufferRef)pixelBuffer
{
    if (self.background.empty()) return NO;
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    cv::Mat gray = [self grayMatFromPixelBuffer:pixelBuffer];
    cv::Mat diff;
    cv::absdiff(gray, self.background, diff);
    cv::threshold(diff, diff, Significant_Difference_Threshold, 255, cv::THRESH_TOZERO);
    unsigned long diffVal = sum(diff)[0];
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    NSLog(@"%lu", diffVal);
    return (diffVal > [self motionSensitivityThreshold]);
}

/*
 * Get the grayscale Mat from the pixelBufferRef
 */
- (cv::Mat)grayMatFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    cv::Mat image = [self imageMatFromPixelBuffer:pixelBuffer];
    cv::Mat gray;
    cv::cvtColor(image, gray, CV_RGB2GRAY);
    return gray;
}

/*
 * Get the image mat from the pixelBufferRef
 */
- (cv::Mat)imageMatFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    cv::Mat image = cv::Mat(bufferHeight, bufferWidth, CV_8UC4, pixel); //put buffer in open cv, no memory copied
    return image;
}

- (int)motionSensitivityThreshold
{
    switch (self.sensitivity) {
        case MotionDetectorSensitivityHigh:   return High_Motion_Sensitivity;
        case MotionDetectorSensitivityMedium: return Medium_Motion_Sensitivity;
        case MotionDetectorSensitivityLow:    return Low_Motion_Sensitivity;
    }
}

@end
