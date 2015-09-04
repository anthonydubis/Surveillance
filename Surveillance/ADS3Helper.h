//
//  ADS3Helper.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/16/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSCore/AWSNetworking.h>

@class ADEvent;
@class AWSS3TransferManagerDownloadRequest;

@interface ADS3Helper : NSObject

/**
 Cancel all existing 
 */
+ (void)cancelAllRequests;

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
+ (AWSS3TransferManagerDownloadRequest *)downloadVideoForEvent:(ADEvent *)event
                                               completionBlock:(id(^)(BFTask *task))completionBlock
                                                 progressBlock:(AWSNetworkingDownloadProgressBlock)progressBlock;

/*
 * Get the download request for an event and download URL
 * Used when it makes more sense for the download blocks to be handled elsewhere, such as a view controller
 */
+ (AWSS3TransferManagerDownloadRequest *)downloadRequestForEvent:(ADEvent *)event andDownloadURL:(NSURL *)url;

/*
 * Delete the video for an Event from the S3 Bucket
 */
+ (void)deleteVideoForEvent:(ADEvent *)event withSuccessBlock:(void(^)(void))successBlock;

/*
 * Get the size of the video file without having to download it
 */
+ (int)getSizeOfVideoForEvent:(ADEvent *)event;

@end
