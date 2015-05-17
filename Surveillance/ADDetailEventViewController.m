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
    // [armButton addTarget:self action:@selector(armDrone:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.removeFromDeviceButton];
    
    // Create
    CGRect r2 = CGRectMake(r1.origin.x, r1.origin.y + r1.size.height + MARGIN, BUTTON_W, BUTTON_H);
    self.permanentlyDeleteButton = [[BButton alloc] initWithFrame:r2 type:BButtonTypeDanger style:BButtonStyleBootstrapV3];
    [self.permanentlyDeleteButton setTitle:@"Permanently Delete" forState:UIControlStateNormal];
    [self.view addSubview:self.permanentlyDeleteButton];
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
