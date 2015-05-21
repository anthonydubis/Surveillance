//
//  ADSurveillanceTableViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/21/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADSurveillanceTableViewController.h"

@interface ADSurveillanceTableViewController ()

@end

@implementation ADSurveillanceTableViewController

#define CELL_HEIGHT 55.0;

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

@end
