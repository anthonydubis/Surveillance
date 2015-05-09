//
//  ADFaceDetector.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/8/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADFaceDetector.h"
#import <CoreImage/CoreImage.h>

@interface ADFaceDetector ()

@property (nonatomic, strong) CIContext *context;
@property (nonatomic, strong) CIDetector *detector;

@end

@implementation ADFaceDetector

- (NSArray *)detectFacesInPixelBufferRef:(CVPixelBufferRef)pixelBuffer
{
    CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    // NSDictionary *opts = @{ CIDetectorImageOrientation : [[image properties] valueForKey:kCGImagePropertyOrientation] };
    NSArray *features = [self.detector featuresInImage:image];
    return features;
}

- (CIContext *)context
{
    if (!_context) {
        _context = [CIContext contextWithOptions:nil];
    }
    return _context;
}

- (CIDetector *)detector
{
    if (!_detector) {
        NSDictionary *opts = @{ CIDetectorAccuracy : CIDetectorAccuracyLow };
        _detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                       context:self.context
                                       options:opts];
    }
    return _detector;
}

@end
