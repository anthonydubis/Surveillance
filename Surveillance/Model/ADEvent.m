//
//  Event.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/15/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADEvent.h"
#import <Parse/PFObject+Subclass.h>

NSString * const EventStatusRecording = @"Recording";
NSString * const EventStatusUploading = @"Uploading";
NSString * const EventStatusUploaded  = @"Uploaded";

@implementation ADEvent

@dynamic videoName;
@dynamic s3BucketName;
@dynamic startedRecordingAt;
@dynamic user;
@dynamic status;
@dynamic videoSize;
@dynamic videoDuration;
@dynamic installation;

// This gets called before Parse's setApplicationId:clientKey:
+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"Event";
}

+ (ADEvent *)objectForNewEvent
{
    ADEvent *event = [ADEvent object];
    
    event.startedRecordingAt = [NSDate date];
    event.status = EventStatusRecording;
    event.user = [PFUser currentUser];
    event.videoName = [self videoNameForEvent:event];
    event.installation = [PFInstallation currentInstallation];
    
    return event;
}

// This method assumes the startedRecordingAt field has been set
+ (NSString *)videoNameForEvent:(ADEvent *)event
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.timeZone = [NSTimeZone timeZoneWithName:@"America/Los_Angeles"];
    [df setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    NSString *dateString = [df stringFromDate:event.startedRecordingAt];
    NSString *videoName = [NSString stringWithFormat:@"%@.mp4", dateString];
    
    return videoName;
}

- (NSString *)descriptionOfMetadata
{
    if ([self.status isEqualToString:EventStatusRecording])
    {
        return @"Still recording...";
    }
    else if ([self.status isEqualToString:EventStatusUploading])
    {
        return @"Uploading video to server...";
    }
    else
    {
        return [NSString stringWithFormat:@"%@ - %@", [self durationString], [self sizeString]];
    }
}

- (NSString *)durationString
{
    int time = self.videoDuration.intValue;
    
    if (time == 0) return @"00:00";
    
    int hours = time / 3600;
    time = time % 3600;
    
    int minutes = time / 60;
    time = time % 60;
    
    int seconds = time;
    
    if (hours > 0) {
        return [NSString stringWithFormat:@"%02i:%02i:%02i", hours, minutes, seconds];
    } else {
        return [NSString stringWithFormat:@"%02i:%02i", minutes, seconds];
    }
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

- (NSString *)sizeString
{
    return [self sizeStringForBytes:self.videoSize];
}

@end
