********************************************************************************
COPYRIGHT & LICENSING 
********************************************************************************

Copyright 2015, Anthony Dubis, All rights reserved

This project is owned exclusively by me, Anthony Dubis (anthonydubis@gmail.com),
and cannot be viewed, copied, distributed, or used in any way without my
explicit permission.

The state of the project as it was on May 23th, 2015 was submitted for a project
grade in Cloud Computing & Big Data (COMS 6998 - Columbia University). The
associated team members, teaching assistants, and instructor have permission to
view and test the project on their own personal computers and iOS devices for
the sole purpose of grading. Beyond that, the project cannot be shared with
anyone else without permission.

The state of the project as it was on May 12th, 2015 was submitted for a project
grade in Visual Interfaces to Computers (COMS 4735 - Columbia University). The
associated team member, teaching assistants, and instructor have permission to
view and test the project on their own personal computers and iOS devices for
the sole purpose of grading. Beyond that, the project cannot be shared with
anyone else without permission.

********************************************************************************
INSTALLATION 
********************************************************************************

The app can be run as is using Xcode until the grading period ends for the
Spring 2015 semester of Columbia University.

********************************************************************************
OVERVIEW 
********************************************************************************

Surveillance is an iOS app that is meant to turn your iOS device into a
surveillance camera. At a high level, the app uses the camera in the following
way:

1. It monitors an area by processing the video frames at 30FPS to check for
motion. 
2. If motion occurs, it begins recording a video of what is going on in
the frame. 
3. While recording, it tries to detect faces in the frame. If a face is 
detected, the frame is converted to an image and sent to the user via  a
notification. 
4. The app continues to record until it decides motion has ended. At this point, 
the recording is wrapped up and the camera enters the monitoring state again to 
detect further motion.

The app also allows the user to specify settings to control the app's behavior.
For example, the user can:

- Specify events that should cause the camera device to play a sound (beep) 
- Specify events that send notifications to the users other devices so the user 
is informed of their occurence (motion began, motion ended, camera disabled) 
- View all of the user's devices and their current status (monitoring or not) 
- Remotely send a "disable" message to a device that is monitoring an area from
one of the user's other devices

********************************************************************************
MOTION AND FACE DETECTION 
********************************************************************************

Motion detection is performed by calculating the absolute difference between a
background frame and the current frame. If the difference is large enough,
motion has occurred.

Face detection is performed using Apple's CoreImage framework.

********************************************************************************
LOCAL STORAGE 
********************************************************************************

As videos are recorded, they are uploaded to the backend and removed from the
device as quickly as possible to free space on the device. The user can later
choose which videos they want to download locally for viewing.

********************************************************************************
BACKEND SUPPORT 
********************************************************************************

The app's backend consists of a Parse datastore for handling most of the user
and event data. Parse is also utilized for registering a user, sending
notifications between a users devices, and running certain pieces of code in the
cloud to provide a layer between the client and the datastore.

Because Parse is incapable of handling files larger than 10MB, the app uses AWS
S3 to store the recorded videos.

********************************************************************************
KEY FRAMEWORKS AND CLASSES
********************************************************************************

While the project contains a lot of frameworks, the bulk of these are from the
AWS S3 and Parse SDKs (and frameworks that must be included for those to work).
OpenCV was also added for the motion detection features.

*** UIViewController Classes ***

Below are the UIViewControllers that support the various screens of the app. For
a complete look at the flow and where each occur, view the Main.Storyboard file.

- ADCameraStreamViewController - responsible for connecting to the camera,
getting the frames, and outputting the frames to the screen 
- ADMonitoringViewController - subclass of ADCameraStreamViewController. This
controller is the heart of the monitoring state and facilitates all of the frame
processing and event handling 
- ADSurveillanceTableViewController - a parent class that performs some layout 
functions that its subclasses can inherit and not worry about 
- ADConfigureMonitoringTableViewcontroller - this is behind the view that let’s 
the user specify the monitoring settings for the camera 
- ADEventsTableViewController - this controller shows the events a user’s 
devices have captured 
- ADDetailEventViewController - this controller shows the details for a specific 
event the user wants to see (such as it’s video) 
- ADDevicesTableViewController - this controller shows the user’s devices, both
active and inactive, and lets the user send disable commands to active devices 
- ADSettingsTableViewController - this controller shows the user basic
administration options, such as changing their password or logging out 
- ADImageViewController - this controller shows the image a user was sent via a
notification due a face detection

*** Helper Classes ***

We created several helper classes to help break out features and functionality
that could logically be made into their own objects. These include:

- ADVideoRecord - for recording video frame at a time 
- ADMotionDetector - for detecting motion and when it has ended 
- ADFaceDetector - for detecting faces 
- ADFileHelper - used to facilitate the local storage of recorded videos 
- ADS3Helper - used to handle most of the interactions with the AWS S3 bucket 
- ADDownloadTask - used to hold information such as current status, size, and
location of videos being downloaded locally to the device 
- ADNotificationHelper - used to send out the various types of notifications to 
other devices associated to the user

*** Model Classes ***
We represented the Parse objects through subclasses and categories on PFObject. 
This let us turn code such as:

 event[@”isStillRecording”] = @YES; 
           into 
 event.isStillRecording = YES;

The primary benefit of this is that Xcode offer autocomplete recommendations and
verify the correct syntax.

These subclasses and categories are as follows:

- ADEvent - a subclass representing the Event class of our Parse datastore 
- ADEventImage - a subclass representing the EventImage class datastore 
- PFInstallation+ADDevice.h - a category for the Installation class datastore

*** Open Source Classes ***

- UIActionSheet+Blocks - an action sheet with a block-based completion handler 
- UIAlertView+Blocks - an alert view with a block-based completion handler 
- UIImage+DataHandler - a category for deep copying a UIImage 
- ACPDownload - used to show the user the download progress of their video