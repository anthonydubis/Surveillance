//
//  ThumbnailViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/9/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADImageViewController.h"
#import <ParseUI/ParseUI.h>
#import "ADEventImage.h"

@interface ADImageViewController ()

@end

@implementation ADImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = [NSDateFormatter localizedStringFromDate:self.eventImage.createdAt
                                                dateStyle:NSDateFormatterMediumStyle
                                                timeStyle:NSDateFormatterLongStyle];
}

- (void)viewDidLayoutSubviews {
    [self.eventImage.image getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            UIImage *image = [UIImage imageWithData:data];
            [self.activityIndicatorView stopAnimating];
            self.capturedImageView.image = image;
            self.view.backgroundColor = [UIColor whiteColor];
            self.eventImage.hasBeenViewed = YES;
            [self.eventImage saveEventually];
        } else {
            [UIAlertView showWithTitle:@"Sorry" message:@"Sorry, there was an error when trying to load the image."
                     cancelButtonTitle:@"OK" otherButtonTitles:nil tapBlock:^(UIAlertView *av, NSInteger buttonIndex) {
                         [self dismiss:nil];
                     }];
        }
    }];
}

- (IBAction)dismiss:(UIBarButtonItem *)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
