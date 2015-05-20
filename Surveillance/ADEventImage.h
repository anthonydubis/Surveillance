//
//  ADEventImage.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/19/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <Parse/Parse.h>
#import "ADEvent.h"

@interface ADEventImage : PFObject <PFSubclassing>

@property (nonatomic, strong) PFFile *image;
@property (nonatomic, strong) ADEvent *event;
@property (nonatomic, strong) NSNumber *numFaces;
@property (nonatomic, assign) BOOL hasBeenViewed;

// Must be overriden by PFObject subclasses
+ (NSString *)parseClassName;

/*
 * A new EventImage for an image that was just taken
 */
+ (ADEventImage *)objectForNewEventImageForEvent:(ADEvent *)event;

@end
