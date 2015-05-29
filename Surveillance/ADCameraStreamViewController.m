//
//  CameraStreamViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/8/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADCameraStreamViewController.h"

@interface ADCameraStreamViewController ()

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

// Sets up the session, it's inputs/outputs, and the assetWriter for recording video
- (void)setupAVCapture
{
    NSError *error = nil;
    
    // Create the session (manages data flow from input to output
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    
    // Specify the video quality
    if (_videoQuality == ADVideoQualityStandard)
        [session setSessionPreset:AVCaptureSessionPresetMedium];
    else if (_videoQuality == ADVideoQualityLow)
        [session setSessionPreset:AVCaptureSessionPresetLow];
    else
        NSLog(@"Didn't specify a video quality");
    
    // Specify an input (one of the cameras)
    AVCaptureDevice *device;
    AVCaptureDevicePosition desiredPosition = AVCaptureDevicePositionFront;
    
    // Find the front facing camera
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == desiredPosition) {
            device = d;
            self.isUsingFrontFacingCamera = YES;
            break;
        }
    }
    
    // Fall back to the default camera.
    if (!device) {
        self.isUsingFrontFacingCamera = NO;
        device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    [device lockForConfiguration:nil];
    [device setActiveVideoMinFrameDuration:CMTimeMake(1, 30)];
    [device setActiveVideoMaxFrameDuration:CMTimeMake(1, 30)];
    [device unlockForConfiguration];
    
    // Create the input device
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    // Create the audio input device
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    
    if(!error) {
        // Add the input to the session
        if ([session canAddInput:deviceInput]) {
            [session addInput:deviceInput];
        }
        
        if ([session canAddInput:audioInput]) {
            [session addInput:audioInput];
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
        
        if ([session canAddOutput:self.videoDataOutput]) {
            [session addOutput:self.videoDataOutput];
        }
        
        // Get the output for doing face detection.
        [[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
        
        // Create audio output info
        _audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioDataOutput setSampleBufferDelegate:self queue:_videoDataOutputQueue];
        if ([session canAddOutput:_audioDataOutput]) {
            [session addOutput:_audioDataOutput];
        } else {
            NSLog(@"Unable to add audio output");
        }
        
        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
        self.previewLayer.backgroundColor = [[UIColor blackColor] CGColor];
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        
        CALayer *rootLayer = [self.previewView layer];
        [rootLayer setMasksToBounds:YES];
        [self.previewLayer setFrame:[rootLayer bounds]];
        [rootLayer addSublayer:self.previewLayer];
        
        _audioConnection = [_audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
        _videoConnection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        
        [session startRunning];
    }
    
    session = nil;
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

@end
