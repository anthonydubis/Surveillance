//
//  ADNotificationHelper.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/19/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ADEventImage;
@class PFInstallation;

@interface ADNotificationHelper : NSObject

// Call this when the user has logged in so ADNotificationHelper can get notifications setup
+ (void)setupNotifications;

// Called only when Apple let's us know we've successfully registered for remote notifications
+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

// Call this when the user tries to enable push notifications but doesn't have them enabled
+ (void)userRequestedToEnablePushNotifications;

// NOTIFICATIONS

// Send notification to users other devices that motion was detected
+ (void)sendMotionDetectedNotification;

// Send notification to users other devices that motion has ended
+ (void)sendMotionEndedNotification;

// Send notification to users other devices when the camera was disabled while recording
+ (void)sendCameraWasDisabledWhileRecordingNotification;

// Send a notification to the user with an image for an event (such as a picture taken when a face is detected)
+ (void)sendFaceDetectedNotificationWithEventImage:(ADEventImage *)eventImage;

// Send a notification to a monitoring installation to tell it to stop monitoring
+ (void)sendMessageToDisableMonitoringInstallation:(PFInstallation *)monitoringInstallation;

@end
