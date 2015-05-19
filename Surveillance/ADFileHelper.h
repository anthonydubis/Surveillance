//
//  ADFileHelper.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/16/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <Parse/Parse.h>
@class ADEvent;

@interface ADFileHelper : PFObject

+ (NSString *)documentsPath;

/*
 * Returns the directory where videos that still need to be uploaded will be stored
 * Will create the ToUpload directory if it needs to
 */
+ (NSString *)toUploadDirectoryPath;

/*
 * Returns the directory where videos of the users choosing are stored locally.
 * Creates the Downloads directory if needed.
 */
+ (NSString *)downloadsDirectoryPath;

/*
 * List all of the files at the ToUpload directory
 */
+ (void)listAllFilesAtToUploadDirectory;

/*
 * List all files in the documents directory
 */
+ (void)listAllFilesInDocumentsDirectory;

/*
 * List all files and sizes in the documents directory
 */
+ (void)listAllFilesInDownloadsDirectory;

/*
 * Returns true if we have a local copy of the event video
 * Note, this is true even if only part of the video has been downloaded
 */
+ (BOOL)haveDownloadedVideoForEvent:(ADEvent *)event;

/*
 * Returns the NSURL to a video for an event.
 * Assumes the caller has already checked that the video exists
 */
+ (NSURL *)urlToDownloadedVideoForEvent:(ADEvent *)event;

/*
 * Remove the video associated with an event.
 * Assumes the caller has already checked that the video exists
 */
+ (BOOL)removeLocalCopyOfVideoForEvent:(ADEvent *)event;

/*
 * Return the file size of the file at the given URL in bytes
 */
+ (NSNumber *)sizeOfFileAtURL:(NSURL *)fileURL;

@end
