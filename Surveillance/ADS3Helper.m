    //
//  ADS3Helper.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/16/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADS3Helper.h"
#import <AWSS3/AWSS3.h>
#import "ADEvent.h"
#import "ADFileHelper.h"

#warning Test what happens when the ID is wrong just so you know we have some level of security
NSString *CognitoPoolID = @"us-east-1:5bb89c68-9ee9-48b0-aceb-a18d4297aa29";
NSString *BucketName = @"surveillance-bucket";

@implementation ADS3Helper

+ (void)setupAWSS3Service
{
    // [AWSLogger defaultLogger].logLevel = AWSLogLevelVerbose;
    
    AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:AWSRegionUSEast1
                                                                                                    identityPoolId:CognitoPoolID];
    
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1
                                                                         credentialsProvider:credentialsProvider];
    
    AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;
}

+ (void)uploadVideoAtURL:(NSURL *)url forEvent:(ADEvent *)event
{
    // Create the upload request
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.body = url;
    uploadRequest.bucket = BucketName;
    uploadRequest.key = [self keyForEvent:event];
    
    // Perform the upload with a transfer manager
    AWSS3TransferManager *manager = [AWSS3TransferManager defaultS3TransferManager];
    
    // Create the completion block
    id (^completionBlock)(BFTask *task) = ^id(BFTask *task) {
        if (task.error) {
            if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
                switch (task.error.code) {
                    case AWSS3TransferManagerErrorCancelled:
                    case AWSS3TransferManagerErrorPaused:
                        break;
                        
                    default:
                        NSLog(@"Error: %@", task.error);
                        break;
                }
            } else {
                // Unknown error.
                NSLog(@"Error: %@", task.error);
            }
        }
        
        if (task.result) {
            // The file uploaded successfully. Update the Parse object
            NSLog(@"File uploaded successfully");
            event.s3BucketName = BucketName;
            [event saveInBackground];
#warning You need to handle failures here
            if ([[NSFileManager defaultManager] removeItemAtURL:url error:nil])
                NSLog(@"Removed file");
            else
                NSLog(@"Couldn't remove file.");
            [ADFileHelper listAllFilesAtToUploadDirectory];
        }
        return nil;
    };
    
    // Start he upload
    [[manager upload:uploadRequest] continueWithExecutor:[BFExecutor mainThreadExecutor]
                                               withBlock:completionBlock];
}

+ (void)downloadVideoForEvent:(ADEvent *)event toURL:(NSURL *)toURL withCompletionBlock:(void(^)(void))completionBlock;
{
    // Construct the download request.
    AWSS3TransferManagerDownloadRequest *downloadRequest = [AWSS3TransferManagerDownloadRequest new];
    downloadRequest.bucket = BucketName;
    downloadRequest.key = [self keyForEvent:event];
    NSLog(@"Requesting key: %@", downloadRequest.key);
    downloadRequest.downloadingFileURL = toURL;
    
    // Construct the completion block
    id (^handler)(BFTask *task) = ^id(BFTask *task) {
        if (task.error){
            if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
                switch (task.error.code) {
                    case AWSS3TransferManagerErrorCancelled:
                    case AWSS3TransferManagerErrorPaused:
                        break;
                    default:
                        NSLog(@"Error: %@", task.error);
                        break;
                }
            } else {
                // Unknown error.
                NSLog(@"Error: %@", task.error);
            }
        }
        
        if (task.result) {
            //File downloaded successfully.
            NSLog(@"File downloaded successfully");
            if (completionBlock != nil) {
                completionBlock();
            }
        }
        return nil;
    };
    
    // Start the process with the transfer manager
    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    [[transferManager download:downloadRequest] continueWithExecutor:[BFExecutor mainThreadExecutor]
                                                           withBlock:handler];
}

+ (void)deleteVideoForEvent:(ADEvent *)event withCompletionBlock:(void(^)(void))completionBlock
{
    AWSS3 *s3 = [AWSS3 defaultS3];
    
    //Delete Object
    AWSS3DeleteObjectRequest *deleteObjectRequest = [AWSS3DeleteObjectRequest new];
    deleteObjectRequest.bucket = BucketName;
    deleteObjectRequest.key = [self keyForEvent:event];
    
    [[s3 deleteObject:deleteObjectRequest] continueWithExecutor:[BFExecutor mainThreadExecutor]
                                                      withBlock:^id(BFTask *task) {
        if(task.error != nil){
            if(task.error.code != AWSS3TransferManagerErrorCancelled && task.error.code != AWSS3TransferManagerErrorPaused){
                NSLog(@"%s Error: [%@]",__PRETTY_FUNCTION__, task.error);
            }
        } else{
            NSLog(@"Finished the deletion");
            if (completionBlock != nil)
                completionBlock();
        }
        return nil;
    }];
}

// Specify the key format as "objectID/videoName" to ensure uniqueness
+ (NSString *)keyForEvent:(ADEvent *)event
{
    return [NSString stringWithFormat:@"%@/%@", event.user.objectId, event.videoName];
}

@end
