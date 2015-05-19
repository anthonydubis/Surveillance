//
//  ADNotificationHelper.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/19/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADNotificationHelper : NSObject

// Call this when the user has logged in so ADNotificationHelper can get notifications setup
+ (void)setupNotifications;

// Called only when Apple let's us know we've successfully registered for remote notifications
+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

// Call this when the user tries to enable push notifications but doesn't have them enabled
+ (void)userRequestedToEnablePushNotifications;

// Send notification to users other devices that motion was detected
+ (void)sendMotionDetectedNotification;

// Send notification to users other devices that motion has ended
+ (void)sendMotionEndedNotification;


@end
