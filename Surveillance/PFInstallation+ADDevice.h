//
//  PFInstallation+ADDevice.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/22/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <Parse/Parse.h>

@interface PFInstallation (ADDevice)

@property (nonatomic, strong) NSString *deviceName;
@property (nonatomic, assign) BOOL isMonitoring;
@property (nonatomic, strong) NSString *model;

- (BOOL)isiPhone;
- (BOOL)isiPad;

@end
