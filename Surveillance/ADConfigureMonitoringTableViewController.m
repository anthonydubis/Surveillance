//
//  ConfigureMonitoringTableViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/3/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADConfigureMonitoringTableViewController.h"
#import "ObservationViewController.h"
#import "SegmentedControlCell.h"
#import "ADMonitoringViewController.h"
#import "ADMotionDetector.h"
#import <AWSS3/AWSS3.h>
#import "ADFileHelper.h"
#import "SwitchTableViewCell.h"
#import "FlatButtonTableViewCell.h"
#import "SliderCell.h"

// Cell Identifiers
NSString * RightDetailCellID = @"RightDetail";
NSString * LeftDetailCellID  = @"LeftDetail";
NSString * SwitchCellID      = @"SwitchCell";
NSString * FooterID          = @"FooterView";
NSString * ButtonCellID      = @"ButtonCell";
NSString * SliderCellID      = @"SliderCell";

// Preferences
NSString * PrefKeyMotionSensitivity      = @"PrefKeyMotionSensitivity";
NSString * PrefKeyVideoQuality           = @"PrefKeyVideoQuality";
NSString * PrefKeyPreferredFrameRate     = @"PrefKeyPreferredFrameRate";
NSString * PrefKeyBeepOnRecordingStart   = @"PrefKeyBeepOnRecordingStart";
NSString * PrefKeyBeepOnRecordingStops   = @"PrefKeyBeepOnRecordingStops";
NSString * PrefKeyBeepOnFaceDetected     = @"PrefKeyBeepOnFaceDetected";
NSString * PrefKeyNotifyOnRecordingStart = @"PrefKeyNotifyOnRecordingStart";
NSString * PrefKeyNotifyOnRecordingStops = @"PrefKeyNotifyOnRecordingStops";
NSString * PrefKeyNotifyOnFaceDetected   = @"PrefKeyNotifyOnFaceDetected";
NSString * PrefKeyNotifyOnCameraDisabled = @"PrefKeyNotifyOnCameraDisabled";


@interface ADConfigureMonitoringTableViewController ()
{    
    BOOL showSensitivityOptions;
    BOOL showVideoQualityOptions;
    BOOL beepWhenRecordingStarts;
    BOOL beepWhenRecordingStops;
    BOOL beepWhenFaceDetected;
    BOOL notifyOnMotionStart;
    BOOL notifyOnMotionEnd;
    BOOL notifyOnFaceDetection;
    BOOL notifyWhenCameraDisabled;
    
    UISwitch *beepRecordingStopsSwitch;
    UISwitch *beepRecordingStartsSwitch;
    UISwitch *beepFaceDetectedSwitch;
    UISwitch *notifyMotionStartSwitch;
    UISwitch *notifyMotionEndSwitch;
    UISwitch *notifyFaceDetectionSwitch;
    UISwitch *notifyCameraDisabledSwitch;
}

@property (nonatomic, assign) MotionDetectorSensitivity motionSensitivity;
@property (nonatomic, assign) ADVideoQuality videoQuality;
@property (nonatomic, assign) NSInteger frameRate;

@end

@implementation ADConfigureMonitoringTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupInitialOptions];
    [ADFileHelper listAllFilesAtToUploadDirectory];
    [ADFileHelper listAllFilesInDownloadsDirectory];
    
    [self.tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:FooterID];
}

- (void)setupInitialOptions {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Motion sensitivity
    MotionDetectorSensitivity sensitivity = [defaults integerForKey:PrefKeyMotionSensitivity];
    _motionSensitivity = (sensitivity == 0) ? MotionDetectorSensitivityHigh : sensitivity;
    
    ADVideoQuality videoQuality = [defaults integerForKey:PrefKeyVideoQuality];
    _videoQuality = (videoQuality == 0) ? ADVideoQualityStandard : videoQuality;
    
    NSInteger frameRate = [defaults integerForKey:PrefKeyPreferredFrameRate];
    _frameRate = (frameRate == 0) ? 30 : frameRate;
    
#warning Set initial values for these
    // Sounds
    beepWhenRecordingStarts = [defaults boolForKey:PrefKeyBeepOnRecordingStart];
    beepWhenRecordingStops  = [defaults boolForKey:PrefKeyBeepOnRecordingStops];
    beepWhenFaceDetected    = [defaults boolForKey:PrefKeyBeepOnFaceDetected];
    
    // Notifications
    notifyOnMotionStart      = [defaults boolForKey:PrefKeyNotifyOnRecordingStart];
    notifyOnMotionEnd        = [defaults boolForKey:PrefKeyNotifyOnRecordingStops];
    notifyOnFaceDetection    = [defaults boolForKey:PrefKeyNotifyOnFaceDetected];
    notifyWhenCameraDisabled = [defaults boolForKey:PrefKeyNotifyOnCameraDisabled];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    // Return the automatic dimensions for the section with the "Start" button
    if (section == 4) return UITableViewAutomaticDimension;
    
    // Calculate the height for the section with footerViews
    NSString *text = [self textForFooterInSection:section];
    
    CGFloat margin = 15.0;
    CGSize constrainedSize = CGSizeMake(self.view.bounds.size.width - margin * 2, 9999);
    
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [UIFont systemFontOfSize:13.0], NSFontAttributeName,
                                          nil];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:text attributes:attributesDictionary];
    
    CGRect requiredRect = [string boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    CGFloat height = requiredRect.size.height;
    
    return height + 12.0;
}

- (NSString *)textForFooterInSection:(NSInteger)section
{
    switch (section) {
        case 0: return @"The motion sensitivity determines how much motion must occur in the environment for the camera to begin recording.";
        case 1: return @"Standard video quality and a high number of frames captured per second will result in higher quality videos, but they will take up more space.";
        case 2: return @"These sounds will play through this device. Please turn up the volume and make sure the device is not silenced.";
        case 3: return @"These alerts will go to other devices that you have accepted Notifications on.";
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    // Reuse the instance that was created in viewDidLoad, or make a new one if not enough.
    UITableViewHeaderFooterView *footerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:FooterID];
    footerView.textLabel.text = [self textForFooterInSection:section];
    
    // Specify your own font to ensure it doesn't change (makes specifying the height in heightForFooter easy)
    // Must set other three properties if you change the font
    footerView.textLabel.font = [UIFont systemFontOfSize:13.0];
    footerView.textLabel.numberOfLines = 0;
    footerView.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    footerView.textLabel.textColor = [UIColor colorWithRed:109/255.0 green:109/255.0 blue:114/255.0 alpha:1.0];
    
    // Uncomment this to see contentView background
    // footerView.contentView.backgroundColor = [UIColor redColor];
    
    return footerView;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0: return @"Motion Sensitivity";
        case 1: return @"Video Quality";
        case 2: return @"Sounds";
        case 3: return @"Notifications";
        default: return nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return (showSensitivityOptions) ? 4 : 1;
        case 1: return (showVideoQualityOptions) ? 4 : 2;
        case 2: return 3;
        case 3: return 4;
        case 4: return 1;
        default: return 0;
    }
}

#define SLIDER_CELL_HEIGHT 75.0

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath isEqual:[self frameRateSelectionIndexPath]])
        return SLIDER_CELL_HEIGHT;
    else
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger s = indexPath.section;
    NSInteger r = indexPath.row;
    
    UITableViewCell *cell;
    
    if (s == 0) {
        if (r == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:RightDetailCellID forIndexPath:indexPath];
            [self configureSelectedSensitivityCell:cell forIndexPath:indexPath];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:LeftDetailCellID forIndexPath:indexPath];
            [self configureSelectivityOptionCell:cell forIndexPath:indexPath];
        }
    } else if (s == 1) {
        if (r == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:RightDetailCellID forIndexPath:indexPath];
            [self configureSelectedVideoQualityCell:cell forIndexPath:indexPath];
        } else if ([indexPath isEqual:[self frameRateSelectionIndexPath]]) {
            SliderCell *sliderCell = [tableView dequeueReusableCellWithIdentifier:SliderCellID forIndexPath:indexPath];
            [self configureSliderCell:sliderCell forIndexPath:indexPath];
            cell = sliderCell;
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:LeftDetailCellID forIndexPath:indexPath];
            [self configureVideoQualityOptionCell:cell forIndexPath:indexPath];
        }
    } else if (s == 2 || s == 3) {
        SwitchTableViewCell *switchCell = [tableView dequeueReusableCellWithIdentifier:SwitchCellID forIndexPath:indexPath];
        if (s == 2)
            [self configureSoundCell:switchCell forIndexPath:indexPath];
        else
            [self configureNotificationCell:switchCell forIndexPath:indexPath];
        cell = switchCell;
    } else if (s == 4) {
        FlatButtonTableViewCell *buttonCell = [tableView dequeueReusableCellWithIdentifier:ButtonCellID forIndexPath:indexPath];
        cell = buttonCell;
    }
    
    return cell;
}

- (void)configureSelectedSensitivityCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.text = @"Motion Sensitivity";
    cell.detailTextLabel.text = [ADMotionDetector nameForSensitivity:self.motionSensitivity];
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
}

- (void)configureSelectivityOptionCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    MotionDetectorSensitivity sensitivity = (MotionDetectorSensitivity)indexPath.row;
    cell.textLabel.text = [ADMotionDetector nameForSensitivity:sensitivity];
    cell.detailTextLabel.text = [ADMotionDetector descriptionForSensitivity:sensitivity];
    
    if (self.motionSensitivity == sensitivity)
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
}

- (void)configureSelectedVideoQualityCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.text = @"Video Quality";
    cell.detailTextLabel.text = [ADCameraStreamViewController nameForVideoQuality:_videoQuality];
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
}

- (void)configureVideoQualityOptionCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    ADVideoQuality videoQuality = (ADVideoQuality)indexPath.row;
    cell.textLabel.text = [ADCameraStreamViewController nameForVideoQuality:videoQuality];
    cell.detailTextLabel.text = [ADCameraStreamViewController descriptionForVideoQuality:videoQuality];
    
    if (_videoQuality == videoQuality) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}


- (void)configureSliderCell:(SliderCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.text = @"Frames Captured per Second";
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%li", (long)_frameRate];
    cell.slider.value = _frameRate;
    [cell.slider addTarget:self action:@selector(frameRateChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)frameRateChanged:(UISlider *)sender
{
    _frameRate = sender.value;
    SliderCell *cell = (SliderCell *)[self.tableView cellForRowAtIndexPath:[self frameRateSelectionIndexPath]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%li", (long)_frameRate];
}

- (void)configureSoundCell:(SwitchTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Recording starts";
            cell.switchControl.on = beepWhenRecordingStarts;
            beepRecordingStartsSwitch = cell.switchControl;
            break;
        case 1:
            cell.textLabel.text = @"Recording stops";
            cell.switchControl.on = beepWhenRecordingStops;
            beepRecordingStopsSwitch = cell.switchControl;
            break;
        case 2:
            cell.textLabel.text = @"Face is detected";
            cell.switchControl.on = beepWhenFaceDetected;
            beepFaceDetectedSwitch = cell.switchControl;
            break;
    }
    [cell.switchControl addTarget:self action:@selector(switchControlToggled:) forControlEvents:UIControlEventValueChanged];
}

- (void)configureNotificationCell:(SwitchTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Motion is detected";
            cell.switchControl.on = notifyOnMotionStart;
            notifyMotionStartSwitch = cell.switchControl;
            break;
        case 1:
            cell.textLabel.text = @"Motion ends";
            cell.switchControl.on = notifyOnMotionEnd;
            notifyMotionEndSwitch = cell.switchControl;
            break;
        case 2:
            cell.textLabel.text = @"Face is detected";
            cell.switchControl.on = notifyOnFaceDetection;
            notifyFaceDetectionSwitch = cell.switchControl;
            break;
        case 3:
            cell.textLabel.text = @"Camera is disabled";
            cell.switchControl.on = notifyWhenCameraDisabled;
            notifyCameraDisabledSwitch = cell.switchControl;
            break;
    }
    [cell.switchControl addTarget:self action:@selector(switchControlToggled:) forControlEvents:UIControlEventValueChanged];
}

#pragma mark - Table view delegate

- (void)switchControlToggled:(UISwitch *)switchControl
{
    if      (switchControl == beepRecordingStartsSwitch)  beepWhenRecordingStarts = switchControl.on;
    else if (switchControl == beepRecordingStopsSwitch)   beepWhenRecordingStops = switchControl.on;
    else if (switchControl == beepFaceDetectedSwitch)     beepWhenFaceDetected = switchControl.on;
    else if (switchControl == notifyMotionStartSwitch)    notifyOnMotionStart = switchControl.on;
    else if (switchControl == notifyMotionEndSwitch)      notifyOnMotionEnd = switchControl.on;
    else if (switchControl == notifyFaceDetectionSwitch)  notifyOnFaceDetection = switchControl.on;
    else if (switchControl == notifyCameraDisabledSwitch) notifyWhenCameraDisabled = switchControl.on;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    [tableView.delegate tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger s = indexPath.section;
    if (s == 2 || s == 3 || [indexPath isEqual:[self frameRateSelectionIndexPath]])
        return nil;
    else
        return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isMotionSensitivityIndexPath:indexPath]) {
        showSensitivityOptions = !showSensitivityOptions;
        if (showSensitivityOptions) {
            [tableView insertRowsAtIndexPaths:[self sensitivityOptionsIndexPaths] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [tableView deleteRowsAtIndexPaths:[self sensitivityOptionsIndexPaths] withRowAnimation:UITableViewRowAnimationFade];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
    } else if ([self isMotionSensitivityOptionIndexPath:indexPath]) {
        self.motionSensitivity = (MotionDetectorSensitivity)indexPath.row;
        showSensitivityOptions = NO;
        [tableView deleteRowsAtIndexPaths:[self sensitivityOptionsIndexPaths] withRowAnimation:UITableViewRowAnimationFade];
        [tableView reloadRowsAtIndexPaths:@[[self motionSensitivityIndexPath]] withRowAnimation:UITableViewRowAnimationFade];
        
    } else if ([self isVideoQualityIndexPath:indexPath]) {
        showVideoQualityOptions = !showVideoQualityOptions;
        if (showVideoQualityOptions) {
            [tableView insertRowsAtIndexPaths:[self videoQualityOptionsIndexPaths] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [tableView deleteRowsAtIndexPaths:[self videoQualityOptionsIndexPaths] withRowAnimation:UITableViewRowAnimationFade];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
    } else if ([self isVideoQualityOptionIndexPath:indexPath]) {
        self.videoQuality = (ADVideoQuality)indexPath.row;
        showVideoQualityOptions = NO;
        [tableView deleteRowsAtIndexPaths:[self videoQualityOptionsIndexPaths] withRowAnimation:UITableViewRowAnimationFade];
        [tableView reloadRowsAtIndexPaths:@[[self videoQualityIndexPath]] withRowAnimation:UITableViewRowAnimationFade];
        
    } else if ([self isStartMonitoringIndexPath:indexPath]) {
        [self performSegueWithIdentifier:@"StartMonitoringSegue" sender:nil];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (IBAction)startMonitoring:(UIBarButtonItem *)sender
{
    [self performSegueWithIdentifier:@"StartMonitoringSegue" sender:nil];
}

- (NSIndexPath *)motionSensitivityIndexPath
{   return [NSIndexPath indexPathForRow:0 inSection:0]; }

- (BOOL)isMotionSensitivityIndexPath:(NSIndexPath *)indexPath
{   return [[self motionSensitivityIndexPath] isEqual:indexPath];   }

- (BOOL)isMotionSensitivityOptionIndexPath:(NSIndexPath *)indexPath
{   return [[self sensitivityOptionsIndexPaths] containsObject:indexPath];  }

- (NSArray *)sensitivityOptionsIndexPaths
{
    return @[[NSIndexPath indexPathForRow:1 inSection:0], [NSIndexPath indexPathForRow:2 inSection:0],
             [NSIndexPath indexPathForRow:3 inSection:0]];
}

- (BOOL)isVideoQualityIndexPath:(NSIndexPath *)indexPath
{   return [[self videoQualityIndexPath] isEqual:indexPath];    }

- (NSIndexPath *)videoQualityIndexPath
{   return [NSIndexPath indexPathForRow:0 inSection:1]; }

- (NSArray *)videoQualityOptionsIndexPaths
{
    return @[[NSIndexPath indexPathForRow:1 inSection:1], [NSIndexPath indexPathForRow:2 inSection:1]];
}

- (BOOL)isVideoQualityOptionIndexPath:(NSIndexPath *)indexPath
{   return [[self videoQualityOptionsIndexPaths] containsObject:indexPath]; }

- (NSIndexPath *)frameRateSelectionIndexPath
{
    NSInteger row = (showVideoQualityOptions) ? 3 : 1;
    return [NSIndexPath indexPathForRow:row inSection:1];
}

- (BOOL)isStartMonitoringIndexPath:(NSIndexPath *)indexPath
{   return indexPath.section == ([self.tableView numberOfSections] - 1);    }

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"StartMonitoringSegue"]) {
        [self savePreferences];
        UINavigationController *navCon = (UINavigationController *)segue.destinationViewController;
        ADMonitoringViewController *avovc = (ADMonitoringViewController *)navCon.topViewController;

        // Configure settings
        avovc.motionSensitivity = _motionSensitivity;
        avovc.frameRate = _frameRate;
        avovc.videoQuality = _videoQuality;
        avovc.beepWhenRecordingStarts = beepWhenRecordingStarts;
        avovc.beepWhenRecordingStops = beepWhenRecordingStops;
        avovc.beepWhenFaceDetected = beepWhenFaceDetected;
        avovc.notifyOnMotionStart = notifyOnMotionStart;
        avovc.notifyOnMotionEnd = notifyOnMotionEnd;
        avovc.notifyOnFaceDetection = notifyOnFaceDetection;
        avovc.notifyWhenCameraDisabled = notifyWhenCameraDisabled;
    }
}

- (void)savePreferences
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Motion sensitivity
    [defaults setInteger:_motionSensitivity forKey:PrefKeyMotionSensitivity];
    
    // Video quality
    [defaults setInteger:_videoQuality forKey:PrefKeyVideoQuality];
    [defaults setInteger:_frameRate forKey:PrefKeyPreferredFrameRate];
    
    // Sounds
    [defaults setBool:beepWhenRecordingStarts forKey:PrefKeyBeepOnRecordingStart];
    [defaults setBool:beepWhenRecordingStops forKey:PrefKeyBeepOnRecordingStops];
    [defaults setBool:beepWhenFaceDetected forKey:PrefKeyBeepOnFaceDetected];
    
    // Notifications
    [defaults setBool:notifyOnMotionStart forKey:PrefKeyNotifyOnRecordingStart];
    [defaults setBool:notifyOnMotionEnd forKey:PrefKeyNotifyOnRecordingStops];
    [defaults setBool:notifyOnFaceDetection forKey:PrefKeyNotifyOnFaceDetected];
    [defaults setBool:notifyWhenCameraDisabled forKey:PrefKeyNotifyOnCameraDisabled];
    
    [defaults synchronize];
}

@end
