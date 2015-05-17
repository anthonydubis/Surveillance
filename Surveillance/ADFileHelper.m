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

+ (NSString *)downloadsDirectoryPath
{
    NSString *documentsPath = [self documentsPath];
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
    NSLog(@"Listing files at ToUpload directory.");
    NSString *toUploadPath = [self toUploadDirectoryPath];
    [self listAllFilesAtDirectoryPath:toUploadPath];
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

@end
