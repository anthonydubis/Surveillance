//
//  ADDownloadProgress.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/18/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADDownloadProgress.h"

@implementation ADDownloadProgress

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
        NSLog(@"Setting bytes to be downloaded %@", bytes);
        self.bytesToBeDownloaded = bytes;
    }
    return self;
}

- (int)secondsSinceLastUpdate
{
    return [[NSDate date] timeIntervalSinceDate:self.lastUpdate];
}

- (float)percentageDownloaded
{
    NSLog(@"Bytes to be downloaded %@ and bytes downloaded %@", self.bytesToBeDownloaded, self.bytesDownloaded);
    if (!self.bytesToBeDownloaded || !self.bytesDownloaded)
        return 0.0;
    else
        return (self.bytesDownloaded.doubleValue / self.bytesToBeDownloaded.doubleValue);
}

@end
