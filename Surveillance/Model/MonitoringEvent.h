//
//  MonitoringEvent.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/11/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MonitoringEventFace;

@interface MonitoringEvent : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSSet *faces;
@end

@interface MonitoringEvent (CoreDataGeneratedAccessors)

- (void)addFacesObject:(MonitoringEventFace *)value;
- (void)removeFacesObject:(MonitoringEventFace *)value;
- (void)addFaces:(NSSet *)values;
- (void)removeFaces:(NSSet *)values;

@end
