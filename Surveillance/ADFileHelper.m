//
//  ADFileHelper.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/16/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADFileHelper.h"
#import "ADEvent.h"

@implementation ADFileHelper

+ (NSString *)documentsPath
{
  NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  return [searchPaths objectAtIndex:0];
}

+ (NSString *)toUploadDirectoryPath
{
  NSString *documentsPath = [self documentsPath];
  NSString *toUploadPath = [documentsPath stringByAppendingPathComponent:@"ToUpload"];
  [self createDirectoryIfNeededPath:toUploadPath];
  
  return toUploadPath;
}

+ (NSString *)libraryCachesPath
{
  NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  return [searchPaths objectAtIndex:0];
}

+ (NSString *)downloadsTemporaryDirectoryPath
{
  NSString *downloadsPath = [self downloadsDirectoryPath];
  NSString *tmpDownloadsPath = [downloadsPath stringByAppendingPathComponent:@"Downloading"];
  [self createDirectoryIfNeededPath:tmpDownloadsPath];
  
  return tmpDownloadsPath;
}

+ (NSString *)downloadsDirectoryPath
{
  NSString *documentsPath = [self libraryCachesPath];
  NSString *downloadsPath = [documentsPath stringByAppendingPathComponent:@"Downloads"];
  [self createDirectoryIfNeededPath:downloadsPath];
  
  return downloadsPath;
}

+ (void)createDirectoryIfNeededPath:(NSString *)dirPath
{
  BOOL isDir;
  NSFileManager *fm = [NSFileManager defaultManager];
  if(![fm fileExistsAtPath:dirPath isDirectory:&isDir])
  {
    if([fm createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil])
      NSLog(@"Directory Created");
  }
}

+ (void)listAllFilesAtDirectoryPath:(NSString *)dirPath
{
  NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:NULL];
  
  for (int count = 0; count < [directoryContent count]; count++)
  {
    NSString *filename = [directoryContent objectAtIndex:count];
    NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[dirPath stringByAppendingPathComponent:filename]
                                                                                    error:nil];
    unsigned long long size = [fileDictionary fileSize];
    NSLog(@"File %d: %@, file size: %llu", count, [directoryContent objectAtIndex:count], size);
  }
}

+ (void)listAllFilesInDocumentsDirectory
{
  NSLog(@"List files at Documents directory.");
  NSString *documentsPath = [self documentsPath];
  [self listAllFilesAtDirectoryPath:documentsPath];
}

+ (void)listAllFilesAtToUploadDirectory
{
  NSString *toUploadPath = [self toUploadDirectoryPath];
  // NSLog(@"Listing files at ToUpload directory: %@", toUploadPath);
  NSLog(@"*****Listing files in ToUpload directory*****");
  [self listAllFilesAtDirectoryPath:toUploadPath];
}

+ (void)listAllFilesInDownloadsTemporaryDirectory
{
  NSString *downloadsTemp = [self downloadsTemporaryDirectoryPath];
  // NSLog(@"Listing files at temporary downloads directory: %@", downloadsTemp);
  NSLog(@"*****Listing files at temporary downloads directory*****");
  [self listAllFilesAtDirectoryPath:downloadsTemp];
}

+ (void)listAllFilesInDownloadsDirectory
{
  NSString *downloadsPath = [self downloadsDirectoryPath];
  // NSLog(@"Listing files at Downloads directory: %@", downloadsPath);
  NSLog(@"*****Listing files at downloads directory*****");
  [self listAllFilesAtDirectoryPath:downloadsPath];
}

+ (BOOL)haveDownloadedVideoForEvent:(ADEvent *)event
{
  NSString *videoPath = [[self downloadsDirectoryPath] stringByAppendingPathComponent:event.videoName];
  return [[NSFileManager defaultManager] fileExistsAtPath:videoPath];
}

+ (NSURL *)urlToDownloadedVideoForEvent:(ADEvent *)event
{
  return [NSURL fileURLWithPath:[[self downloadsDirectoryPath]
                                 stringByAppendingPathComponent:event.videoName]];
}

+ (BOOL)removeLocalCopyOfVideoForEvent:(ADEvent *)event
{
  NSURL *url = [self urlToDownloadedVideoForEvent:event];
  return [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
}

+ (NSNumber *)sizeOfFileAtURL:(NSURL *)fileURL
{
  NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[fileURL path] error:nil];
  return [NSNumber numberWithLongLong:[fileDictionary fileSize]];
}

@end
