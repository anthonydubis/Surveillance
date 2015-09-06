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

+ (void)cancelAllRequests
{
  [[AWSS3TransferManager defaultS3TransferManager] cancelAll];
}

+ (void)uploadFilesIfNecessary
{
  /*
   Iterate through files in toUpload directory. If there are any, find the correspond ADEvent.
   If an ADEvent exists for the file, upload it. If not, the file should probably be deleted.
   */
  PFQuery *query = [self _queryForEventsInLocalDatastore];
  [[query findObjectsInBackground] continueWithSuccessBlock:^id(BFTask *task) {
    NSDictionary *events = [ADEvent dictionaryOfEventsForVideoNames:task.result];
    [self _uploadFilesInToUploadDirectoryWithEvents:events];
    return task;
  }];
}

+ (PFQuery *)_queryForEventsInLocalDatastore
{
  PFQuery *query = [PFQuery queryWithClassName:[ADEvent parseClassName]];
  [query orderByDescending:@"createdAt"];
  [query fromLocalDatastore];
  return query;
}

+ (void)_uploadFilesInToUploadDirectoryWithEvents:(NSDictionary *)events
{
  NSURL *toUploadURL = [NSURL fileURLWithPath:[ADFileHelper toUploadDirectoryPath]];
  NSDirectoryEnumerator *dirEnumerator = [ADFileHelper directoryEnumeratorForURL:toUploadURL];
  
  for (NSURL *url in dirEnumerator) {
    NSString *videoName = [[url path] lastPathComponent];
    ADEvent *event = events[videoName];
    if (event) {
      // Try uploading the video again
      [self uploadVideoAtURL:url
                    forEvent:event];
    } else {
      // Delete the video because it's not tied to an event
      [[NSFileManager defaultManager] removeItemAtURL:url
                                                error:nil];
    }
  }
}

#warning LAUNCH BLOCKER - Handle errors here
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
    } else if (task.result) {
      // The file uploaded successfully. Update the Parse object
      NSLog(@"File uploaded successfully");
      event.s3BucketName = BucketName;
      event.status = EventStatusUploaded;
      [event saveEventually];
#warning You need to handle failures here
      if ([[NSFileManager defaultManager] removeItemAtURL:url error:nil])
        NSLog(@"Removed file");
      else
        NSLog(@"Couldn't remove file.");
      // Uncomment for debugging purposes
      // [ADFileHelper listAllFilesAtToUploadDirectory];
    }
    return nil;
  };
  
  // Start he upload
  [[manager upload:uploadRequest] continueWithExecutor:[BFExecutor mainThreadExecutor]
                                             withBlock:completionBlock];
}

+ (AWSS3TransferManagerDownloadRequest *)downloadVideoForEvent:(ADEvent *)event
                                               completionBlock:(id(^)(BFTask *task))completionBlock
                                                 progressBlock:(AWSNetworkingDownloadProgressBlock)progressBlock;
{
  // Temporary URL to store the data while it's being downloaded
  NSString *tmpPath = [[ADFileHelper downloadsTemporaryDirectoryPath] stringByAppendingPathComponent:event.videoName];
  NSURL *tmpUrl = [NSURL fileURLWithPath:tmpPath];
  
  // Construct the download request.
  AWSS3TransferManagerDownloadRequest *downloadRequest = [self downloadRequestForEvent:event andDownloadURL:tmpUrl];
  downloadRequest.downloadProgress = progressBlock;
  
  // Construct the completion block
  id (^handler)(BFTask *task) = ^id(BFTask *task) {
    if (task.error){
      // Remove file from temp directory
      if ([[NSFileManager defaultManager] fileExistsAtPath:tmpPath]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:&error];
        if (error) {
          NSLog(@"ERROR REMOVING DOWNLOAD FROM TMP DIRECTORY: %@", error);
        }
      }
    } else if (task.result) {
      NSLog(@"File downloaded successfully");
      // Move to permanent directory
      NSError *error = nil;
      NSString *finalUrlPath = [[ADFileHelper downloadsDirectoryPath] stringByAppendingPathComponent:event.videoName];
      // Make sure no final currently exists there
      if ([[NSFileManager defaultManager] fileExistsAtPath:finalUrlPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:finalUrlPath error:&error];
        if (error) {
          NSLog(@"ERROR REMOVING EXISTING DOWNLOAD FROM DOWNLOAD DIRECTORY: %@", error);
        }
      }
      [[NSFileManager defaultManager] moveItemAtPath:tmpPath
                                              toPath:finalUrlPath
                                               error:&error];
      if (error) {
        NSLog(@"FAILED TO MOVE DOWNLOAD TO PERMANENT DIRECTORY: %@", error);
      }
    }
    if (completionBlock != nil) {
      completionBlock(task);
    }
    return nil;
  };
  
  // Start the process with the transfer manager
  AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
  [[transferManager download:downloadRequest] continueWithExecutor:[BFExecutor mainThreadExecutor]
                                                         withBlock:handler];
  return downloadRequest;
}

+ (AWSS3TransferManagerDownloadRequest *)downloadRequestForEvent:(ADEvent *)event andDownloadURL:(NSURL *)url
{
  // Construct the download request.
  AWSS3TransferManagerDownloadRequest *downloadRequest = [AWSS3TransferManagerDownloadRequest new];
  downloadRequest.bucket = BucketName;
  downloadRequest.key = [self keyForEvent:event];
  downloadRequest.downloadingFileURL = url;
  return downloadRequest;
}

+ (void)deleteVideoForEvent:(ADEvent *)event withSuccessBlock:(void(^)(void))successBlock
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
                                                          UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Sorry"
                                                                                                       message:@"There was an error deleting this video. Please make sure you're connected to the internet and try again."
                                                                                                      delegate:nil
                                                                                             cancelButtonTitle:@"OK"
                                                                                             otherButtonTitles:nil];
                                                          [av show];
                                                        }
                                                      } else{
                                                        if (successBlock != nil) {
                                                          successBlock();
                                                        }
                                                      }
                                                      return nil;
                                                    }];
}

// Specify the key format as "objectID/videoName" to ensure uniqueness
+ (NSString *)keyForEvent:(ADEvent *)event
{
  return [NSString stringWithFormat:@"%@/%@", event.user.objectId, event.videoName];
}

//
+ (int)getSizeOfVideoForEvent:(ADEvent *)event
{
  //    S3GetObjectMetadataRequest *request =
  //    [[S3GetObjectMetadataRequest alloc] initWithKey:FILE_NAME withBucket:BUCKET_NAME];
  //    S3GetObjectMetadataResponse *response = [s3 getObjectMetadata:request];
  //    int64_t fileSize = response.contentLength;
  return 0;
}

@end
