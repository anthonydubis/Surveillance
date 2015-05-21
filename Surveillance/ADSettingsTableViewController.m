//
//  ADSettingsTableTableViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/21/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADSettingsTableViewController.h"
#import "FlatButtonTableViewCell.h"

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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
