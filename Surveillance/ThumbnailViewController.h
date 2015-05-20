//
//  ThumbnailViewController.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/9/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ADEventImage;

@interface ThumbnailViewController : UIViewController

@property (nonatomic, strong) ADEventImage *eventImage;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;

- (IBAction)dismiss:(UIBarButtonItem *)sender;

@end
