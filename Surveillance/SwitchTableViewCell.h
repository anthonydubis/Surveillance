//
//  SwitchTableViewCell.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/20/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SwitchTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UISwitch *switchControl;

@end
