//
//  Event.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/15/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADEvent.h"
#import <Parse/PFObject+Subclass.h>

@implementation ADEvent

@dynamic videoName;
@dynamic s3BucketName;
@dynamic startedRecordingAt;
@dynamic user;

// This gets called before Parse's setApplicationId:clientKey:
+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"ADEvent";
}

+ (ADEvent *)objectForNewEvent
{
    ADEvent *event = [ADEvent object];
    
    event.startedRecordingAt = [NSDate date];
    event.isStillRecording = YES;
    event.user = [PFUser currentUser];
    event.videoName = [self videoNameForEvent:event];
    
    return event;
}

// This method assumes the startedRecordingAt field has been set
+ (NSString *)videoNameForEvent:(ADEvent *)event
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"America/Los_Angeles"];
    [df setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    NSString *dateString = [df stringFromDate:event.startedRecordingAt];
    NSString *videoName = [NSString stringWithFormat:@"%@.mp4", dateString];
    
    return videoName;
}

@end
