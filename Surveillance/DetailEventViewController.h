//
//  DetailEventViewController.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/11/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MonitoringEvent;

@interface DetailEventViewController : UIViewController

@property (strong, nonatomic) MonitoringEvent *event;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *viewVideoButton;

- (IBAction)viewVideoButtonPressed:(UIButton *)sender;

@end
