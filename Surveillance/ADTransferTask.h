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

@interface ADTransferTask : NSObject

+ (NSString *)sizeStringForBytes:(NSNumber *)bytesNum;

// The download request associated with this information
@property (nonatomic, strong) AWSS3TransferManagerDownloadRequest *downloadRequest;

// The last time the UI was updated
@property (nonatomic, strong) NSDate *lastUpdate;

// Number of bytes you've transferred so far
@property (nonatomic, strong) NSNumber *bytesTransferred;

// Number of bytes you expect to transfer
@property (nonatomic, strong) NSNumber *bytesToBeTransferred;

- (id)initWithBytesToBeTransferred:(NSNumber *)bytes;
- (id)initWithDownloadRequest:(AWSS3TransferManagerDownloadRequest *)request andBytesToBeDownloaded:(NSNumber *)bytes;

// The amount of seconds that have passed since the UI was updated
- (int)secondsSinceLastUpdate;

// Returns the percentage transferred so far
- (double)percentageTransferred;

/*
 * A user presentable string for the number of bytes transferred, and the percentage
 * xx MB of xx MB, xx%
 */
- (NSString *)downloadProgressString;

- (NSString *)uploadProgressString;

@end
