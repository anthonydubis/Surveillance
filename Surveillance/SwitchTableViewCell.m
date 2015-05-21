//
//  SwitchTableViewCell.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/20/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "SwitchTableViewCell.h"

@implementation SwitchTableViewCell

@synthesize textLabel = _textLabel;

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
