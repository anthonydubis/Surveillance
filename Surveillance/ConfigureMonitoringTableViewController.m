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
#import "AVObservationViewController.h"

const int High_Motion_Sensitivity   = 1000;
const int Medium_Motion_Sensitivity = 10000;
const int Low_Motion_Sensitivity    = 50000;

@interface ConfigureMonitoringTableViewController ()

@property (nonatomic, assign) int motionSensitivity;

@end

@implementation ConfigureMonitoringTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SegmentedControlCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SegmentedControlCell" forIndexPath:indexPath];
    [self configureMotionSensitivityCell:cell];
    return cell;
}

- (void)configureMotionSensitivityCell:(SegmentedControlCell *)cell
{
    switch (self.motionSensitivity) {
        case Low_Motion_Sensitivity:    cell.segmentedControl.selectedSegmentIndex = 0; break;
        case Medium_Motion_Sensitivity: cell.segmentedControl.selectedSegmentIndex = 1; break;
        case High_Motion_Sensitivity:   cell.segmentedControl.selectedSegmentIndex = 2; break;
    }
    [cell.segmentedControl addTarget:self action:@selector(motionSensitivityChanged:)
                    forControlEvents:UIControlEventValueChanged];
}

- (void)motionSensitivityChanged:(UISegmentedControl *)sender
{
    switch (sender.selectedSegmentIndex) {
        case 0: self.motionSensitivity = Low_Motion_Sensitivity;    break;
        case 1: self.motionSensitivity = Medium_Motion_Sensitivity; break;
        case 2: self.motionSensitivity = High_Motion_Sensitivity;   break;
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"StartMonitoring"]) {
        UINavigationController *navCon = (UINavigationController *)segue.destinationViewController;
        ObservationViewController *ovc = (ObservationViewController *)navCon.topViewController;
        ovc.motionSensitivity = self.motionSensitivity;
    } else if ([segue.identifier isEqualToString:@"AVStartMonitoring"]) {
        UINavigationController *navCon = (UINavigationController *)segue.destinationViewController;
        AVObservationViewController *avovc = (AVObservationViewController *)navCon.topViewController;
        avovc.motionSensitivity = self.motionSensitivity;
    }
}

#pragma mark - Getters/Setters

- (int)motionSensitivity
{
    if (_motionSensitivity == 0) {
        _motionSensitivity = High_Motion_Sensitivity;
    }
    return _motionSensitivity;
}

@end
