//
//  ADLoginViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/14/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADLoginViewController.h"
#import "BButton.h"

@interface ADLoginViewController ()

@end

@implementation ADLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self setupButtons];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)loginButtonPressed:(BButton *)sender {
}

- (IBAction)loginWithFacebookButtonPressed:(BButton *)sender {
}

- (IBAction)signUpButtonPressed:(BButton *)sender {
}

- (void)setupButtons
{
    // Setup the login button
    CGRect rect1 = self.loginButton.frame;
    [self.loginButton removeFromSuperview];
    BButton *loginButton = [[BButton alloc] initWithFrame:rect1 type:BButtonTypePrimary style:BButtonStyleBootstrapV3];
    [loginButton setTitle:@"Login" forState:UIControlStateNormal];
    // [login addTarget:self action:@selector(armDrone:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:loginButton];
    
    // Setup the facebook button
    CGRect rect2 = self.facebookButton.frame;
    [self.facebookButton removeFromSuperview];
    BButton *facebookButton = [[BButton alloc] initWithFrame:rect2 type:BButtonTypeFacebook style:BButtonStyleBootstrapV3];
    [facebookButton setTitle:@"Login using Facebook" forState:UIControlStateNormal];
    // [login addTarget:self action:@selector(armDrone:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:facebookButton];
}

@end
