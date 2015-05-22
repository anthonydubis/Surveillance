//
//  ADSettingsTableTableViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/21/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADSettingsTableViewController.h"
#import "FlatButtonTableViewCell.h"
#import <Parse/Parse.h>
#import "AppDelegate.h"

NSString * BasicCellID  = @"BasicCell";
NSString * ButtonCellID2 = @"ButtonCell";

@interface ADSettingsTableViewController ()

@end

@implementation ADSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0: return @"Account Settings";
        case 1: return @"General";
        default: return @" "; // Hackish way of giving the top of the login button a little more space
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    switch (section) {
        case 0: return 2;
        case 1: return 3;
        case 2: return 1;
        default: return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger s = indexPath.section;
    NSInteger r = indexPath.row;
    
    UITableViewCell *cell;
    
    if (s == 0 || s == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:BasicCellID forIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if (s == 0) {
            if (r == 0) {
                cell.textLabel.text = @"Change Email";
            } else if (r == 1) {
                cell.textLabel.text = @"Change Password";
            }
            
        } else if (s == 1) {
            if (r == 0) {
                cell.textLabel.text = @"Rate Surveillance";
            } else if (r == 1) {
                cell.textLabel.text = @"Send us Feedback";
            } else if (r == 2) {
                cell.textLabel.text = @"Privacy Policy";
            }
        
        }
    } else if (s == 2) {
        FlatButtonTableViewCell *buttonCell = [tableView dequeueReusableCellWithIdentifier:ButtonCellID2 forIndexPath:indexPath];
        cell = buttonCell;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isLogoutCell:indexPath]) {
        [PFUser logOut];
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [appDelegate userLoggedOut];
    }
}

- (BOOL)isLogoutCell:(NSIndexPath *)indexPath
{
    return indexPath.section == (self.tableView.numberOfSections - 1);
}

@end
