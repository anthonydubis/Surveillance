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

@interface ADDownloadProgress : NSObject

// The last time the UI was updated
@property (nonatomic, strong) NSDate *lastUpdate;

// Amount of file downloaded in bytes
@property (nonatomic, strong) NSNumber *bytesDownloaded;

// The amount of seconds that have passed since the UI was updated
- (int)secondsSinceLastUpdate;

@end
