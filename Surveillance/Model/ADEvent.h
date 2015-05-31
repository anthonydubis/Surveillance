//
//  Event.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/15/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <Parse/Parse.h>

extern NSString * const EventStatusRecording;
extern NSString * const EventStatusUploading;
extern NSString * const EventStatusUploaded;

@interface ADEvent : PFObject <PFSubclassing>

@property (nonatomic, strong) NSString *videoName;
@property (nonatomic, strong) NSString *s3BucketName;
@property (nonatomic, strong) NSDate *startedRecordingAt;
@property (nonatomic, strong) PFUser *user;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSNumber *videoSize;
@property (nonatomic, strong) NSNumber *videoDuration;
@property (nonatomic, strong) PFInstallation *installation;

// Must be overriden by PFObject subclasses
+ (NSString *)parseClassName;

/*
 * A new Event for an event that just started
 * At this point, no video has been uploaded as we are still recording.
 */
+ (ADEvent *)objectForNewEvent;

/*
 * Gives a user-presentable description of the videos metadata (size/duration)
 */
- (NSString *)descriptionOfMetadata;

/*
 * Give the video size in a user presentable string
 */
- (NSString *)sizeString;

@end
