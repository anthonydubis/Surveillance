//
//  MonitoringEventFace+AD.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/11/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "MonitoringEventFace.h"

@interface MonitoringEventFace (AD)

+ (MonitoringEventFace *)newFaceWithData:(NSData *)data forEvent:(MonitoringEvent *)event inContext:(NSManagedObjectContext *)context;

@end
