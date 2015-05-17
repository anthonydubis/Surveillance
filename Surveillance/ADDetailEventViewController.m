//
//  ADDetailEventViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/16/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADDetailEventViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ADEvent.h"
#import "BButton.h"
#import "ADFileHelper.h"
#import "ADS3Helper.h"
#import "UIAlertView+Blocks.h"

@interface ADDetailEventViewController ()

@property (nonatomic, strong) MPMoviePlayerController *moviePlayerController;
@property (nonatomic, strong) BButton *removeFromDeviceButton;
@property (nonatomic, strong) BButton *permanentlyDeleteButton;

@end

@implementation ADDetailEventViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    // Setup video
    [self.view addSubview:self.moviePlayerController.view];
    // Add Buttons
    [self setupButtons];
}

#define BUTTON_W (320 - 16 * 2)
#define BUTTON_H 50
#define MARGIN 15.0

- (void)setupButtons
{
    CGRect playerFrame = self.videoPlayerView.frame;
    
    // Create "Remove from Device" button
    CGRect r1 = CGRectMake((self.view.frame.size.width - BUTTON_W) / 2, playerFrame.origin.y + playerFrame.size.height + MARGIN,
                           BUTTON_W, BUTTON_H);
    self.removeFromDeviceButton = [[BButton alloc] initWithFrame:r1 type:BButtonTypePrimary style:BButtonStyleBootstrapV3];
    [self.removeFromDeviceButton setTitle:@"Remove from Device" forState:UIControlStateNormal];
    [self.removeFromDeviceButton addTarget:self action:@selector(removeVideoFromDevice) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.removeFromDeviceButton];
    
    // Create
    CGRect r2 = CGRectMake(r1.origin.x, r1.origin.y + r1.size.height + MARGIN, BUTTON_W, BUTTON_H);
    self.permanentlyDeleteButton = [[BButton alloc] initWithFrame:r2 type:BButtonTypeDanger style:BButtonStyleBootstrapV3];
    [self.permanentlyDeleteButton setTitle:@"Permanently Delete" forState:UIControlStateNormal];
    [self.permanentlyDeleteButton addTarget:self action:@selector(permanentlyDeleteVideo) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.permanentlyDeleteButton];
}

#warning Show progress view so the user knows you're doing something

// Remove the video from the local device only
- (void)removeVideoFromDevice
{
#warning How long does this take? Try it against a long video
#warning What happens if you are in the middle of playing it? Try against large video that you can't load all at once
    // Specify the block handler
    void(^handler)(UIAlertView *alertView, NSInteger buttonIndex) = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex != [alertView cancelButtonIndex]) {
            if ([ADFileHelper removeLocalCopyOfVideoForEvent:self.event]) {
                [self.delegate didDeleteLocalVideoForEvent:self.event];
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:nil message:@"Sorry, something went wrong - could you try that again?"
                                                            delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [av show];
            }
        }
    };
    
    [UIAlertView showWithTitle:@"Remove Video from Device"
                       message:@"Would you like to remove this video from the device? You can always download it again later."
             cancelButtonTitle:@"No" otherButtonTitles:@[@"Yes"]
                      tapBlock:handler];
}

#warning What happens if you lose internet?

// Remove the video from the local device and the cloud storage
- (void)permanentlyDeleteVideo
{
    // Specify the block handler
    void(^handler)(UIAlertView *alertView, NSInteger buttonIndex) = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex != [alertView cancelButtonIndex]) {
#warning Show that you're doing work
            [ADS3Helper deleteVideoForEvent:self.event withCompletionBlock:^{
                [self removeLocalCopyAndDeleteParseObject];
            }];
        }
    };
    
    [UIAlertView showWithTitle:@"Permanently Delete"
                       message:@"Would you like to permanently delete this video? You will not be able to download it again later."
             cancelButtonTitle:@"No" otherButtonTitles:@[@"Yes"]
                      tapBlock:handler];
}

- (void)removeLocalCopyAndDeleteParseObject
{
    NSLog(@"Removing local copies");
    [ADFileHelper removeLocalCopyOfVideoForEvent:self.event];
#warning Do I need to block for this deletion to ensure that ADEventsTVC's query does not fetch it before it's removed from the parse server?
    [self.event deleteInBackground];
    [self.delegate didPermanentlyDeleteEvent:self.event];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Setters/Getters

- (MPMoviePlayerController *)moviePlayerController
{
    if (!_moviePlayerController) {
        NSURL *url = [NSURL fileURLWithPath:[[ADFileHelper downloadsDirectoryPath]
                                             stringByAppendingPathComponent:self.event.videoName]];
        _moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:url];
        [_moviePlayerController prepareToPlay];
        [_moviePlayerController.view setFrame:self.videoPlayerView.frame];
    }
    return _moviePlayerController;
}

@end
