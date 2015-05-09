//
//  ADFaceDetector.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/8/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADFaceDetector : NSObject

- (NSArray *)detectFacesInPixelBufferRef:(CVPixelBufferRef)pixelBuffer;

@end
