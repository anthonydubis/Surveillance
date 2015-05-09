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

@interface MonitoringViewController ()
{
    BOOL isMonitoring;          // is the camera focused and monitoring the area
    BOOL isPreparingToRecord;   // is the assetWriter being prepared to record
    BOOL isRecording;           // is the assetWriter recording
}

@property (nonatomic, strong) AVAudioPlayer *beep;
@property (nonatomic, strong) MonitoringEvent *event;
@property (nonatomic, strong) ADVideoRecorder *videoRecorder;
@property (nonatomic, strong) ADMotionDetector *motionDetector;
@property (nonatomic, strong) CIDetector *faceDetector;

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
    [self performSelector:@selector(beginMonitoring) withObject:nil afterDelay:3.0];
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
#warning You need to teardown the video recorder
    self.faceDetector = nil;
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
    NSLog(@"Working on frame");
    
    /*
    NSArray *detectedFaces = [self detectFacesFromSampleBuffer:sampleBuffer andPixelBufferRef:pixelBuffer];
    if (detectedFaces.count > 0) {
        [self.beep play];
        NSLog(@"Found faces.");
    }
     */
    
    if (isRecording) { // Handle recording
        if (self.videoRecorder.frameNumber > 100)
            [self stopRecording];
        else
            [self.videoRecorder appendFrameFromPixelBuffer:pixelBuffer];
    } else if (isMonitoring) { // Handle motion detection
        if (![self.motionDetector isBackgroundSet]) {
            [self.motionDetector setBackgroundWithPixelBuffer:pixelBuffer];
        } else {
            if ([self.motionDetector didMotionOccurInPixelBufferRef:pixelBuffer] && !isPreparingToRecord) {
                isPreparingToRecord = YES;
                [self startRecording];
            }
        }
    }
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

- (NSArray *)detectFacesFromSampleBuffer:(CMSampleBufferRef)sampleBuffer andPixelBufferRef:(CVPixelBufferRef)pixelBuffer
{
    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer
                                                      options:(__bridge NSDictionary *)attachments];
    if (attachments) {
        CFRelease(attachments);
    }
    
    // make sure your device orientation is not locked.
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    
    NSDictionary *imageOptions = nil;
    
    imageOptions = [NSDictionary dictionaryWithObject:[self exifOrientation:curDeviceOrientation]
                                               forKey:CIDetectorImageOrientation];
    
    NSArray *features = [self.faceDetector featuresInImage:ciImage
                                                   options:imageOptions];
    return features;
}

- (NSNumber *) exifOrientation: (UIDeviceOrientation) orientation
{
    int exifOrientation;
    /* kCGImagePropertyOrientation values
     The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
     by the TIFF and EXIF specifications -- see enumeration of integer constants.
     The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
     
     used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
     If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */
    
    enum {
        PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
        PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.
        PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
        PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
        PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
        PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
        PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
        PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
    };
    
    switch (orientation) {
        case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
            break;
        case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
            if (self.isUsingFrontFacingCamera)
                exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
            else
                exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
            break;
        case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
            if (self.isUsingFrontFacingCamera)
                exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
            else
                exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
            break;
        case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
        default:
            exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
            break;
    }
    return [NSNumber numberWithInt:exifOrientation];
}

- (NSArray *)listFileAtPath:(NSString *)path
{
    NSLog(@"LISTING ALL FILES FOUND");
    int count;
    
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    for (count = 0; count < (int)[directoryContent count]; count++)
    {
        NSLog(@"File %d: %@", (count + 1), [directoryContent objectAtIndex:count]);
    }
    return directoryContent;
}

#pragma mark - Getters/Setters

- (ADMotionDetector *)motionDetector
{
    if (!_motionDetector) {
        _motionDetector = [[ADMotionDetector alloc] init];
        _motionDetector.sensitivity = self.motionSensitivity;
    }
    return _motionDetector;
}

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

- (CIDetector *)faceDetector
{
    if (!_faceDetector) {
        NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyHigh, CIDetectorAccuracy, nil];
        _faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    }
    return _faceDetector;
}

@end
