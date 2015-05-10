//
//  MonitoringEvent.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/7/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MonitoringEvent : NSManagedObject

@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSString *filename;

@end
