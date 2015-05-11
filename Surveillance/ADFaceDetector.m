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

@property (nonatomic, strong) CIDetector *detector;

@end

@implementation ADFaceDetector

- (NSArray *)detectFacesFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
                          andPixelBuffer:(CVPixelBufferRef)pixelBuffer
                  usingFrontFacingCamera:(BOOL)isUsingFrontFacingCamera
{
    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer
                                                      options:(__bridge NSDictionary *)attachments];
    if (attachments) {
        CFRelease(attachments);
    }
    
    // Release resources
    CFRelease(sampleBuffer);
    
    // make sure your device orientation is not locked.
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    
    NSDictionary *imageOptions = nil;
    
    imageOptions = [NSDictionary
                    dictionaryWithObject:[self exifOrientation:curDeviceOrientation usingFrontFacingCamera:isUsingFrontFacingCamera]
                    forKey:CIDetectorImageOrientation];
    
    NSArray *features = [self.detector featuresInImage:ciImage
                                               options:imageOptions];
    
    NSMutableArray *croppedFaces = [[NSMutableArray alloc] init];
    
    for (CIFeature *feature in features) {
        // crop detected face
        CIVector *cropRect = [CIVector vectorWithCGRect:feature.bounds];
        CIFilter *cropFilter = [CIFilter filterWithName:@"CICrop"];
        [cropFilter setValue:ciImage forKey:@"inputImage"];
        [cropFilter setValue:cropRect forKey:@"inputRectangle"];
        CIImage *croppedImage = [cropFilter valueForKey:@"outputImage"];
        croppedImage = [croppedImage imageByApplyingOrientation:[self exifOrientation:[UIDevice currentDevice].orientation
                                                               usingFrontFacingCamera:isUsingFrontFacingCamera].intValue];
        UIImage *stillImage = [UIImage imageWithCIImage:croppedImage];
        [croppedFaces addObject:stillImage];
    }
    
    NSLog(@"About to return cropped faces");
    
    // return features;
    return croppedFaces;
}

- (NSNumber *)exifOrientation:(UIDeviceOrientation)orientation usingFrontFacingCamera:(BOOL)isUsingFrontFacingCamera
{
    int exifOrientation;
    /* kCGImagePropertyOrientation values
     The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
     by the TIFF and EXIF specifications -- see enumeration of integer constants.
     The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
     
     used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
     If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */
    
    enum {
        PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
        PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.
        PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
        PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
        PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
        PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
        PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
        PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
    };
    
    switch (orientation) {
        case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
            break;
        case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
            if (isUsingFrontFacingCamera)
                exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
            else
                exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
            break;
        case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
            if (isUsingFrontFacingCamera)
                exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
            else
                exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
            break;
        case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
        default:
            exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
            break;
    }
    
    return [NSNumber numberWithInt:exifOrientation];
}

- (CIDetector *)detector
{
    if (!_detector) {
        NSDictionary *opts = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh };
        _detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                       context:nil
                                       options:opts];
    }
    return _detector;
}

@end
