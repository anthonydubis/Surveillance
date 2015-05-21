//
//  ConfigureMonitoringTableViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/3/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ConfigureMonitoringTableViewController.h"
#import "ObservationViewController.h"
#import "SegmentedControlCell.h"
#import "MonitoringViewController.h"
#import "ADMotionDetector.h"
#import <AWSS3/AWSS3.h>
#import "ADFileHelper.h"
#import "SwitchTableViewCell.h"

NSString * RightDetailCellID = @"RightDetail";
NSString * LeftDetailCellID  = @"LeftDetail";
NSString * SwitchCellID      = @"SwitchCell";
NSString * FooterID          = @"FooterView";

@interface ConfigureMonitoringTableViewController ()
{
    BOOL showSensitivityOptions;
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

@end

@implementation ConfigureMonitoringTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.motionSensitivity = MotionDetectorSensitivityHigh;
    [ADFileHelper listAllFilesAtToUploadDirectory];
    [ADFileHelper listAllFilesInDownloadsDirectory];
    
    [self.tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:FooterID];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 60.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    // Reuse the instance that was created in viewDidLoad, or make a new one if not enough.
    UITableViewHeaderFooterView *footerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:FooterID];
    NSString *text;
    if (section == 0)
        text = @"The camera's sensitivity determines how much motion must occur in the environment for the camera to begin recording.";
    else if (section == 1)
        text = @"These sounds will play through this device. Please turn up the volume and make sure the device is not silenced.";
    else if (section == 2)
        text = @"These alerts will go to other devices that you have accepted Notifications on.";
    
    footerView.textLabel.text = text;
    NSLog(@"Font for text label: %@", footerView.textLabel.font);
    return footerView;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return @"Motion Sensitivity";
    else if (section == 1)
        return @"Sounds";
    else if (section == 2)
        return @"Receive Notifications";
    else
        return nil;
}

#define CELL_HEIGHT 50.0;

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if (showSensitivityOptions)
            return 4;
        else
            return 1;
    } else if (section == 1) {
        return 3;
    } else if (section == 2) {
        return 4;
    }
    return 0;
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
    } else {
        SwitchTableViewCell *switchCell = [tableView dequeueReusableCellWithIdentifier:SwitchCellID forIndexPath:indexPath];
        if (s == 1)
            [self configureSoundCell:switchCell forIndexPath:indexPath];
        else
            [self configureNotificationCell:switchCell forIndexPath:indexPath];
        cell = switchCell;
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

- (void)configureSoundCell:(SwitchTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Beep when recording starts";
            cell.switchControl.on = beepWhenRecordingStarts;
            beepRecordingStartsSwitch = cell.switchControl;
            break;
        case 1:
            cell.textLabel.text = @"Been when recording stops";
            cell.switchControl.on = beepWhenRecordingStops;
            beepRecordingStopsSwitch = cell.switchControl;
            break;
        case 2:
            cell.textLabel.text = @"Beep when face detected";
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
    
    NSLog(@"%i %i %i %i %i %i %i", beepWhenRecordingStarts, beepWhenRecordingStops, beepWhenFaceDetected, notifyOnMotionStart,
          notifyOnMotionEnd, notifyOnFaceDetection, notifyWhenCameraDisabled);
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    [tableView.delegate tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section > 0)
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
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    } else if ([self isMotionSensitivityOptionIndexPath:indexPath]) {
        self.motionSensitivity = (MotionDetectorSensitivity)indexPath.row;
        showSensitivityOptions = NO;
        [tableView deleteRowsAtIndexPaths:[self sensitivityOptionsIndexPaths] withRowAnimation:UITableViewRowAnimationFade];
        [tableView reloadRowsAtIndexPaths:@[[self motionSensitivityIndexPath]] withRowAnimation:UITableViewRowAnimationFade];
    }
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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"AVStartMonitoring"]) {
        UINavigationController *navCon = (UINavigationController *)segue.destinationViewController;
        MonitoringViewController *avovc = (MonitoringViewController *)navCon.topViewController;
        avovc.motionSensitivity = self.motionSensitivity;
    }
}

@end
