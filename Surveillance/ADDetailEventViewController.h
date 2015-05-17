//
//  ADDetailEventViewController.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/16/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ADEvent;

@interface ADDetailEventViewController : UIViewController

@property (nonatomic, strong) ADEvent *event;
@property (weak, nonatomic) IBOutlet UIView *videoPlayerView;

@end
