//
//  ADDownloadProgress.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/18/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADDownloadTask.h"

@implementation ADDownloadTask

- (id)init
{
    self = [super init];
    if (self) {
        self.bytesDownloaded = [NSNumber numberWithInt:0];
        self.lastUpdate = [NSDate date];
    }
    return self;
}

- (id)initWithBytesToBeDownloaded:(NSNumber *)bytes
{
    self = [self init];
    if (self) {
        self.bytesToBeDownloaded = bytes;
    }
    return self;
}

- (id)initWithDownloadRequest:(AWSS3TransferManagerDownloadRequest *)request andBytesToBeDownloaded:(NSNumber *)bytes
{
    self = [self initWithBytesToBeDownloaded:bytes];
    if (self) {
        self.downloadRequest = request;
    }
    return self;
}

- (int)secondsSinceLastUpdate
{
    return [[NSDate date] timeIntervalSinceDate:self.lastUpdate];
}

- (double)percentageDownloaded
{
    if (!self.bytesToBeDownloaded || !self.bytesDownloaded) {
        return 0.0;
    } else {
        // Handle situations where pieces of a file need to be redownloaded, pushing percentage over 100%
        double percentage = self.bytesDownloaded.doubleValue / self.bytesToBeDownloaded.doubleValue;
        percentage = MIN(percentage, 1.0);
        
        return percentage;
    }
}

- (NSString *)downloadProgressString
{
    if (self.bytesToBeDownloaded.longLongValue == 0)
        return @"Downloading...";
    
    double percentage = [self percentageDownloaded];
    
    NSString *desc = [NSString stringWithFormat:@"Downloaded %@ of %@",
                      [self sizeStringForBytes:self.bytesDownloaded],
                      [self sizeStringForBytes:self.bytesToBeDownloaded]];
    NSString *pctStr = [NSString stringWithFormat:@", %.0f%%", percentage * 100];
    return [desc stringByAppendingString:pctStr];
}

- (NSString *)sizeStringForBytes:(NSNumber *)bytesNum
{
    long long bytes = bytesNum.longLongValue;
    
    if (bytes < 1000)
        return [NSString stringWithFormat:@"%lli bytes", bytes];
    else if (bytes < 1000000)
        return [NSString stringWithFormat:@"%.1f KB", (float)bytes / 1000];
    else if (bytes < 1000000000)
        return [NSString stringWithFormat:@"%.1f MB", (float)bytes / 1000000];
    else
        return [NSString stringWithFormat:@"%.1f GB", (float)bytes / 1000000000];
}

@end
