//
//  PFInstallation+ADDevice.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/22/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "PFInstallation+ADDevice.h"

@implementation PFInstallation (ADDevice)

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

- (BOOL)isiPad {
    return [self[@"model"] isEqualToString:@"iPad"];
}

- (BOOL)isiPhone {
    return [self[@"model"] isEqualToString:@"iPhone"];
}

@end
