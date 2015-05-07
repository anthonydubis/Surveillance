//
//  MonitoringEvent+AD.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/7/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "MonitoringEvent+AD.h"

@implementation MonitoringEvent (AD)

+ (MonitoringEvent *)newEventWithDate:(NSDate *)date andFilename:(NSString *)filename inContext:(NSManagedObjectContext *)context
{
    MonitoringEvent *event = [NSEntityDescription insertNewObjectForEntityForName:@"MonitoringEvent" inManagedObjectContext:context];
    event.date = date;
    event.filename = filename;
    return event;
}

+ (NSArray *)eventsInContext:(NSManagedObjectContext *)context orderedByDateAscd:(BOOL)ascd
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MonitoringEvent"];
    NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:ascd]];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSError *error = nil;
    return [context executeFetchRequest:fetchRequest error:&error];
}

@end
