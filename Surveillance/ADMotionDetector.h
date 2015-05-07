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
    MotionDetectorSensitivityLow = 0,
    MotionDetectorSensitivityMedium,
    MotionDetectorSensitivityHigh
};

@interface ADMotionDetector : NSObject

@property (nonatomic, assign) MotionDetectorSensitivity sensitivity;

- (BOOL)isBackgroundSet;
- (void)setBackgroundWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (BOOL)didMotionOccurInPixelBufferRef:(CVPixelBufferRef)pixelBuffer;

@end
