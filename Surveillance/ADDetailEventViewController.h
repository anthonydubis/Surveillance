//
//  ADDetailEventViewController.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/16/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ADEvent;

@protocol EventAndVideoDeletionDeletionDelegate <NSObject>
@required
- (void)didDeleteLocalVideoForEvent:(ADEvent *)event;
- (void)didPermanentlyDeleteEvent:(ADEvent *)event;
@end

@interface ADDetailEventViewController : UIViewController

@property (nonatomic, weak) id<EventAndVideoDeletionDeletionDelegate> delegate;
@property (nonatomic, weak) IBOutlet UIView *videoPlayerView;
@property (nonatomic, strong) ADEvent *event;

@end
