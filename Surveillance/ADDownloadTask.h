//
//  ADDownloadProgress.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/18/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//
//  This class helps us manage the progress of current downloads, specifically,
//  it contains information that will help us update the UI.

#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>

@interface ADDownloadTask : NSObject

// The download request associated with this information
@property (nonatomic, strong) AWSS3TransferManagerDownloadRequest *downloadRequest;

// The last time the UI was updated
@property (nonatomic, strong) NSDate *lastUpdate;

// Number of bytes you've downloaded so far
@property (nonatomic, strong) NSNumber *bytesDownloaded;

// Number of bytes you expect to download
@property (nonatomic, strong) NSNumber *bytesToBeDownloaded;

- (id)initWithBytesToBeDownloaded:(NSNumber *)bytes;

- (id)initWithDownloadRequest:(AWSS3TransferManagerDownloadRequest *)request andBytesToBeDownloaded:(NSNumber *)bytes;

// The amount of seconds that have passed since the UI was updated
- (int)secondsSinceLastUpdate;

// Returns the percentage downloaded so far
- (double)percentageDownloaded;

/*
 * A user presentable string for the number of bytes downloaded, and the percentage
 * xx MB of xx MB, xx%
 */
- (NSString *)downloadProgressString;

@end
