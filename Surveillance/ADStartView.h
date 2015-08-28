//
//  ADStartView.h
//  Surveillance
//
//  Created by Anthony Dubis on 8/27/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BButton.h"

extern const CGFloat kStartViewHeight;
extern const CGFloat kStartViewWidth;

typedef NS_ENUM(NSUInteger, ADStartViewState) {
  ADStartViewStateReady,
  ADStartViewStateCountdown
};

@interface ADStartView : UIView

@property (nonatomic, assign) ADStartViewState state;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) BButton *startButton;
@property (nonatomic, strong) BButton *cancelButton;

@end
