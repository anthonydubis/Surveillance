//
//  ADMotionDetector.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/7/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MotionDetectorSensitivity )
{
    MotionDetectorSensitivityLow = 1,
    MotionDetectorSensitivityMedium,
    MotionDetectorSensitivityHigh
};

@interface ADMotionDetector : NSObject

@property (nonatomic, assign) MotionDetectorSensitivity sensitivity;

// Return a string name of the sensitivity
+ (NSString *)nameForSensitivity:(MotionDetectorSensitivity)sensitivity;

// Return a string description of the sensitivity
+ (NSString *)descriptionForSensitivity:(MotionDetectorSensitivity)sensitivity;

- (BOOL)isBackgroundSet;
- (BOOL)shouldSetBackground;
- (void)setBackgroundWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (BOOL)didMotionOccurInPixelBufferRef:(CVPixelBufferRef)pixelBuffer;
- (NSTimeInterval)intervalSinceLastMotionCheck;
- (BOOL)hasMotionEnded;

@end
