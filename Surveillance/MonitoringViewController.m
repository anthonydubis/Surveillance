//
//  MonitoringViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/2/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "MonitoringViewController.h"
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ADFaceDetector.h"
#import "ADVideoRecorder.h"

// Core Data Related
#import "AppDelegate.h"
#import "MonitoringEvent+AD.h"

#import "ThumbnailViewController.h"

// How often should we check to see if motion still exists, in seconds
const int MotionDetectionFrequencyWhenRecording = 1;

@interface MonitoringViewController ()
{
    BOOL isMonitoring;          // is the camera focused and monitoring the area
    BOOL isPreparingToRecord;   // is the assetWriter being prepared to record
    BOOL isRecording;           // is the assetWriter recording
    BOOL faceWasFound;
}

@property (nonatomic, strong) AVAudioPlayer *beep;
@property (nonatomic, strong) MonitoringEvent *event;
@property (nonatomic, strong) ADVideoRecorder *videoRecorder;
@property (nonatomic, strong) ADMotionDetector *motionDetector;
@property (nonatomic, strong) ADFaceDetector *faceDetector;
@property (nonatomic, strong) AppDelegate *appDelegate;

@end

@implementation MonitoringViewController

#pragma mark - View lifecycle

// This is called when the view about to be presented (with the output of the camera) is loaded into memory
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

// This is called when the view is on screen (or at least, about to be) and the views have been resized to fill the screen
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.videoRecorder = [[ADVideoRecorder alloc] initWithRecordingURL:[self.event recordingURL]];
    [self performSelector:@selector(beginMonitoring) withObject:nil afterDelay:6.0];
}

// Cal when the view leaves the screen
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // If recording, finish up. Then rollback the context to remove uncommited events
    if (isRecording) {
        [self.appDelegate saveContext];
        [self.videoRecorder stopRecordingWithCompletionHandler:^{
            [self.appDelegate.managedObjectContext rollback];
        }];
    }
}

// Sets the isMonitoring flag that causes work to be done when processing frames
- (void)beginMonitoring
{
    isMonitoring = YES;
}

// This is when the view is unloaded - in this simple app, it's likely called when the app terminates
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
#warning You may need additional clearnup here
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // We support only Portrait.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// This method processes the frames and handles the recording process when motion is detected
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    // Get the image
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // Set the background if needed
    if (isMonitoring && [self.motionDetector shouldSetBackground]) {
        [self.motionDetector setBackgroundWithPixelBuffer:pixelBuffer];
    }
    
    if (isMonitoring) { // Monitoring the area
        if (!isPreparingToRecord && [self.motionDetector didMotionOccurInPixelBufferRef:pixelBuffer]) {
            isPreparingToRecord = YES;
            [self startRecording];
        }
    }
    
    if (isRecording) { // Handle recording
        // Check for motion if we haven't do so in the # of seconds specificed by MotionDetectionFrequencyWhenRecording
        if ([self.motionDetector intervalSinceLastMotionCheck] < -1 * MotionDetectionFrequencyWhenRecording) {
            [self.motionDetector didMotionOccurInPixelBufferRef:pixelBuffer];
            if ([self.motionDetector hasMotionEnded]) {
                [self stopRecording];
                return;
            }
        }
        [self.videoRecorder appendFrameFromPixelBuffer:pixelBuffer];
    }
    
    /*
    if (faceWasFound) return;
    
    NSArray *detectedFaces = [self.faceDetector detectFacesFromSampleBuffer:sampleBuffer
                                                             andPixelBuffer:pixelBuffer
                                                     usingFrontFacingCamera:self.isUsingFrontFacingCamera];
    
    if (detectedFaces.count > 0) {
        [self.beep play];
        faceWasFound = YES;
        for (UIImage *image in detectedFaces) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSegueWithIdentifier:@"ThumbnailSegue" sender:image];
            });
        }
    }
     */
}

- (void)startRecording
{
    NSLog(@"Starting the recording");
    [self.beep play];
    [self.videoRecorder startRecording];
    isRecording = YES;
    isMonitoring = NO;
    isPreparingToRecord = NO;
}

- (void)stopRecording
{
    NSLog(@"Stopping the recording");
    [self.beep play];
    isRecording = NO;
    [self.appDelegate saveContext];
    [self.videoRecorder stopRecordingWithCompletionHandler:^{
        [self prepareForNewRecording];
    }];
}

- (void)prepareForNewRecording
{
    self.event = nil;
    [self.motionDetector setBackgroundWithPixelBuffer:nil];
    [self.videoRecorder prepareToRecordWithNewURL:[self.event recordingURL]];
    isMonitoring = YES;
}

- (IBAction)dismissSelf:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqual:@"ThumbnailSegue"]) {
        ThumbnailViewController *tvc = segue.destinationViewController;
        tvc.thumbnailImage = (UIImage *)sender;
    }
}

#pragma mark - Getters/Setters

- (AppDelegate *)appDelegate
{
    return [[UIApplication sharedApplication] delegate];
}

- (MonitoringEvent *)event
{
    if (!_event) {
        NSDate *date = [NSDate date];
        NSString *filename = [NSString stringWithFormat:@"%@.mp4", [NSDateFormatter localizedStringFromDate:date
                                                                                                  dateStyle:NSDateFormatterMediumStyle
                                                                                                  timeStyle:NSDateFormatterMediumStyle]];
        _event = [MonitoringEvent newEventWithDate:date andFilename:filename inContext:self.appDelegate.managedObjectContext];
    }
    return _event;
}

- (AVAudioPlayer *)beep
{
    if (!_beep) {
        // Setup beep sound
        NSString *path = [[NSBundle mainBundle] pathForResource:@"beep-07" ofType:@"wav"];
        NSURL *url = [NSURL fileURLWithPath:path];
        _beep = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    }
    return _beep;
}

- (ADMotionDetector *)motionDetector
{
    if (!_motionDetector) {
        _motionDetector = [[ADMotionDetector alloc] init];
        _motionDetector.sensitivity = self.motionSensitivity;
    }
    return _motionDetector;
}

- (ADFaceDetector *)faceDetector
{
    if (!_faceDetector) {
        _faceDetector = [[ADFaceDetector alloc] init];
    }
    return _faceDetector;
}

@end
