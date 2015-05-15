//
//  ADLoginViewController.h
//  Surveillance
//
//  Created by Anthony Dubis on 5/14/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BButton;

@interface ADLoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet BButton *loginButton;
@property (weak, nonatomic) IBOutlet BButton *facebookButton;
@property (weak, nonatomic) IBOutlet BButton *signUpButton;

- (IBAction)loginButtonPressed:(BButton *)sender;
- (IBAction)loginWithFacebookButtonPressed:(BButton *)sender;
- (IBAction)signUpButtonPressed:(BButton *)sender;
@end
