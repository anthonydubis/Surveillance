//
//  UIImage+DataHandler.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/11/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//  Attributed to this stackoverflow post: http://stackoverflow.com/questions/4002040/making-deep-copy-of-uiimage

#import "UIImage+DataHandler.h"

@implementation UIImage (DataHandler)

+ (UIImage *)copyUIImage:(UIImage *)image
{
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    UIImage *copiedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return copiedImage;
}

@end
