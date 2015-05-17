//
//  ADS3Helper.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/16/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ADEvent;

@interface ADS3Helper : NSObject

/*
 * Set the credentials to use the S3 Service, as well as the logging setting
 */
+ (void)setupAWSS3Service;

/*
 * Upload the video for an Event
 */
+ (void)uploadVideoAtURL:(NSURL *)url forEvent:(ADEvent *)event;

/*
 * Download the video for an Event
 */
+ (void)downloadVideoForEvent:(ADEvent *)event toURL:(NSURL *)url withCompletionBlock:(void(^)(void))completionBlock;

/*
 * Delete the video for an Event from the S3 Bucket
 */
+ (void)deleteVideoForEvent:(ADEvent *)event withCompletionBlock:(void(^)(void))completionBlock;

@end
