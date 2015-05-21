//
//  ADLoginViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/21/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADLoginViewController.h"

@interface ADLoginViewController ()

@end

@implementation ADLoginViewController

- (void)viewDidLoad {
    NSLog(@"View did load for login view controller was called");
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    UIImage *image = [UIImage imageNamed:@"logo"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    
    // logoView.contentMode = UIViewContentModeScaleAspectFit;
    self.logInView.logo = imageView; // logo can be any UIView
    
//    UILabel *logoLabel = [[UILabel alloc] init];
//    logoLabel.text = @"Surveillence";
//    self.logInView.logo = logoLabel;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    UIView *v = self.logInView.logo;
    NSLog(@"%f, %f, %f, %f", v.frame.origin.x, v.frame.origin.y, v.frame.size.width, v.frame.size.height);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
