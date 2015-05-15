//
//  Event.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/15/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADEvent.h"
#import <Parse/PFObject+Subclass.h>

@implementation ADEvent

@dynamic videoName;
@dynamic s3BucketName;
@dynamic user;

// This gets called before Parse's setApplicationId:clientKey:
+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"ADEvent";
}

@end
