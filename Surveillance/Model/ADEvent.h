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
@property (nonatomic, strong) NSNumber *videoSize;
@property (nonatomic, strong) NSNumber *videoDuration;

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
 * Gives a string back that describes the bytes that have been received compared to the size of the video
 */
- (NSString *)percentDownloadedStringForBytesReceived:(NSNumber *)bytes;

@end
