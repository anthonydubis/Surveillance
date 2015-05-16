//
//  DetailEventViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/11/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "DetailEventViewController.h"
#import "MonitoringEvent+AD.h"
#import "MonitoringEventFace+AD.h"
#import <MediaPlayer/MediaPlayer.h>

@interface DetailEventViewController ()

@property (nonatomic, strong) MPMoviePlayerController *moviePlayerController;

@end

@implementation DetailEventViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    MonitoringEventFace *faces = [self.event.faces anyObject];
    UIImage *image = [UIImage imageWithData:faces.imageData];
    if (image)
        self.imageView.image = image;
    
    
    // Movie Player Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(movieEventFullscreenHandler:)
                                                 name:MPMoviePlayerDidExitFullscreenNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(movieEventFullscreenHandler:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    if (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        [self.moviePlayerController.view setFrame:CGRectMake(0, 70, 320, 270)];
    } else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        [self.moviePlayerController.view setFrame:CGRectMake(0, 0, 480, 320)];
    }
    return YES;
}

- (void)movieEventFullscreenHandler:(NSNotification *)notif
{
    [self.moviePlayerController.view removeFromSuperview];
}

- (IBAction)viewVideoButtonPressed:(UIButton *)sender {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:[NSString pathWithComponents:@[documentsPath, self.event.filename]]];
    [self showVideoAtURL:fileURL];
}

- (void)showVideoAtURL:(NSURL *)fileURL
{
    self.moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:fileURL];
    [self.moviePlayerController.view setFrame:CGRectMake(0, 70, 320, 270)];
    [self.view addSubview:self.moviePlayerController.view];
    self.moviePlayerController.fullscreen = YES;
    [self.moviePlayerController play];
}

@end
