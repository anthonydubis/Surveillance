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
#import "ADMotionDetector.h"

@interface ConfigureMonitoringTableViewController ()

@property (nonatomic, assign) MotionDetectorSensitivity motionSensitivity;

@end

@implementation ConfigureMonitoringTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.motionSensitivity = MotionDetectorSensitivityHigh;
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
    cell.segmentedControl.selectedSegmentIndex = self.motionSensitivity;
    [cell.segmentedControl addTarget:self action:@selector(motionSensitivityChanged:)
                    forControlEvents:UIControlEventValueChanged];
}

- (void)motionSensitivityChanged:(UISegmentedControl *)sender
{
    self.motionSensitivity = (MotionDetectorSensitivity)sender.selectedSegmentIndex;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"AVStartMonitoring"]) {
        UINavigationController *navCon = (UINavigationController *)segue.destinationViewController;
        AVObservationViewController *avovc = (AVObservationViewController *)navCon.topViewController;
        avovc.motionSensitivity = self.motionSensitivity;
    }
}

- (NSArray *)listFileAtPath:(NSString *)path
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

- (NSString *)documentsPath
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [searchPaths objectAtIndex:0];
}

- (void)deleteFilesAtPath:(NSString *)path
{
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    for (NSString *filename in directoryContent) {
        NSString *fullPath = [path stringByAppendingPathComponent:filename];
        NSLog(@"About to remove: %@", fullPath);
        [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
    }
}

@end
