//
//  SliderCell.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/29/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "SliderCell.h"

@implementation SliderCell

@synthesize textLabel = _textLabel;
@synthesize detailTextLabel = _detailTextLabel;

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
