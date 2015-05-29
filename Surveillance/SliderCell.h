//
//  SliderCell.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/29/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SliderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailTextLabel;
@property (weak, nonatomic) IBOutlet UISlider *slider;

@end
