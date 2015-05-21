//
//  FlatButtonTableViewCell.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/21/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "FlatButtonTableViewCell.h"

@implementation FlatButtonTableViewCell

@synthesize textLabel = _textLabel;

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

//    if (selected) {
//        self.contentView.backgroundColor = [UIColor colorWithRed:97/255.0 green:106/255.0 blue:116/255.0 alpha:1.0];
//    } else {
//        self.contentView.backgroundColor = [UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:1.0];
//    }
}

@end
