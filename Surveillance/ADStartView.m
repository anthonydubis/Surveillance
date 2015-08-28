//
//  ADStartView.m
//  Surveillance
//
//  Created by Anthony Dubis on 8/27/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADStartView.h"

// Public
const CGFloat kStartViewHeight = 160.0;
const CGFloat kStartViewWidth = 280.0;

// Private
const CGFloat kButtonHeight = 45.0;
const CGFloat kMargin = 15.0;

@implementation ADStartView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    self.state = ADStartViewStateReady;
    
    self.backgroundColor = [UIColor lightGrayColor];
    self.layer.cornerRadius = 10;
    self.alpha = 0.85;
    
    // Create the label
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.titleLabel.numberOfLines = 0;
    
    // Create the buttons
    BButtonType buttonType = BButtonTypePrimary;
    self.startButton = [[BButton alloc] initWithFrame:CGRectZero
                                                 type:buttonType
                                                style:BButtonStyleBootstrapV3];
    self.cancelButton = [[BButton alloc] initWithFrame:CGRectZero
                                                  type:buttonType
                                                 style:BButtonStyleBootstrapV3];
    
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.startButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:self.titleLabel];
    [self addSubview:self.startButton];
    [self addSubview:self.cancelButton];
    
    [self configureConstraints];
  }
  return self;
}

- (void)configureConstraints
{
  NSDictionary *views = @{
                          @"titleLabel" : self.titleLabel,
                          @"cancelButton" : self.cancelButton,
                          @"startButton" : self.startButton
                          };
  NSDictionary *metrics = @{
                            @"margin" : @(kMargin)
                            };
  
  [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-margin-[titleLabel]-margin-|"
                                                              options:0
                                                              metrics:metrics
                                                                views:views]];
  [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-margin-[cancelButton]-margin-[startButton]-margin-|"
                                                               options:0
                                                               metrics:metrics
                                                                 views:views]];
  [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[titleLabel]-margin-[cancelButton]-margin-|"
                                                               options:0
                                                               metrics:metrics
                                                                 views:views]];
  
  // Specify the button heights
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_startButton
                                                   attribute:NSLayoutAttributeHeight
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:nil
                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                  multiplier:0
                                                    constant:kButtonHeight]];
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_cancelButton
                                                   attribute:NSLayoutAttributeHeight
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:nil
                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                  multiplier:0
                                                    constant:kButtonHeight]];
  
  // Specify button widths
  [self addConstraint:[NSLayoutConstraint constraintWithItem:self.startButton
                                                   attribute:NSLayoutAttributeWidth
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:self.cancelButton
                                                   attribute:NSLayoutAttributeWidth
                                                  multiplier:1.0
                                                    constant:0]];
  
  // Align the buttons vertically
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_startButton
                                                   attribute:NSLayoutAttributeCenterY
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:_cancelButton
                                                   attribute:NSLayoutAttributeCenterY
                                                  multiplier:1.0 constant:0]];
}

- (void)setState:(ADStartViewState)state
{
  if (state == ADStartViewStateReady) {
    self.titleLabel.font = [UIFont systemFontOfSize:17.0];
    [self.startButton setType:BButtonTypePrimary];
  } else {
    self.titleLabel.font = [UIFont systemFontOfSize:30.0];
    [self.startButton setType:BButtonTypeDanger];
  }
}

@end
