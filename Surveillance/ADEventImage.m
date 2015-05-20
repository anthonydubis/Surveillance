//
//  ADEventImage.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/19/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADEventImage.h"

@implementation ADEventImage

@dynamic image;
@dynamic event;
@dynamic numFaces;
@dynamic hasBeenViewed;

// This gets called before Parse's setApplicationId:clientKey:
+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"EventImage";
}

+ (ADEventImage *)objectForNewEventImageForEvent:(ADEvent *)event
{
    ADEventImage *eventImage = [ADEventImage object];
    
    eventImage.hasBeenViewed = NO;
    eventImage.event = event;
    
    return eventImage;
}

@end
