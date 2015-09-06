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

/*
 * Return the documents path for our app
 * This will hold newly created videos that have not been uploaded to S3 yet
 */
+ (NSString *)documentsPath;

/*
 * Return the library cache path for our app
 * This will hold user downloaded videos (that can be redownloaded if purged)
 */
+ (NSString *)libraryCachesPath;

/*
 * Returns the directory where videos that still need to be uploaded will be stored
 * Will create the ToUpload directory if it needs to
 */
+ (NSString *)toUploadDirectoryPath;

/**
 This temporary directory is used as the place videos are downloaded to. When the download
 is completed, we should move those videos to the actual downloadsDirectoryPath
 */
+ (NSString *)downloadsTemporaryDirectoryPath;

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

/**
 Lists all files in the temp directory that videos are downloaded to before being moved
 into their permanent directory.
 */
+ (void)listAllFilesInDownloadsTemporaryDirectory;

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

/**
 Convenience method for renaming a file. Returns an NSURL of the renamed file
 */
+ (NSURL *)renameFileAtURL:(NSURL *)url withName:(NSString *)name;

/*
 * Return the file size of the file at the given URL in bytes
 */
+ (NSNumber *)sizeOfFileAtURL:(NSURL *)fileURL;

/**
 Remove any downloaded files that are not associated with the array of events passed it.
 The array of events should be an up-to-date list of events just fetched from the server with
 the goal of deleting downloads for events that were deleted on other devices.
 */
+ (void)removeDownloadsNotAssociatedWithEvents:(NSArray *)events;

/**
 Convenience method for getting the enumerator for all of the non-hidden files at a URL
 */
+ (NSDirectoryEnumerator *)directoryEnumeratorForURL:(NSURL *)url;


@end
