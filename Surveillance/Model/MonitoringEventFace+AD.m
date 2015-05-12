//
//  MonitoringEventFace+AD.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/11/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "MonitoringEventFace+AD.h"

@implementation MonitoringEventFace (AD)

+ (MonitoringEventFace *)newFaceWithData:(NSData *)data forEvent:(MonitoringEvent *)event inContext:(NSManagedObjectContext *)context
{
    MonitoringEventFace *face = [NSEntityDescription insertNewObjectForEntityForName:@"MonitoringEventFace" inManagedObjectContext:context];
    face.imageData = data;
    face.monitoringEvent = event;
    
    return face;
}

@end
