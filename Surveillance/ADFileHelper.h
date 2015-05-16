//
//  ADFileHelper.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/16/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <Parse/Parse.h>

@interface ADFileHelper : PFObject

+ (NSString *)documentsPath;

/*
 * Returns the directory where videos that still need to be uploaded will be stored
 * Will create the ToUpload directory if it needs to
 */
+ (NSString *)toUploadDirectoryPath;

/*
 * Remove the file at the URL
 */
+ (void)removeFileAtURL:(NSURL *)url;

/*
 * List all of the files at the ToUpload directory
 */
+ (void)listAllFilesAtToUploadDirectory;

@end
