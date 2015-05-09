//
//  MonitoringEvent+AD.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/7/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "MonitoringEvent.h"

@interface MonitoringEvent (AD)

+ (MonitoringEvent *)newEventWithDate:(NSDate *)date andFilename:(NSString *)filename inContext:(NSManagedObjectContext *)context;
+ (NSArray *)eventsInContext:(NSManagedObjectContext *)context orderedByDateAscd:(BOOL)ascd;

/*
 * Get the URL that the video should be saved to.
 */
- (NSURL *)recordingURL;

@end
