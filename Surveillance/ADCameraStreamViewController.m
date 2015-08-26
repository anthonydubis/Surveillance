//
//  CameraStreamViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/8/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADCameraStreamViewController.h"

@interface ADCameraStreamViewController ()
{
  AVCaptureSession *_captureSession;
  AVCaptureDeviceInput *_videoDeviceInput;
}
@end

@implementation ADCameraStreamViewController

+ (NSString *)nameForVideoQuality:(ADVideoQuality)videoQuality {
  switch (videoQuality) {
    case ADVideoQualityLow:      return @"Low";
    case ADVideoQualityStandard: return @"Standard";
  }
}

+ (NSString *)descriptionForVideoQuality:(ADVideoQuality)videoQuality {
  switch (videoQuality) {
    case ADVideoQualityLow:      return @"Best for cellular connections";
    case ADVideoQualityStandard: return @"Best for Wifi connections";
  }
}

// This is called when the view is on screen (or at least, about to be) and the views have been resized to fill the screen
- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];
#warning Try doing this on a background queue
  self.navigationItem.title = @"Setting Up";
  [self setupAVCapture];
  self.navigationItem.title = @"Ready to Monitor";
  
  UIImage *background44 = [self imageWithColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
  [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
  [self.navigationController.navigationBar setBackgroundImage:background44 forBarMetrics:UIBarMetricsDefault];
  [self.navigationController.toolbar setBackgroundImage:background44 forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
}

- (UIImage *)imageWithColor:(UIColor *)color
{
  CGRect rect = CGRectMake(0, 0, 1, 1);
  
  // create a 1 by 1 pixel context
  UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
  [color setFill];
  UIRectFill(rect);
  
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return image;
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
  [self teardownAVCapture];
}

// Clean up capture setup
- (void)teardownAVCapture
{
  self.videoDataOutput = nil;
  self.videoDataOutputQueue = nil;
  [self.previewLayer removeFromSuperlayer];
  self.previewLayer = nil;
}

- (void)configureCameraForMonitoring:(AVCaptureDevice *)camera
{
  NSError *error = nil;
  
  if ([camera lockForConfiguration:&error]) {
    [camera setActiveVideoMinFrameDuration:CMTimeMake(1, VIDEO_FRAME_RATE)];
    [camera setActiveVideoMaxFrameDuration:CMTimeMake(1, VIDEO_FRAME_RATE)];
    [camera unlockForConfiguration];
  }
  NSAssert(error == nil, @"Failed to configure the device");
}

// Sets up the session, it's inputs/outputs, and the assetWriter for recording video
- (void)setupAVCapture
{
  NSError *error = nil;
  
  // Create the session (manages data flow from input to output
  _captureSession = [[AVCaptureSession alloc] init];
  
  // Specify the video quality
  if (_videoQuality == ADVideoQualityStandard)
    [_captureSession setSessionPreset:AVCaptureSessionPresetMedium];
  else if (_videoQuality == ADVideoQualityLow)
    [_captureSession setSessionPreset:AVCaptureSessionPresetLow];
  else
    NSLog(@"Didn't specify a video quality");
  
  // Specify the video input (one of the cameras)
  AVCaptureDevice *device = [self cameraWithPosition:AVCaptureDevicePositionFront];
  if (device) {
    self.isUsingFrontFacingCamera = YES;
  } else {
    device = [self cameraWithPosition:AVCaptureDevicePositionBack];
    self.isUsingFrontFacingCamera = NO;
  }
  NSAssert(device, @"Could not locate a camera for use");
  
  // Configure the device
  [self configureCameraForMonitoring:(AVCaptureDevice *)device];
  
  // Create the input device
  _videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
  
  // Create the audio input device
  AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
  AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
  
  if(!error) {
    // Add the input to the session
    if ([_captureSession canAddInput:_videoDeviceInput]) {
      [_captureSession addInput:_videoDeviceInput];
    }
    
    if ([_captureSession canAddInput:audioInput]) {
      [_captureSession addInput:audioInput];
    } else {
      NSLog(@"Unable to add audio input to session");
    }
    
    // Make a video data output
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    // BGRA work well with CoreGraphics and OpenGL
    NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                       [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [self.videoDataOutput setVideoSettings:rgbOutputSettings];
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked
    
    // create a serial dispatch queue used for the sample buffer delegate
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
    // see the header doc for setSampleBufferDelegate:queue: for more information
    self.videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
    
    if ([_captureSession canAddOutput:self.videoDataOutput]) {
      [_captureSession addOutput:self.videoDataOutput];
    }
    
    // Get the output for doing face detection.
    [[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
    
    // Create audio output info
    _audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    [_audioDataOutput setSampleBufferDelegate:self queue:_videoDataOutputQueue];
    if ([_captureSession canAddOutput:_audioDataOutput]) {
      [_captureSession addOutput:_audioDataOutput];
    } else {
      NSLog(@"Unable to add audio output");
    }
    
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    self.previewLayer.backgroundColor = [[UIColor blackColor] CGColor];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    CALayer *rootLayer = [self.previewView layer];
    [rootLayer setMasksToBounds:YES];
    [self.previewLayer setFrame:[rootLayer bounds]];
    [rootLayer addSublayer:self.previewLayer];
    
    _audioConnection = [_audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
    _videoConnection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    
    [_captureSession startRunning];
  }
  
  if (error) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:
                              [NSString stringWithFormat:@"Failed with error %d", (int)[error code]]
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
    [alertView show];
    [self teardownAVCapture];
  }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
  // Access the frames being captured by the camera
  // Override in subclasses to process the frames
}

#pragma mark - Switch Cameras

- (IBAction)switchCameraTapped:(id)sender
{
  //Change camera source
  if (_captureSession) {
    //Indicate that some changes will be made to the session
    [_captureSession beginConfiguration];
    
    //Get new input
    AVCaptureDevice *newCamera;
    if(_videoDeviceInput.device.position == AVCaptureDevicePositionBack) {
      newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
    } else {
      newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
    }
    [self configureCameraForMonitoring:newCamera];
    
    //Add input to session
    NSError *err = nil;
    AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:&err];
    if(!newVideoInput || err) {
      UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Couldn't Switch Cameras"
                                                   message:@"There was an issue switching to your other camera. Please try again later."
                                                  delegate:nil
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
      [av show];
    } else {
      [_captureSession removeInput:_videoDeviceInput];
      [_captureSession removeOutput:self.videoDataOutput];
      _videoDeviceInput = newVideoInput;
      [_captureSession addInput:newVideoInput];
      [_captureSession addOutput:self.videoDataOutput];
      _videoConnection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    }
    
    //Commit all the configuration changes at once
    [_captureSession commitConfiguration];
  }
}

// Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
  NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
  for (AVCaptureDevice *device in devices) {
    if ([device position] == position) {
      return device;
    }
  }
  return nil;
}

@end
