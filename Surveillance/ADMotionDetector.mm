//
//  ADMotionDetector.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/7/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADMotionDetector.h"
#import <opencv2/highgui/cap_ios.h>

const int SignificantDifferenceThreshold = 50;
const float HighMotionSensitivityPct     = 0.005;
const float MediumMotionSensitivityPct   = 0.03;
const float LowMotionSensitivityPct      = 0.06;

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
 * then summing over all the values to get the total number of pixels that changed. This number over
 * over the total number of pixels gives us a percentage that we compare to the motoinSensitivityThreshold.
 */
- (BOOL)didMotionOccurInPixelBufferRef:(CVPixelBufferRef)pixelBuffer
{
    if (self.background.empty()) return NO;
    
    // Get the difference matrix for changes in pixel values
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    cv::Mat gray = [self grayMatFromPixelBuffer:pixelBuffer];
    cv::Mat diff;
    cv::absdiff(gray, self.background, diff);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    // Make all differences <= Significant_Difference_Threshold equal to 0, all others 1
    cv::threshold(diff, diff, SignificantDifferenceThreshold, 1, cv::THRESH_BINARY);
    long unsigned diffVal = sum(diff)[0];
    long unsigned numPixels = diff.cols * diff.rows;
    NSLog(@"%lu / %lu = %f against threshold %f", diffVal, numPixels, ((float)diffVal) / numPixels, [self motionSensitivityThreshold]);
    
    return ((((float)diffVal) / numPixels) > [self motionSensitivityThreshold]);
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

/*
 * The percentage of pixels that must have a significant change to say that motion occured.
 */
- (float)motionSensitivityThreshold
{
    switch (self.sensitivity) {
        case MotionDetectorSensitivityHigh:   return HighMotionSensitivityPct;
        case MotionDetectorSensitivityMedium: return MediumMotionSensitivityPct;
        case MotionDetectorSensitivityLow:    return LowMotionSensitivityPct;
    }
}

@end
