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

@interface ConfigureMonitoringTableViewController ()

@property (nonatomic, assign) MotionDetectorSensitivity motionSensitivity;

@end

@implementation ConfigureMonitoringTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.motionSensitivity = MotionDetectorSensitivityHigh;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self listFileAtPath:[self documentsPath]];
}

#pragma mark - Handle user login


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
        MonitoringViewController *avovc = (MonitoringViewController *)navCon.topViewController;
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
        NSString *filename = [directoryContent objectAtIndex:count];
        if (![filename containsString:@"Surveillance"]) {
            NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[path stringByAppendingPathComponent:filename]
                                                                                            error:nil];
            unsigned long long size = [fileDictionary fileSize];
            NSLog(@"File %d: %@, file size: %llu", (count + 1), [directoryContent objectAtIndex:count], size);
        }
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
        if (![filename containsString:@"Surveillance"]) {
            NSString *fullPath = [path stringByAppendingPathComponent:filename];
            NSLog(@"About to remove: %@", fullPath);
            [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
        }
    }
}

- (IBAction)testUploadPressed:(id)sender {
    // Create the URL
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = @"surveillance-bucket";
    uploadRequest.key = @"2015-05-15-15-31-23.mp4";
    NSString *path = [[self documentsPath] stringByAppendingPathComponent:@"2015-05-15-15-31-23.mp4"];
    NSURL *testURL = [NSURL fileURLWithPath:path];
    NSLog(@"%@", testURL);
    uploadRequest.body = testURL;
    
    
    
    AWSS3TransferManager *manager = [AWSS3TransferManager defaultS3TransferManager];
    
    [[manager upload:uploadRequest] continueWithExecutor:[BFExecutor mainThreadExecutor]
                                               withBlock:^id(BFTask *task) {
                                                            if (task.error) {
                                                                if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
                                                                    switch (task.error.code) {
                                                                        case AWSS3TransferManagerErrorCancelled:
                                                                        case AWSS3TransferManagerErrorPaused:
                                                                            break;
                                                                           
                                                                        default:
                                                                            NSLog(@"Error: %@", task.error);
                                                                            break;
                                                                    }
                                                                } else {
                                                                    // Unknown error.
                                                                    NSLog(@"Error: %@", task.error);
                                                                }
                                                            }
                                                           
                                                            if (task.result) {
                                                                AWSS3TransferManagerUploadOutput *uploadOutput = task.result;
                                                                // The file uploaded successfully.
                                                                NSLog(@"File uploaded successfully");
                                                            }
                                                            return nil;
                                                        }];
}
@end
