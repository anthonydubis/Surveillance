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

- (void)prepareForDeletion
{
    NSError *error = nil;
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:[NSString pathWithComponents:@[documentsPath, self.filename]]];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:fileURL.path isDirectory:NO]) {
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error];
        if (error) {
            NSLog(@"Error deleting underlying video: %@", error);
        }
    }
}

- (NSURL *)recordingURL
{
    return [[NSURL alloc] initFileURLWithPath:[NSString pathWithComponents:@[[self documentsPath], self.filename]]];
}

- (NSString *)documentsPath
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [searchPaths objectAtIndex:0];
}

@end
