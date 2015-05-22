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
#import "UIImage+DataHandler.h"
#import "ADFileHelper.h"
#import "ADS3Helper.h"
#import "ADNotificationHelper.h"

// Parse Related
#import "ADEvent.h"
#import "ADEventImage.h"

// How often should we check to see if motion still exists, in seconds
const int MotionDetectionFrequencyWhenRecording = 1;

@interface MonitoringViewController ()
{
    BOOL isMonitoring;           // is the camera focused and monitoring the area
    BOOL isPreparingToRecord;    // is the assetWriter being prepared to record
    BOOL isRecording;            // is the assetWriter recording
    BOOL isLookingForFace;       // is the faceDetector currently processing a face
    int maxNumSimultaneousFaces; // the max number of faces found in a single frame so far
    BOOL endedMonitoring;        // Ensures that the endMonitoring method only gets called once
}

@property (nonatomic, strong) AVAudioPlayer *beep;
@property (nonatomic, strong) ADVideoRecorder *videoRecorder;
@property (nonatomic, strong) ADMotionDetector *motionDetector;
@property (nonatomic, strong) ADFaceDetector *faceDetector;
@property (nonatomic, strong) NSURL *recordingURL;

// Integrating parse
@property (nonatomic, strong) ADEvent *event;

@end

@implementation MonitoringViewController

#pragma mark - View lifecycle

// This is called when the view about to be presented (with the output of the camera) is loaded into memory
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    self.navigationItem.title = @"Setting Up";
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appHasEnteredBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// This is called when the view is on screen (or at least, about to be) and the views have been resized to fill the screen
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.videoRecorder = [[ADVideoRecorder alloc] initWithRecordingURL:self.recordingURL];
    [self performSelector:@selector(beginMonitoring) withObject:nil afterDelay:5.0];
}

- (void)appHasEnteredBackground
{
#warning You also need to handle case where app terminates while recording
    [self endMonitoring];
    [self dismissSelf:nil];
}

// Cal when the view leaves the screen
- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"View will disappear");
    [super viewWillDisappear:animated];
    [self endMonitoring];
}

- (void)endMonitoring
{
    if (!endedMonitoring) {
        // Notify the user that the camera was disabled
        if (_notifyWhenCameraDisabled) {
            [ADNotificationHelper sendCameraWasDisabledWhileRecordingNotification];
        }
        
        // If recording, finish up. Then rollback the context to remove uncommited events
        if (isRecording) {
            [self stopRecording];
        }
        
        // Set the installation status to no longer monitoring
        [ADNotificationHelper deviceStoppedMonitoring];
        
        // Ensure this only gets called once
        endedMonitoring = YES;
    }
}

// Sets the isMonitoring flag that causes work to be done when processing frames
- (void)beginMonitoring
{
    [self.beep play];
    isMonitoring = YES;
    self.navigationItem.title = @"Monitoring...";
    
    // Set the installation status to monitoring
    [ADNotificationHelper deviceBeganMonitoring];
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
    if ((isMonitoring || isRecording) && [self.motionDetector shouldSetBackground]) {
        [self.motionDetector setBackgroundWithPixelBuffer:pixelBuffer];
    }
    
    // Monitoring phase
    if (isMonitoring) {
        if (!isPreparingToRecord && [self.motionDetector didMotionOccurInPixelBufferRef:pixelBuffer]) {
            isPreparingToRecord = YES;
            [self startRecording];
            if (_notifyOnMotionStart) {
                [ADNotificationHelper sendMotionDetectedNotification];
            }
        }
    }
    
    // Recording phase
    if (isRecording) {
        // Check for motion if we haven't do so in the # of seconds specificed by MotionDetectionFrequencyWhenRecording
        if ([self.motionDetector intervalSinceLastMotionCheck] < -1 * MotionDetectionFrequencyWhenRecording) {
            [self.motionDetector didMotionOccurInPixelBufferRef:pixelBuffer];
            if ([self.motionDetector hasMotionEnded]) {
                [self stopRecordingAndPrepareForNewRecording];
                if (_notifyOnMotionEnd) {
                    [ADNotificationHelper sendMotionEndedNotification];
                }
                return;
            }
        }
        [self.videoRecorder appendFrameFromPixelBuffer:pixelBuffer];
        
        if (!isLookingForFace) {
            isLookingForFace = YES;
            CFRetain(sampleBuffer);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSDictionary *detectionResults = [self.faceDetector detectFacesFromSampleBuffer:sampleBuffer
                                                                                 andPixelBuffer:pixelBuffer
                                                                         usingFrontFacingCamera:self.isUsingFrontFacingCamera];
                CFRelease(sampleBuffer);
                [self handleDetectedFaces:detectionResults];
                isLookingForFace = NO;
            });
        }
    }
}

- (void)handleDetectedFaces:(NSDictionary *)detectionResults
{
    NSNumber *numFaces = (NSNumber *)detectionResults[ADFaceDetectorNumberOfFacesDetected];
    if (numFaces) {
        // Beep if the user asked you to do so
        if (_beepWhenFaceDetected) {
            [self.beep play];
        }
        
        // Sending a notification
        if (_notifyOnFaceDetection && numFaces.intValue > maxNumSimultaneousFaces) {
            // Get a copy of the image
            UIImage *image = [UIImage copyUIImage:(UIImage *)detectionResults[ADFaceDetectorImageWithFaces]];
            
            // Create the PFFile object to hold it
            NSData *jpeg = UIImageJPEGRepresentation(image, 1);
            PFFile *file = [PFFile fileWithName:@"eventImage.jpeg" data:jpeg];
            
            // Save everything in the background - only begin looking for new faces when this finishes
            [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    ADEventImage *eventImage = [ADEventImage objectForNewEventImageForEvent:self.event];
                    eventImage.image = file;
                    eventImage.numFaces = numFaces;
                    [eventImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (succeeded) {
                            NSLog(@"Saved a new event image");
                            [ADNotificationHelper sendFaceDetectedNotificationWithEventImage:eventImage];
                        }
                    }];
                }
            }];
            maxNumSimultaneousFaces = numFaces.intValue;
        }
    }
}

- (void)startRecording
{
    // Beep if the user specified that you should
    if (_beepWhenRecordingStarts) {
        [self.beep play];
    }
    
    // Create the parse object and save it
    self.event = [ADEvent objectForNewEvent];
    [self.event saveInBackground];
    
    [self.videoRecorder startRecording];
    isRecording = YES;
    isMonitoring = NO;
    isPreparingToRecord = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.title = @"Recording...";
    });
}

- (void)stopRecording
{
    // Beep if the user specified that you should
    if (_beepWhenRecordingStops) {
        [self.beep play];
    }
    
    isRecording = NO;
    [self.videoRecorder stopRecordingWithCompletionHandler:^{
        [self updateEventForEndOfRecording];
        [ADS3Helper uploadVideoAtURL:self.recordingURL forEvent:self.event];
    }];
}

- (void)stopRecordingAndPrepareForNewRecording
{
    // Beep if the user specified that you should
    if (_beepWhenRecordingStops) {
        [self.beep play];
    }
    
    isRecording = NO;
    // Upload video and prepare for new recording
    [self.videoRecorder stopRecordingWithCompletionHandler:^{
        [self updateEventForEndOfRecording];
        [ADS3Helper uploadVideoAtURL:self.recordingURL forEvent:self.event];
        [self prepareForNewRecording];
    }];
    
    // Update the ViewController's title
    dispatch_async(dispatch_get_main_queue(), ^{
        self.title = @"Stopping recording...";
    });
}

// Update the event with metadata and knowledge that the recording has ended
- (void)updateEventForEndOfRecording
{
    self.event.isStillRecording = NO;
    self.event.videoSize = [ADFileHelper sizeOfFileAtURL:self.recordingURL];
    NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:self.event.startedRecordingAt];
    self.event.videoDuration = [NSNumber numberWithInt:duration];
    [self.event saveInBackground];
}

- (void)prepareForNewRecording
{
    self.event = nil;
    self.recordingURL = nil;
    [self.motionDetector setBackgroundWithPixelBuffer:nil];
    [self.videoRecorder prepareToRecordWithNewURL:self.recordingURL];
    isMonitoring = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.title = @"Monitoring...";
    });
}

- (IBAction)dismissSelf:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Getters/Setters

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

- (NSURL *)recordingURL
{
    if (!_recordingURL) {
        NSString *toUploadDirectory = [ADFileHelper toUploadDirectoryPath];
        NSString *path = [toUploadDirectory stringByAppendingPathComponent:[[NSDate date] description]];
        _recordingURL = [NSURL fileURLWithPath:path];
    }
    return _recordingURL;
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
