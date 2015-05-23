//
//  MonitoringViewController.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/2/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ADCameraStreamViewController.h"
#import "ADMotionDetector.h"

@interface ADMonitoringViewController : ADCameraStreamViewController

@property (nonatomic, assign) MotionDetectorSensitivity motionSensitivity;

@property (nonatomic, assign) BOOL beepWhenRecordingStarts;
@property (nonatomic, assign) BOOL beepWhenRecordingStops;
@property (nonatomic, assign) BOOL beepWhenFaceDetected;
@property (nonatomic, assign) BOOL notifyOnMotionStart;
@property (nonatomic, assign) BOOL notifyOnMotionEnd;
@property (nonatomic, assign) BOOL notifyOnFaceDetection;
@property (nonatomic, assign) BOOL notifyWhenCameraDisabled;

@end
