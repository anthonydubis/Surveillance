//
//  MonitoringViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/2/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADMonitoringViewController.h"
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "ADFaceDetector.h"
#import "ADGateKeeper.h"
#import "ADVideoRecorder.h"
#import "ADFileHelper.h"
#import "ADS3Helper.h"
#import "ADNotificationHelper.h"
#import "ADStartView.h"

#import "UIImage+DataHandler.h"

// Parse Related
#import "ADEvent.h"
#import "ADEventImage.h"
#import "PFInstallation+ADDevice.h"

// How often should we check to see if motion still exists, in seconds
const int MotionDetectionFrequencyWhenRecording = 1;

// Countdown to begin monitoring once "start" is tapped
const int kCountdownTime = 10;

@interface ADMonitoringViewController ()
{
  BOOL isMonitoring;           // is the camera focused and monitoring the area
  BOOL isPreparingToRecord;    // is the assetWriter being prepared to record
  BOOL isRecording;            // is the assetWriter recording
  BOOL isLookingForFace;       // is the faceDetector currently processing a face
  int maxNumSimultaneousFaces; // the max number of faces found in a single frame so far
  BOOL endedMonitoring;        // Ensures that the endMonitoring method only gets called once
  CMTime lastSampleTime;       // The CMTime of the last sample buffer received
  int countdown;               // The countdown clock to begin monitoring
  NSTimer *countdownTimer;     // The current countdownTimer
  double captureInterval;      // The interval frames should be captured at: 1 implies every frame, 2 implies every other frame, etc.
  int frameInInterval;         // The frame number in the current interval
  ADStartView *_startView;     // The prompt that appears on the screen so the user can decide to begin monitoring
}

@property (nonatomic, assign) UIDeviceOrientation currentOrientation;
@property (nonatomic, strong) AVAudioPlayer *beep;
@property (nonatomic, strong) ADVideoRecorder *videoRecorder;
@property (nonatomic, strong) ADMotionDetector *motionDetector;
@property (nonatomic, strong) ADFaceDetector *faceDetector;
@property (nonatomic, strong) NSURL *recordingURL;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *finishedBarButtonItem;

// Integrating parse
@property (nonatomic, strong) ADEvent *event;

@end

@implementation ADMonitoringViewController

#pragma mark - View lifecycle

// This is called when the view about to be presented (with the output of the camera) is loaded into memory
- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.navigationItem.rightBarButtonItem = nil;
  _startView = [[ADStartView alloc] initWithFrame:CGRectMake(
                                                             (self.view.frame.size.width - kStartViewWidth) / 2,
                                                             (self.view.frame.size.height - kStartViewHeight) / 2,
                                                             kStartViewWidth,
                                                             kStartViewHeight
                                                             )];
  [self _configureStartViewForState:ADStartViewStateReady];
  [_startView.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
  [_startView.startButton addTarget:self action:@selector(startMonitoringTapped:) forControlEvents:UIControlEventTouchUpInside];
  [_startView.cancelButton addTarget:self action:@selector(dismissSelf:) forControlEvents:UIControlEventTouchUpInside];
  [self.navigationController.view addSubview:_startView];
  
  // Start us in the Portrait orientation in case the current orientation is face up or face down
  self.currentOrientation = UIDeviceOrientationPortrait;
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  self.currentOrientation = [[UIDevice currentDevice] orientation];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(deviceOrientationDidChange)
                                               name:UIDeviceOrientationDidChangeNotification
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appHasEnteredBackground)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(dismissSelf:)
                                               name:@"DisableCameraNotification"
                                             object:nil];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)appHasEnteredBackground
{
#warning You also need to handle case where app terminates while recording
  [self endMonitoring];
  [self dismissSelf:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  [self endMonitoring];
  [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)deviceOrientationDidChange
{
  UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
  switch (currentOrientation) {
    case UIDeviceOrientationPortrait:
    case UIDeviceOrientationLandscapeLeft:
    case UIDeviceOrientationLandscapeRight:
    case UIDeviceOrientationPortraitUpsideDown:
      self.currentOrientation = currentOrientation;
      break;
    case UIDeviceOrientationFaceUp:
    case UIDeviceOrientationFaceDown:
      if (self.currentOrientation == UIDeviceOrientationPortraitUpsideDown) {
        self.currentOrientation = UIDeviceOrientationPortrait;
      }
      break;
    default:
      break;
  }
}

- (void)setCurrentOrientation:(UIDeviceOrientation)currentOrientation
{
  if (_currentOrientation != currentOrientation) {
    _currentOrientation = currentOrientation;
    if (!isRecording) {
      self.videoRecorder.orientation = _currentOrientation;
    }
  }
}

- (void)endMonitoring
{
  if (!endedMonitoring) {
    // Ensure this only gets called once
    endedMonitoring = YES;
    
    // Notify the user that the camera was disabled
    if (_notifyWhenCameraDisabled) {
      [ADNotificationHelper sendCameraWasDisabledWhileRecordingNotification];
    }
    
    // Handle scenarios where you are preparing to record or recording
    // Should handle false positives here
    if (isRecording) {
      // Finish up
      NSLog(@"Was recording when dismissed - end recording");
      [self stopRecording];
    }
    
    // Set the installation status to no longer monitoring
    [PFInstallation deviceStoppedMonitoring];
  }
}

// Sets the isMonitoring flag that causes work to be done when processing frames
- (void)beginMonitoring
{
  self.navigationItem.rightBarButtonItem = self.finishedBarButtonItem;
  if (!endedMonitoring) {
#warning Commented out beep for testing purposes
    // [self.beep play];
    isMonitoring = YES;
    self.navigationItem.title = @"Monitoring...";
    
    // Set the installation status to monitoring
    [PFInstallation deviceBeganMonitoring];
  }
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
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// This method processes the frames and handles the recording process when motion is detected
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
  // Get the image
  lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
  if (connection == self.videoConnection) {
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
      
      // Append the frame depending on the frame rate
      if (captureInterval - frameInInterval < 1.0) {
        [self.videoRecorder appendFrameFromPixelBuffer:pixelBuffer withPresentationTime:lastSampleTime];
        frameInInterval = 1;
      } else {
        frameInInterval++;
      }
      
      NSLog(@"Before face detection loop");
      // Do face detection
      if (FaceDetectionEnabled() && !isLookingForFace) {
        NSLog(@"YOU SHOULDNT BE HERE!");
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
  } else {
    [self.videoRecorder appendAudioSampleBuffer:sampleBuffer];
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
  
  [self.videoRecorder startRecordingWithSourceTime:lastSampleTime];
  isRecording = YES;
  isMonitoring = NO;
  isPreparingToRecord = NO;
  dispatch_async(dispatch_get_main_queue(), ^{
    self.title = @"Motion Detected - Recording...";
    self.navigationController.navigationBar.titleTextAttributes = @{
                                                                    NSForegroundColorAttributeName : [UIColor redColor]
                                                                    };
  });
}

- (void)stopRecording
{
  // Beep if the user specified that you should
  if (_beepWhenRecordingStops) {
    [self.beep play];
  }
  
  // Handle false positives
  //    if (![[NSFileManager defaultManager] fileExistsAtPath:self.recordingURL.path isDirectory:nil]) {
  //        NSLog(@"False positive");
  //    }
  
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
  self.event.status = EventStatusUploading;
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
  self.videoRecorder.orientation = self.currentOrientation;
  self.videoRecorder.isUsingFrontCamera = self.isUsingFrontFacingCamera;
  maxNumSimultaneousFaces = 0;
  isMonitoring = YES;
  dispatch_async(dispatch_get_main_queue(), ^{
    self.title = @"Monitoring...";
    self.navigationController.navigationBar.titleTextAttributes = @{
                                                                    NSForegroundColorAttributeName : [UIColor whiteColor]
                                                                    };

  });
}

- (IBAction)dismissSelf:(id)sender
{
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)dimScreen:(UIBarButtonItem *)sender
{
  if ([sender.title isEqualToString:@"Dim Screen"]) {
    sender.title = @"Brighten Screen";
    [[UIScreen mainScreen] setBrightness:0.0];
  } else {
    sender.title = @"Dim Screen";
    [[UIScreen mainScreen] setBrightness:0.7];
  }
}

- (void)startMonitoringTapped:(UIButton *)sender
{
  if (!countdownTimer) {
    // Setup the recorder and begin the countdown
    self.videoRecorder = [[ADVideoRecorder alloc] initWithRecordingURL:self.recordingURL];
    self.videoRecorder.orientation = self.currentOrientation;
    self.videoRecorder.isUsingFrontCamera = self.isUsingFrontFacingCamera;
    countdown = kCountdownTime;
    [self _configureStartViewForState:ADStartViewStateCountdown];
    [self updateCountdownTitle];
    countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(countdownToMonitoring)
                                                    userInfo:nil
                                                     repeats:YES];
  } else if (countdownTimer.valid) {
    // In the middle of the countdown sequence - reset the startView for a new countdown
    [countdownTimer invalidate];
    countdownTimer = nil;
    [self _configureStartViewForState:ADStartViewStateReady];
    self.title = @"Ready to Monitor";
    [sender setTitle:@"Start" forState:UIControlStateNormal];
    
  } else {
    NSAssert(false, @"We should never reach this point");
    [self dismissSelf:nil];
  }
}

- (void)_configureStartViewForState:(ADStartViewState)state
{
  _startView.state = state;
  if (state == ADStartViewStateReady) {
    _startView.titleLabel.text = @"Position and orient the device so its camera captures the desired area and tap \"Start\"";
    [_startView.startButton setTitle:@"Start" forState:UIControlStateNormal];
  } else if (state == ADStartViewStateCountdown) {
    [self updateCountdownTitle];
    [_startView.startButton setTitle:@"Stop" forState:UIControlStateNormal];
  }
}

- (void)countdownToMonitoring
{
  if (--countdown > 0) {
    [self updateCountdownTitle];
  } else {
    [countdownTimer invalidate];
    countdownTimer = nil;
    [_startView removeFromSuperview];
    self.title = @"Monitoring ...";
    [self beginMonitoring];
  }
}

- (void)updateCountdownTitle
{
  _startView.titleLabel.text = [NSString stringWithFormat:@"Monitoring in %i...", countdown];
}

- (IBAction)switchCameraTapped:(id)sender
{
  [super switchCameraTapped:sender];
  self.videoRecorder.isUsingFrontCamera = self.isUsingFrontFacingCamera;
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

- (void)setFrameRate:(NSInteger)frameRate
{
  _frameRate = frameRate;
  captureInterval = (double)VIDEO_FRAME_RATE / (double)_frameRate;
  frameInInterval = captureInterval + 1; // +1 to make sure the first frame gets captured
}

@end
