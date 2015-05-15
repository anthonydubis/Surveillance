//
//  Event.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/15/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <Parse/Parse.h>

@interface ADEvent : PFObject <PFSubclassing>

@property (nonatomic, strong) NSString *videoName;
@property (nonatomic, strong) NSString *s3BucketName;
@property (nonatomic, strong) NSDate *startedRecordingAt;
@property (nonatomic, strong) PFUser *user;
@property (nonatomic, assign) BOOL isStillRecording;

// Must be overriden by PFObject subclasses
+ (NSString *)parseClassName;

// Create a new ADEvent for an event that just started
+ (ADEvent *)objectForNewEvent;

@end
