//
//  AFObservationViewController.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/2/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CameraStreamViewController.h"
#import "ADMotionDetector.h"

@interface MonitoringViewController : CameraStreamViewController

@property (nonatomic, assign) MotionDetectorSensitivity motionSensitivity;

@end
