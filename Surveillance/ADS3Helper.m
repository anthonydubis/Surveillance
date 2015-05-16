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
    
    // Specify the key format as "objectID/videoName" to ensure uniqueness
    uploadRequest.key = [NSString stringWithFormat:@"%@/%@", event.user.objectId, event.videoName];
    
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

@end
