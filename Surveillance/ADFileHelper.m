//
//  ADFileHelper.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/16/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADFileHelper.h"

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
    
    BOOL isDir;
    NSFileManager *fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:toUploadPath isDirectory:&isDir])
    {
        if([fm createDirectoryAtPath:toUploadPath withIntermediateDirectories:YES attributes:nil error:nil])
            NSLog(@"Directory Created");
        else
            NSLog(@"Directory Creation Failed");
    }
    else
    {
        NSLog(@"Directory Already Exist");
    }
    
    return toUploadPath;
}

+ (void)listAllFilesAtToUploadDirectory
{
    NSLog(@"Listing files at ToUpload directory.");
    NSString *toUploadPath = [self toUploadDirectoryPath];
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:toUploadPath error:NULL];

    for (int count = 0; count < [directoryContent count]; count++)
    {
        NSString *filename = [directoryContent objectAtIndex:count];
        NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[toUploadPath stringByAppendingPathComponent:filename]
                                                                                        error:nil];
        unsigned long long size = [fileDictionary fileSize];
        NSLog(@"File %d: %@, file size: %llu", count, [directoryContent objectAtIndex:count], size);
    }
}

@end
