//
//  ADFaceDetector.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/8/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

static const NSString *ADFaceDetectorNumberOfFacesDetected = @"ADFaceDetectorNumberOfFacesDetected";
static const NSString *ADFaceDetectorImageWithFaces = @"ADFaceDetectorImageWithFaces";

@interface ADFaceDetector : NSObject

/*
 * Return dictionary of results after detecting image. The dictionary is empty if no faces detect.
 * If faces are detected, two key : values are present
 * ADFaceDetectorNumberOfFacesDetected : # of faces detected
 * ADFaceDetectorImageWithFaces : a UIImage for the pixelBuffer
 */
- (NSDictionary *)detectFacesFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
                               andPixelBuffer:(CVPixelBufferRef)pixelBuffer
                       usingFrontFacingCamera:(BOOL)isUsingFrontFacingCamera;


@end
