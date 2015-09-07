//
//  AppDelegate.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/1/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import "ADS3Helper.h"
#import "ADNotificationHelper.h"
#import "ADImageViewController.h"
#import "ADLoginViewController.h"
#import "PFInstallation+ADDevice.h"

@interface AppDelegate () <PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Override point for customization after application launch.
  // Setup Parse first
  [self setupParseWithLaunchOptions:launchOptions];
  
  // Setup AWS
  [ADS3Helper setupAWSS3Service];
  [[ADS3Helper sharedInstance] uploadFilesIfNecessary];
  
  if (![PFUser currentUser]) {
    // No user is set - ask the user to login
    self.window.rootViewController = [self loginViewController];
  } else {
    // We have a user, let's setup the device and notifications
    [PFInstallation setupCurrentInstallation];
    [ADNotificationHelper setupNotifications];
  }
  
  // Handle notifications, if any exist
  NSDictionary *notificationPayload = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
  if (notificationPayload)
    [self handleNotification:notificationPayload whileActive:NO];
  
  return YES;
}

- (void)setupParseWithLaunchOptions:(NSDictionary *)launchOptions
{
  // [Optional] Power your app with Local Datastore. For more info, go to
  // https://parse.com/docs/ios_guide#localdatastore/iOS
  [Parse enableLocalDatastore];
  
  // Initialize Parse and Facebook
  [Parse setApplicationId:@"RsfKbEwIOCNz8cCYmESlj5hXIV89HFuZtuZ6Jj2f"
                clientKey:@"WvyRze50fd8hyuZ0NPxNAs5R9b1OPw5FvIyyBKX4"];
  [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];
  
  // Set default ACL so all objects created can only be read/written to by the current user
  [PFACL setDefaultACL:[PFACL ACL] withAccessForCurrentUser:YES];
  
  // [Optional] Track statistics around application opens.
  [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  // Store the deviceToken in the current installation and save it to Parse.
  NSLog(@"Application did register for remote notifications");
  [ADNotificationHelper didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)switchToRootViewController:(UIViewController *)toVC
{
  UIView *snapShot = [self.window snapshotViewAfterScreenUpdates:YES];
  
  [toVC.view addSubview:snapShot];
  
  self.window.rootViewController = toVC;
  
  [UIView animateWithDuration:0.5 animations:^{
    snapShot.layer.opacity = 0;
    snapShot.layer.transform = CATransform3DMakeScale(1.5, 1.5, 1.5);
  } completion:^(BOOL finished) {
    [snapShot removeFromSuperview];
  }];
  
}

- (void)showTabBarAsRootViewController
{
  UIViewController *tabBarVC = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
  if (!self.window.rootViewController) {
    self.window.rootViewController = tabBarVC;
    return;
  }
  
  [self switchToRootViewController:tabBarVC];
}

- (UITabBarController *)tabBarController
{
  if ([self.window.rootViewController isKindOfClass:[UITabBarController class]]) {
    return (UITabBarController *)self.window.rootViewController;
  } else {
    return [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
  }
}

#pragma mark - Handling user login

- (PFLogInViewController *)loginViewController
{
  // Create the loginVC
  PFLogInViewController *logInViewController = [[PFLogInViewController alloc] init];
  logInViewController.fields = PFLogInFieldsUsernameAndPassword | PFLogInFieldsLogInButton | PFLogInFieldsSignUpButton | PFLogInFieldsPasswordForgotten | PFLogInFieldsFacebook;
  logInViewController.emailAsUsername = YES;
  logInViewController.delegate = self;
  logInViewController.logInView.logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
  
  // Create the signUpVC
  PFSignUpViewController *signUpViewController = [[PFSignUpViewController alloc] init];
  signUpViewController.signUpView.logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
  signUpViewController.fields = PFSignUpFieldsUsernameAndPassword | PFSignUpFieldsSignUpButton;
  signUpViewController.emailAsUsername = YES;
  signUpViewController.delegate = self;
  [logInViewController setSignUpController:signUpViewController];
  
  return logInViewController;
}

// Sent to the delegate to determine whether the log in request should be submitted to the server.
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
  NSLog(@"Should begin login with user name");
  // Check if both fields are completed
  if (username && password && username.length != 0 && password.length != 0) {
    return YES; // Begin login process
  }
  
  [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                              message:@"Make sure you fill out all of the information!"
                             delegate:nil
                    cancelButtonTitle:@"OK"
                    otherButtonTitles:nil] show];
  return NO; // Interrupt login process
}

// Sent to the delegate when a PFUser is logged in.
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
  [PFInstallation setupCurrentInstallation];
  [ADNotificationHelper setupNotifications];
  [self showTabBarAsRootViewController];
}

// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
  NSLog(@"Failed to log in...");
}

// Sent to the delegate when the log in screen is dismissed.
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
  // For now, don't allow cancellations
  // [self showTabBarAsRootViewController];
}

#pragma mark - Handling Signup

// Sent to the delegate to determine whether the sign up request should be submitted to the server.
- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
  NSLog(@"Should begin sign up");
  BOOL informationComplete = YES;
  
  // loop through all of the submitted data
  for (id key in info) {
    NSString *field = [info objectForKey:key];
    if (!field || field.length == 0) { // check completion
      informationComplete = NO;
      break;
    }
  }
  
  // Display an alert if a field wasn't completed
  if (!informationComplete) {
    [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                message:@"Make sure you fill out all of the information!"
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
  }
  
  return informationComplete;
}

// Sent to the delegate when a PFUser is signed up.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
  [PFInstallation setupCurrentInstallation];
  [ADNotificationHelper setupNotifications];
  [self showTabBarAsRootViewController];
}

// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error {
  NSLog(@"Failed to sign up...");
}

// Sent to the delegate when the sign up screen is dismissed.
- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController {
  // For now, don't allow cancellations
  // [self showTabBarAsRootViewController];
}

#pragma mark - Log user out

- (void)userLoggedOut
{
  [self switchToRootViewController:[self loginViewController]];
}

#pragma mark - Push Notifications

// Handle notifications received while the app was opened
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
  NSLog(@"Did receive notification");
  [self handleNotification:userInfo whileActive:YES];
}

- (void)handleNotification:(NSDictionary *)userInfo whileActive:(BOOL)wasActive
{
  NSLog(@"Handling notification");
  NSDictionary *aps = userInfo[@"aps"];
  NSString *message = aps[@"alert"];
  if ([userInfo objectForKey:@"p"]) {
    // This is a face notification
    NSString *eventImageID = [userInfo objectForKey:@"p"];
    if (wasActive) {
      // Ask user if he wants to see the image
      [UIAlertView showWithTitle:nil
                         message:message
               cancelButtonTitle:@"No"
               otherButtonTitles:@[@"View Image"]
                        tapBlock:^(UIAlertView *av, NSInteger buttonIndex) {
                          if (buttonIndex != av.cancelButtonIndex) {
                            [self presentEventImageWithID:eventImageID];
                          }
                        }];
    } else {
      // Immediately show the image
      [self presentEventImageWithID:eventImageID];
    }
    
  } else if ([userInfo objectForKey:@"disable"]) {
#warning Use constants file!
    NSLog(@"It's a disable command");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DisableCameraNotification" object:nil];
  }else {
    [PFPush handlePush:userInfo];
  }
}

- (void)presentEventImageWithID:(NSString *)eventImageID
{
  PFObject *eventImage = [PFObject objectWithoutDataWithClassName:@"EventImage" objectId:eventImageID];
  
  // Fetch photo object
  [eventImage fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
    // Show photo view controller
    if (error) {
      // Error - perhaps the image was removed
    } else if ([PFUser currentUser]) {
      UINavigationController *navCon = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]]
                                        instantiateViewControllerWithIdentifier:@"ImageViewControllerNavCon"];
      ADImageViewController *imageVC = (ADImageViewController *)navCon.topViewController;
      imageVC.eventImage = (ADEventImage *)object;
      [self.window.rootViewController presentViewController:navCon animated:YES completion:nil];
    } else {
      //
    }
  }];
}

#pragma mark - App life cycle methods

- (void)applicationWillResignActive:(UIApplication *)application {
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  [[ADS3Helper sharedInstance] cancelAllRequests];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  [[ADS3Helper sharedInstance] uploadFilesIfNecessary];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
  return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                        openURL:url
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  [FBSDKAppEvents activateApp];
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  // Saves changes in the application's managed object context before the application terminates.
  [self saveContext];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
  // The directory the application uses to store the Core Data store file. This code uses a directory named "com.anthonydubis.Surveillance" in the application's documents directory.
  return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
  // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
  if (_managedObjectModel != nil) {
    return _managedObjectModel;
  }
  NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Surveillance" withExtension:@"momd"];
  _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
  return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
  // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
  if (_persistentStoreCoordinator != nil) {
    return _persistentStoreCoordinator;
  }
  
  // Create the coordinator and store
  NSDictionary *storeOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                                nil];
  
  _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
  NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Surveillance.sqlite"];
  NSError *error = nil;
  NSString *failureReason = @"There was an error creating or loading the application's saved data.";
  if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:storeOptions error:&error]) {
    // Report any error we got.
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
    dict[NSLocalizedFailureReasonErrorKey] = failureReason;
    dict[NSUnderlyingErrorKey] = error;
    error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
    // Replace this with code to handle the error appropriately.
    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    abort();
  }
  
  return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
  // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
  if (_managedObjectContext != nil) {
    return _managedObjectContext;
  }
  
  NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
  if (!coordinator) {
    return nil;
  }
  _managedObjectContext = [[NSManagedObjectContext alloc] init];
  [_managedObjectContext setPersistentStoreCoordinator:coordinator];
  return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
  NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
  if (managedObjectContext != nil) {
    NSError *error = nil;
    if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
      // Replace this implementation with code to handle the error appropriately.
      // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
    }
  }
}

@end
