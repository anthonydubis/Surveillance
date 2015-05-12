//
//  MonitoringEventFace.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/11/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MonitoringEvent;

@interface MonitoringEventFace : NSManagedObject

@property (nonatomic, retain) NSData * imageData;
@property (nonatomic, retain) MonitoringEvent *monitoringEvent;

@end
