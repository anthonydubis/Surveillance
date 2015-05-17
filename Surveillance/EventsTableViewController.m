//
//  EventsTableViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/3/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "EventsTableViewController.h"
#import "DetailEventViewController.h"

// Core Data Related
#import "AppDelegate.h"
#import "MonitoringEvent+AD.h"

@interface EventsTableViewController ()

@property (nonatomic, strong) NSMutableArray *events;
@property (nonatomic, strong) AppDelegate *appDelegate;

@end

@implementation EventsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Refresh the events array and reload the tableView
- (void)reloadData
{
    self.events = nil;
    [self.tableView reloadData];
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"DetailEvent" sender:indexPath];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"DetailEvent"]) {
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        MonitoringEvent *event = [self.events objectAtIndex:indexPath.row];
        DetailEventViewController *devc = segue.destinationViewController;
        devc.event = event;
    }
}

// Allow deletations
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        MonitoringEvent *event = [self.events objectAtIndex:indexPath.row];
        [self.events removeObjectAtIndex:indexPath.row];
        [self.appDelegate.managedObjectContext deleteObject:event];
        [self.appDelegate saveContext];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - Getters/Setters

- (NSMutableArray *)events
{
    if (!_events) {
        _events = [[MonitoringEvent eventsInContext:self.appDelegate.managedObjectContext orderedByDateAscd:NO] mutableCopy];
    }
    return _events;
}

- (AppDelegate *)appDelegate
{
    return [[UIApplication sharedApplication] delegate];
}

@end
