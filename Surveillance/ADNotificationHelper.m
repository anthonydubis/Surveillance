//
//  ADNotificationHelper.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/19/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADNotificationHelper.h"
#import <Parse/Parse.h>

NSString *PromptedUserToEnablePushNotificationsPrefKey = @"PromptedUserToEnablePushNotificationsPrefKey";
NSString *ShowedUserNotificationsPermissionPanelPrefKey = @"ShowedUserNotificationsPermissionPanelPrefKey";

@implementation ADNotificationHelper

+ (void)setupNotifications
{
    NSLog(@"Setting up notificiations");
    // Do nothing if the user is not logged in
    if (![PFUser currentUser])
        return;
    
    // Do nothing if we're already setup for notifications
    if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
        NSLog(@"The user is already enabled for notifications");
        return;
    } else if (![[NSUserDefaults standardUserDefaults] boolForKey:PromptedUserToEnablePushNotificationsPrefKey]) {
        // Prompt user to setup push notifications
        [self promptUserToRegisterForPushNotifications];
    } else {
        // It looks like Apple will automatically register us if the user enables notifications in his settings
        // Try registering for notifications to see if the user has enabled this in their settings
        // [self registerForNotifications];
    }
}

+ (void)registerForNotifications
{
    NSLog(@"Registering for notifications");
    UIApplication *application = [UIApplication sharedApplication];
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"Did register for remote notifications");
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    
    currentInstallation.channels = @[[[PFUser currentUser] objectId]];
    currentInstallation[@"user"] = [PFUser currentUser];
    currentInstallation[@"model"] = [[UIDevice currentDevice] model];
    currentInstallation[@"deviceName"] = [[UIDevice currentDevice] name];
    currentInstallation[@"isMonitoring"] = @NO;
    currentInstallation[@"deviceID"] = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    [currentInstallation saveInBackground];
}

+ (void)promptUserToRegisterForPushNotifications
{
    UIApplication *application = [UIApplication sharedApplication];
    [UIAlertView showWithTitle:@"Motion Detection Alerts"
                       message:@"Surveillance can send notifications to your other iOS devices when your device functioning as a camera detects motion. Would you like to enable this?"
             cancelButtonTitle:@"Not Now"
             otherButtonTitles:@[@"Yes"]
                      tapBlock:^(UIAlertView *av, NSInteger buttonIndex) {
                          if (buttonIndex != av.cancelButtonIndex) {
                              // Register for notifications
                              UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                                              UIUserNotificationTypeBadge |
                                                                              UIUserNotificationTypeSound);
                              UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                                                       categories:nil];
                              [application registerUserNotificationSettings:settings];
                              [application registerForRemoteNotifications];
                              [[NSUserDefaults standardUserDefaults] setBool:YES forKey:PromptedUserToEnablePushNotificationsPrefKey];
                              [[NSUserDefaults standardUserDefaults] synchronize];
                          }
                      }];
}

+ (void)userRequestedToEnablePushNotifications
{
#warning Implement this
}

@end
