//
//  ObservationViewController.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/1/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ObservationViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, assign) int motionSensitivity;

@end
