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

- (int)secondsSinceLastUpdate
{
    return [[NSDate date] timeIntervalSinceDate:self.lastUpdate];
}


@end
