//
//  PFInstallation+ADDevice.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/22/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <Parse/Parse.h>

@interface PFInstallation (ADDevice)

@property (nonatomic, strong) PFUser *user;
@property (nonatomic, strong) NSString *deviceName;
@property (nonatomic, assign) BOOL isMonitoring;
@property (nonatomic, strong) NSString *model;
@property (nonatomic, strong) NSString *deviceID;

// Sets up the initial properties of a device (name, type, model, etc.)
+ (void)setupCurrentInstallation;

// The current installation should be set to is monitoring
+ (void)deviceBeganMonitoring;

// The current installation should be set to no longer monitoring
+ (void)deviceStoppedMonitoring;

- (BOOL)isiPhone;
- (BOOL)isiPad;

@end
