//
//  ThumbnailViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/9/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ThumbnailViewController.h"
#import <ParseUI/ParseUI.h>
#import "ADEventImage.h"

@interface ThumbnailViewController ()

@end

@implementation ThumbnailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidLayoutSubviews {
    PFImageView *imageView = [[PFImageView alloc] initWithFrame:self.thumbnailImageView.frame];
    [self.view addSubview:imageView];
    [self.thumbnailImageView removeFromSuperview];
    self.thumbnailImageView = imageView;
    
    imageView.image = [UIImage imageNamed:@"empty.jpg"]; // placeholder image
    imageView.file = self.eventImage.image; // remote image
    
    [imageView loadInBackground];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)dismiss:(UIBarButtonItem *)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
