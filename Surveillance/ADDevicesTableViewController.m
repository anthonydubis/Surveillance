//
//  ADDevicesTableViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/21/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADDevicesTableViewController.h"
#import "PFInstallation+ADDevice.h"
#import "DeviceTableViewCell.h"
#import "ADNotificationHelper.h"

NSString * DeviceCellID = @"DeviceCell";

@interface ADDevicesTableViewController ()

@property (nonatomic, strong) NSMutableArray *activeDevices;
@property (nonatomic, strong) NSMutableArray *inactiveDevices;

@end

@implementation ADDevicesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor colorWithRed:97/255.0 green:106/255.0 blue:116/255.0 alpha:1.0];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(loadObjects)
                  forControlEvents:UIControlEventValueChanged];
    
    [self loadObjects];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)loadObjects {
    [PFCloud callFunctionInBackground:@"getInstallationsForUser"
                       withParameters:nil
                                block:^(NSArray *results, NSError *error) {
                                    if (!error) {
                                        // Remove current objects
                                        [self.inactiveDevices removeAllObjects];
                                        [self.activeDevices removeAllObjects];
                                        
                                        for (PFInstallation *installation in results) {
                                            if (installation.isMonitoring) {
                                                [self.activeDevices addObject:installation];
                                            } else {
                                                [self.inactiveDevices addObject:installation];
                                            }
                                        }
                                
                                        if (self.refreshControl) {
                                            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                                            [formatter setDateFormat:@"MMM d, h:mm a"];
                                            NSString *title = [NSString stringWithFormat:@"Last update: %@", [formatter stringFromDate:[NSDate date]]];
                                            NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                                                        forKey:NSForegroundColorAttributeName];
                                            NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
                                            self.refreshControl.attributedTitle = attributedTitle;
                                            
                                            [self.refreshControl endRefreshing];
                                        }
                                        
                                        [self.tableView reloadData];
                                    } else {
                                        NSLog(@"Error! %@", error);
                                    }
                                }];
}

#pragma mark - Table view data source

#define CELL_HEIGHT 90.0
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_HEIGHT;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    int count = 0;
    if (self.activeDevices.count) count++;
    if (self.inactiveDevices.count) count++;
    return count;;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0 && self.activeDevices.count)
        return @"Active Devices";
    else
        return @"Inactive Devices";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && self.activeDevices.count)
        return self.activeDevices.count;
    else
        return self.inactiveDevices.count;
}

- (PFInstallation *)objectForIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && self.activeDevices.count)
        return [self.activeDevices objectAtIndex:indexPath.row];
    else
        return [self.inactiveDevices objectAtIndex:indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DeviceCellID forIndexPath:indexPath];
    [self configureDeviceCell:cell forIndexPath:indexPath];
    return cell;
}

- (void)configureDeviceCell:(DeviceTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    PFInstallation *installation = [self objectForIndexPath:indexPath];
    
#warning Make sure this works for devices not taking push notifications
    // Set text labels
    cell.textLabel.text = installation.deviceName;
    cell.detailTextLabel.text = (installation.deviceToken) ? @"Notifications enabled" : @"Notifications disabled";
    cell.statusLabel.text = (installation.isMonitoring) ? @"Status: Monitoring" : @"Status: Inactive";
    
    // Set image
    NSString *imageName = ([installation isiPad]) ? @"iPad" : @"iPhone";
    cell.imageView.image = [UIImage imageNamed:imageName];
    
    // Set the accessory view
    if (installation.isMonitoring)
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [tableView.delegate tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && self.activeDevices.count)
        return indexPath;
    else
        return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [UIActionSheet showFromTabBar:self.tabBarController.tabBar
                        withTitle:nil
                cancelButtonTitle:@"Cancel"
           destructiveButtonTitle:@"Disable Camera"
                otherButtonTitles:nil
                         tapBlock:^(UIActionSheet *as, NSInteger buttonIndex) {
                             if (buttonIndex != as.cancelButtonIndex) {
                                 PFInstallation *monitoringInstallation = [self objectForIndexPath:indexPath];
                                 [ADNotificationHelper sendMessageToDisableMonitoringInstallation:monitoringInstallation];
                             }
                             [tableView deselectRowAtIndexPath:indexPath animated:YES];
                         }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Getters / Setters

- (NSMutableArray *)activeDevices
{
    if (!_activeDevices)
        _activeDevices = [[NSMutableArray alloc] init];
    return _activeDevices;
}

- (NSMutableArray *)inactiveDevices
{
    if (!_inactiveDevices)
        _inactiveDevices = [[NSMutableArray alloc] init];
    return _inactiveDevices;
}

@end
