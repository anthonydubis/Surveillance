//
//  EventsTableViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/3/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "EventsTableViewController.h"
#import <MediaPlayer/MediaPlayer.h>

// Core Data Related
#import "AppDelegate.h"
#import "MonitoringEvent+AD.h"

@interface EventsTableViewController ()

@property (nonatomic, strong) NSArray *events;
@property (nonatomic, strong) MPMoviePlayerController *moviePlayerController;

@end

@implementation EventsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadData];
}

// Refresh the events array and reload the tableView
- (void)reloadData
{
    self.events = nil;
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    if (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        [self.moviePlayerController.view setFrame:CGRectMake(0, 70, 320, 270)];
    } else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        [self.moviePlayerController.view setFrame:CGRectMake(0, 0, 480, 320)];
    }
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.events.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BasicCell" forIndexPath:indexPath];
    MonitoringEvent *event = [self.events objectAtIndex:indexPath.row];
    cell.textLabel.text = event.filename;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MonitoringEvent *event = [self.events objectAtIndex:indexPath.row];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:[NSString pathWithComponents:@[documentsPath, event.filename]]];
    [self showVideoAtURL:fileURL];
}

- (void)showVideoAtURL:(NSURL *)fileURL
{
    self.moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:fileURL];
    [self.moviePlayerController.view setFrame:CGRectMake(0, 70, 320, 270)];
    [self.view addSubview:self.moviePlayerController.view];
    self.moviePlayerController.fullscreen = YES;
    [self.moviePlayerController play];
}

#pragma mark - Getters/Setters

- (NSArray *)events
{
    if (!_events) {
        _events = [MonitoringEvent eventsInContext:self.appDelegate.managedObjectContext orderedByDateAscd:NO];
    }
    return _events;
}

- (AppDelegate *)appDelegate
{
    return [[UIApplication sharedApplication] delegate];
}

@end
