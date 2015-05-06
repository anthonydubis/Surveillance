//
//  AFObservationViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/2/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "AVObservationViewController.h"
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <opencv2/highgui/cap_ios.h>
#import <opencv2/highgui/ios.h>


static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

@interface AVObservationViewController ()
{
    BOOL isMonitoring;          // is the camera focused and monitoring the area
    BOOL isPreparingToRecord;   // is the assetWriter being prepared to record
    BOOL isRecording;           // is the assetWriter recording
    int frameNumber;            // the frame number we are on in the recorded video
}

@property (nonatomic) BOOL isUsingFrontFacingCamera;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic) dispatch_queue_t videoDataOutputQueue;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) UIImage *borderImage;
@property (nonatomic, strong) CIDetector *faceDetector;
@property (nonatomic, assign) cv::Mat background;
@property (nonatomic, strong) NSURL *recordingURL;
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;

@end

@implementation AVObservationViewController

#pragma mark - View lifecycle

// This is called when the view about to be presented (with the output of the camera) is loaded into memory
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    self.borderImage = [UIImage imageNamed:@"border"];
    NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
    self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    frameNumber = 0;
    
    [self listFileAtPath:[self documentsPath]];
}

// This is called when the view is on screen (or at least, about to be) and the views have been resized to fill the screen
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self setupAVCapture];
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
    [self teardownAVCapture];
    self.faceDetector = nil;
    self.borderImage = nil;
}

// Clean up capture setup
- (void)teardownAVCapture
{
    self.videoDataOutput = nil;
    self.videoDataOutputQueue = nil;
    [self.previewLayer removeFromSuperlayer];
    self.previewLayer = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // We support only Portrait.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// Sets up the session, it's inputs/outputs, and the assetWriter for recording video
- (void)setupAVCapture
{
    NSError *error = nil;
    
    // Create the session (manages data flow from input to output
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        [session setSessionPreset:AVCaptureSessionPreset640x480];
    } else {
        // Was using AVCaptureSessionPresetPhoto
        [session setSessionPreset:AVCaptureSessionPresetPhoto];
    }
    
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
    
    if(!error) {
        // Add the input to the session
        if ([session canAddInput:deviceInput]) {
            [session addInput:deviceInput];
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
        
        // get the output for doing face detection.
        [[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
        
        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
        self.previewLayer.backgroundColor = [[UIColor blackColor] CGColor];
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        
        CALayer *rootLayer = [self.previewView layer];
        [rootLayer setMasksToBounds:YES];
        [self.previewLayer setFrame:[rootLayer bounds]];
        [rootLayer addSublayer:self.previewLayer];
        [session startRunning];
        
        // Setup the AssetWriter
        NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:640], AVVideoWidthKey,
                                        [NSNumber numberWithInt:480], AVVideoHeightKey,
                                        AVVideoCodecH264, AVVideoCodecKey, nil];
        
        self.assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                   outputSettings:outputSettings];
        
        /* I'm going to push pixel buffers to it, so will need a
         AVAssetWriterPixelBufferAdaptor, to expect the same 32BGRA input as I've
         asked the AVCaptureVideDataOutput to supply */
         self.pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc]
                                    initWithAssetWriterInput:self.assetWriterInput
                                    sourcePixelBufferAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                 [NSNumber numberWithInt:kCVPixelFormatType_32BGRA],kCVPixelBufferPixelFormatTypeKey, nil]];
        
        self.assetWriter = [[AVAssetWriter alloc] initWithURL:self.recordingURL
                                                     fileType:AVFileTypeMPEG4
                                                        error:&error];
        [self.assetWriter addInput:self.assetWriterInput];
        
        /* we need to warn the input to expect real time data incoming, so that it tries
         to avoid being unavailable at inopportune moments */
        self.assetWriterInput.expectsMediaDataInRealTime = YES;
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

// This method processes the frames and hanldes the recording process when motion is detected
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    // get the image
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    if (isRecording && self.assetWriterInput.isReadyForMoreMediaData) {
        if (frameNumber > 100)
            [self stopRecording];
        else
            [self.pixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:CMTimeMake(frameNumber++, 30)];
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    if (isMonitoring) {
        cv::Mat image = cv::Mat(bufferHeight, bufferWidth, CV_8UC4, pixel); //put buffer in open cv, no memory copied
        
        //Processing here
        cv::Mat gray;
        cv::cvtColor(image, gray, CV_RGB2GRAY);
        if (self.background.empty()) {
            self.background = gray.clone();
        } else {
            cv::Mat diff;
            cv::absdiff(gray, self.background, diff);
            cv::threshold(diff, diff, 50, 255, cv::THRESH_TOZERO);
            // cv::threshold(diff[0], diff[0], 30, 255, cv::THRESH_TOZERO);
            unsigned long diffVal = sum(diff)[0];
            NSLog(@"%lu", diffVal);
            if (diffVal > self.motionSensitivity && !isPreparingToRecord) {
                isPreparingToRecord = YES;
                [self startRecording];
            }
        }
    }
    
    //End processing
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

- (void)startRecording
{
    NSLog(@"Starting the recording");
    [self.assetWriter startWriting];
    [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
    isRecording = YES;
}

- (void)stopRecording
{
    NSLog(@"Stopping the recording");
    isRecording = NO;
    [self.assetWriter finishWritingWithCompletionHandler:^{
        [self listFileAtPath:[self documentsPath]];
    }];
}

// utility routine to display error aleart if takePicture fails
- (void)displayErrorOnMainQueue:(NSError *)error withMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:[NSString stringWithFormat:@"%@ (%d)", message, (int)[error code]]
                                  message:[error localizedDescription]
                                  delegate:nil
                                  cancelButtonTitle:@"Dismiss"
                                  otherButtonTitles:nil];
        [alertView show];
    });
}

// find where the video box is positioned within the preview layer based on the video size and gravity
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity
                          frameSize:(CGSize)frameSize
                       apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
    
    CGRect videoBox;
    videoBox.size = size;
    if (size.width < frameSize.width)
        videoBox.origin.x = (frameSize.width - size.width) / 2;
    else
        videoBox.origin.x = (size.width - frameSize.width) / 2;
    
    if ( size.height < frameSize.height )
        videoBox.origin.y = (frameSize.height - size.height) / 2;
    else
        videoBox.origin.y = (size.height - frameSize.height) / 2;
    
    return videoBox;
}

// called asynchronously as the capture output is capturing sample buffers, this method asks the face detector
// to detect features and for each draw the green border in a layer and set appropriate orientation
- (void)drawFaces:(NSArray *)features
      forVideoBox:(CGRect)clearAperture
      orientation:(UIDeviceOrientation)orientation
{
    NSArray *sublayers = [NSArray arrayWithArray:[self.previewLayer sublayers]];
    NSInteger sublayersCount = [sublayers count], currentSublayer = 0;
    NSInteger featuresCount = [features count], currentFeature = 0;
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    // hide all the face layers
    for ( CALayer *layer in sublayers ) {
        if ( [[layer name] isEqualToString:@"FaceLayer"] )
            [layer setHidden:YES];
    }
    
    if ( featuresCount == 0 ) {
        [CATransaction commit];
        return; // early bail.
    }
    
    CGSize parentFrameSize = [self.previewView frame].size;
    NSString *gravity = [self.previewLayer videoGravity];
    BOOL isMirrored = [self.previewLayer isMirrored];
    CGRect previewBox = [AVObservationViewController videoPreviewBoxForGravity:gravity
                                                                     frameSize:parentFrameSize
                                                                  apertureSize:clearAperture.size];
    
    for ( CIFaceFeature *ff in features ) {
        // find the correct position for the square layer within the previewLayer
        // the feature box originates in the bottom left of the video frame.
        // (Bottom right if mirroring is turned on)
        CGRect faceRect = [ff bounds];
        
        // flip preview width and height
        CGFloat temp = faceRect.size.width;
        faceRect.size.width = faceRect.size.height;
        faceRect.size.height = temp;
        temp = faceRect.origin.x;
        faceRect.origin.x = faceRect.origin.y;
        faceRect.origin.y = temp;
        // scale coordinates so they fit in the preview box, which may be scaled
        CGFloat widthScaleBy = previewBox.size.width / clearAperture.size.height;
        CGFloat heightScaleBy = previewBox.size.height / clearAperture.size.width;
        faceRect.size.width *= widthScaleBy;
        faceRect.size.height *= heightScaleBy;
        faceRect.origin.x *= widthScaleBy;
        faceRect.origin.y *= heightScaleBy;
        
        if ( isMirrored )
            faceRect = CGRectOffset(faceRect, previewBox.origin.x + previewBox.size.width - faceRect.size.width - (faceRect.origin.x * 2), previewBox.origin.y);
        else
            faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
        
        CALayer *featureLayer = nil;
        
        // re-use an existing layer if possible
        while (!featureLayer && (currentSublayer < sublayersCount) ) {
            CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
            if ( [[currentLayer name] isEqualToString:@"FaceLayer"] ) {
                featureLayer = currentLayer;
                [currentLayer setHidden:NO];
            }
        }
        
        // create a new one if necessary
        if ( !featureLayer ) {
            featureLayer = [[CALayer alloc]init];
            featureLayer.contents = (id)self.borderImage.CGImage;
            [featureLayer setName:@"FaceLayer"];
            [self.previewLayer addSublayer:featureLayer];
            featureLayer = nil;
        }
        [featureLayer setFrame:faceRect];
        
        switch (orientation) {
            case UIDeviceOrientationPortrait:
                [featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(0.))];
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                [featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(180.))];
                break;
            case UIDeviceOrientationLandscapeLeft:
                [featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(90.))];
                break;
            case UIDeviceOrientationLandscapeRight:
                [featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(-90.))];
                break;
            case UIDeviceOrientationFaceUp:
            case UIDeviceOrientationFaceDown:
            default:
                break; // leave the layer in its last known orientation
        }
        currentFeature++;
    }
    
    [CATransaction commit];
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

-(NSArray *)listFileAtPath:(NSString *)path
{
    //-----> LIST ALL FILES <-----//
    NSLog(@"LISTING ALL FILES FOUND");
    
    int count;
    
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    for (count = 0; count < (int)[directoryContent count]; count++)
    {
        NSLog(@"File %d: %@", (count + 1), [directoryContent objectAtIndex:count]);
    }
    return directoryContent;
}

- (NSURL *)recordingURL
{
    NSString *filename = [NSString stringWithFormat:@"%@.mp4", [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                                                              dateStyle:NSDateFormatterMediumStyle
                                                                                              timeStyle:NSDateFormatterMediumStyle]];
    return [[NSURL alloc] initFileURLWithPath:[NSString pathWithComponents:@[[self documentsPath], filename]]];
}

- (NSString *)documentsPath
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [searchPaths objectAtIndex:0];
}

@end
