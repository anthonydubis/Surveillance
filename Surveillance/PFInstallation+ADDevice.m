//
//  PFInstallation+ADDevice.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/22/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "PFInstallation+ADDevice.h"

@implementation PFInstallation (ADDevice)

+ (void)setupCurrentInstallation
{
    PFInstallation *installation = [PFInstallation currentInstallation];
    installation.user = [PFUser currentUser];
    installation.model = [[UIDevice currentDevice] model];
    installation.deviceName = [[UIDevice currentDevice] name];
    installation.isMonitoring = NO;
    installation.deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    [installation saveEventually];
}

+ (void)deviceBeganMonitoring
{
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation[@"isMonitoring"] = @YES;
    [currentInstallation saveInBackground];
}

+ (void)deviceStoppedMonitoring
{
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation[@"isMonitoring"] = @NO;
    [currentInstallation saveInBackground];
}

- (PFUser *)user {
    return self[@"user"];
}

- (void)setUser:(PFUser *)user {
    self[@"user"] = user;
}

- (NSString *)deviceName {
    return self[@"deviceName"];
}

- (void)setDeviceName:(NSString *)deviceName {
    self[@"deviceName"] = deviceName;
}

- (BOOL)isMonitoring {
    return [self[@"isMonitoring"] boolValue];
}

- (void)setIsMonitoring:(BOOL)isMonitoring {
    self[@"isMonitoring"] = [NSNumber numberWithBool:isMonitoring];
}

- (NSString *)model {
    return self[@"model"];
}

- (void)setModel:(NSString *)model {
    self[@"model"] = model;
}

- (NSString *)deviceID {
    return self[@"deviceID"];
}

- (void)setDeviceID:(NSString *)deviceID {
    self[@"deviceID"] = deviceID;
}

- (BOOL)isiPad {
    return [self[@"model"] isEqualToString:@"iPad"];
}

- (BOOL)isiPhone {
    return [self[@"model"] isEqualToString:@"iPhone"];
}

@end
