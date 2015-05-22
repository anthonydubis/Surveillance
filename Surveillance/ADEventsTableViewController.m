//
//  ADEventsTableViewController.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/16/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADEventsTableViewController.h"
#import "ADEvent.h"
#import "ADFileHelper.h"
#import "ACPDownloadView.h"
#import "ADS3Helper.h"
#import <AWSS3/AWSS3.h>
#import "ADDetailEventViewController.h"
#import "ADDownloadTask.h"

@interface ADEventsTableViewController () <EventAndVideoDeletionDeletionDelegate>

// A dictionary containing the current download progress of remote videos
@property (nonatomic, strong) NSMutableDictionary *downloading;

@end

@implementation ADEventsTableViewController

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // Customize the table
        self.parseClassName = [ADEvent parseClassName];
        self.pullToRefreshEnabled = YES;
        self.paginationEnabled = NO;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)objectsDidLoad:(nullable NSError *)error
{
    [super objectsDidLoad:error];
    NSLog(@"Objects did load");
}

- (void)objectsWillLoad
{
    [super objectsWillLoad];
    NSLog(@"Objects will load");
}

- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    
    [query orderByDescending:@"createdAt"];
    
    return query;
}

#pragma mark - TableView delegate methods

#define CELL_HEIGHT 55.0;

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Captured Events";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    ADEvent *event = (ADEvent *)[self objectAtIndexPath:indexPath];
    cell.textLabel.text = [NSDateFormatter localizedStringFromDate:event.startedRecordingAt
                                                         dateStyle:NSDateFormatterMediumStyle
                                                         timeStyle:NSDateFormatterMediumStyle];
    
    // Set the accessory view
    if (self.downloading[event.videoName])
    {
        NSLog(@"The task is running");
        // We are downloading the video - this check must come first because a partially downloaded file
        // will cause the haveDownloadedVideoForEvent method to come true
        ADDownloadTask *progress = self.downloading[event.videoName];
        cell.detailTextLabel.text = [progress downloadProgressString];
        if ([cell.accessoryView isKindOfClass:[ACPDownloadView class]]) {
            ACPDownloadView *downloadView = (ACPDownloadView *)cell.accessoryView;
            if (downloadView.currentStatus == ACPDownloadStatusRunning)
                [self configureDownloadView:downloadView forDownloadingEvent:event];
            else
                [downloadView setIndicatorStatus:ACPDownloadStatusRunning];
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.accessoryView = [self accessoryViewForIndexPath:indexPath];
        }
    }
    else if ([ADFileHelper haveDownloadedVideoForEvent:event])
    {
        // We already have the video
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text = [event descriptionOfMetadata];
    }
    else
    {
        // The video has not been downloaded yet
        cell.accessoryView = [self accessoryViewForIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.text = [event descriptionOfMetadata];
    }
}

- (void)configureDownloadView:(ACPDownloadView *)downloadView forDownloadingEvent:(ADEvent *)event
{
    ADDownloadTask *progress = self.downloading[event.videoName];
    [downloadView setProgress:[progress percentageDownloaded] animated:YES];
}

#define ACCESSORY_SIZE 35.0

- (UIView *)accessoryViewForIndexPath:(NSIndexPath *)indexPath
{
    ADEvent *event = (ADEvent *)[self objectAtIndexPath:indexPath];
    
    // Create the accessory view
    ACPDownloadView *accessoryView = [[ACPDownloadView alloc] initWithFrame:CGRectMake(0, 0, ACCESSORY_SIZE, ACCESSORY_SIZE)];
    accessoryView.backgroundColor = [UIColor clearColor];
    
    // Set it's progress so far
    ADDownloadTask *progress = self.downloading[event.videoName];
    if (progress) {
        [accessoryView setIndicatorStatus:ACPDownloadStatusRunning];
        [accessoryView setProgress:[progress percentageDownloaded] animated:YES];
    } else {
        [accessoryView setIndicatorStatus:ACPDownloadStatusNone];
        [accessoryView setProgress:0.0 animated:NO];
    }
    
    // Set it's action block to handle taps
    [accessoryView setActionForTap:^(ACPDownloadView *downloadView, ACPDownloadStatus status){
        switch (status) {
            case ACPDownloadStatusNone:
                [downloadView setIndicatorStatus:ACPDownloadStatusRunning];
                [self downloadVideoForEvent:event];
                break;
            case ACPDownloadStatusRunning:
                // Cancel the download
#warning There was a sporadic conflict around trying to delete when a "write operation" was occuring...can't reproduce
                [self cancelDownloadForEvent:event];
                [downloadView setIndicatorStatus:ACPDownloadStatusNone];
                break;
            default:
                break;
        }
    }];
    return accessoryView;
}

- (void)cancelDownloadForEvent:(ADEvent *)event
{
    ADDownloadTask *task = self.downloading[event.videoName];
    if (task) {
        [[task.downloadRequest cancel] continueWithBlock:^id(BFTask *task) {
            if (task.error) {
                NSLog(@"Error: %@",task.error);
            } else {
                // Only after a successful cancellation do this work
                NSIndexPath *indexPath = [self indexPathForEvent:event];
                if ([ADFileHelper haveDownloadedVideoForEvent:event]) {
                    [ADFileHelper removeLocalCopyOfVideoForEvent:event];
                } 
                [self.downloading removeObjectForKey:event.videoName];
                [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            }
            return nil;
        }];
    }
}

#pragma mark - TableView delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ADEvent *event = (ADEvent *)[self objectAtIndexPath:indexPath];
    if (self.downloading[event.videoName]) {
        // The video is currently being downloaded - do nothing
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if ([ADFileHelper haveDownloadedVideoForEvent:event]) {
        // Video is downloaded
        [self performSegueWithIdentifier:@"DetailEventSegue" sender:indexPath];
    } else {
        // Video hasn't been downloaded yet
        [UIActionSheet showFromTabBar:self.tabBarController.tabBar
                            withTitle:nil
                    cancelButtonTitle:@"Cancel"
               destructiveButtonTitle:@"Permanently Delete Video"
                    otherButtonTitles:@[@"Download Video"]
                             tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                 if (buttonIndex == actionSheet.cancelButtonIndex) {
                                     [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                                 } else if (buttonIndex == actionSheet.destructiveButtonIndex) {
                                     [self promptUserToConfirmPermanentDeletion:event];
                                 } else {
                                     [self promptUserToConfirmDownloadingVideo:event];
                                 }
                             }];
    }
}

#warning You need to clean up these deletion methods - possibly toss them in a helper class
- (void)promptUserToConfirmPermanentDeletion:(ADEvent *)event
{
    [UIAlertView showWithTitle:@"Permanently Delete Video"
                       message:@"Are you sure you want to permanently delete this event? This cannot be undone."
             cancelButtonTitle:@"Cancel"
             otherButtonTitles:@[@"Yes"]
                      tapBlock:^(UIAlertView *actionSheet, NSInteger buttonIndex) {
                          if (buttonIndex != actionSheet.cancelButtonIndex) {
#warning Show that you're doing work (like an activity indicator
                              [ADS3Helper deleteVideoForEvent:event withCompletionBlock:^{
                                  [self removeLocalCopyAndDeleteParseObject:event];
                              }];
                          }
                          [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
                      }];
}

- (void)removeLocalCopyAndDeleteParseObject:(ADEvent *)event
{
    NSLog(@"Removing local copies");
    [ADFileHelper removeLocalCopyOfVideoForEvent:event];
#warning Do I need to block for this deletion to ensure that ADEventsTVC's query does not fetch it before it's removed from the parse server?
    // If you just called deleteInBackground then loadObjects, there's no guarentee that the object will be deleted before the query
    // Using the block helps ensure this but you need to handle what happens when it doesn't succeed
    [event deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [self loadObjects];
        } else {
            [UIAlertView showWithTitle:nil message:@"Deletion failed..." cancelButtonTitle:@"OK" otherButtonTitles:nil tapBlock:nil];
        }
    }];
}

- (void)promptUserToConfirmDownloadingVideo:(ADEvent *)event
{
    [UIAlertView showWithTitle:@"Download Video"
                       message:[NSString stringWithFormat:@"Are you sure you would like to download this %@ video to your device?", [event sizeString]]
             cancelButtonTitle:@"No"
             otherButtonTitles:@[@"Yes"]
                      tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                          if (buttonIndex != [alertView cancelButtonIndex]) {
                              [self downloadVideoForEvent:event];
                          }
                          [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
                      }
     ];
}

- (void)downloadVideoForEvent:(ADEvent *)event
{
    // Handle the case where the event was previously paused
    ADDownloadTask *task = self.downloading[event.videoName];
    if (task.downloadRequest.state == AWSS3TransferManagerRequestStatePaused) {
        [[AWSS3TransferManager defaultS3TransferManager] download:task.downloadRequest];
        return;
    }
    
    NSURL *url = [NSURL fileURLWithPath:[[ADFileHelper downloadsDirectoryPath] stringByAppendingPathComponent:event.videoName]];
    
    // Create the download request
    AWSS3TransferManagerDownloadRequest *downloadRequest = [ADS3Helper downloadRequestForEvent:event andDownloadURL:url];
    
    // Construct the completion block
    id (^handler)(BFTask *task) = ^id(BFTask *task) {
        if (task.error){
            if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
                switch (task.error.code) {
                    case AWSS3TransferManagerErrorCancelled:
                    case AWSS3TransferManagerErrorPaused:
                        break;
                    default:
                        NSLog(@"Error: %@", task.error);
                        break;
                }
            } else {
                // Unknown error.
                NSLog(@"Error: %@", task.error);
            }
        }
        
        if (task.result) {
            //File downloaded successfully.
            NSLog(@"File downloaded successfully");
            [self videoWasDownloadedForEvent:event];
        }
        return nil;
    };
    
    // Set the progress blocks
    __weak ADEventsTableViewController *weakSelf = self;
    downloadRequest.downloadProgress = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        ADDownloadTask *progress = weakSelf.downloading[event.videoName];
        if ([progress secondsSinceLastUpdate] >= 1) {
            progress.bytesDownloaded = [NSNumber numberWithLongLong:totalBytesWritten];
            progress.lastUpdate = [NSDate date];
            self.downloading[event.videoName] = progress;
            dispatch_async(dispatch_get_main_queue(), ^{
                NSIndexPath *indexPath = [weakSelf indexPathForEvent:event];
                if ([weakSelf isIndexPathVisible:indexPath]) {
                    [weakSelf configureCell:[weakSelf.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
                }
            });
        }
    };
    
    // Create the ADDownloadEvent
    self.downloading[event.videoName] = [[ADDownloadTask alloc] initWithDownloadRequest:downloadRequest andBytesToBeDownloaded:event.videoSize];
    
    // Start the process with the transfer manager
    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    [[transferManager download:downloadRequest] continueWithExecutor:[BFExecutor mainThreadExecutor]
                                                           withBlock:handler];
    
    // This updates the ACPDownloadView when the user calls this method by selecting the row rather than the accessory button
    NSIndexPath *indexPath = [self indexPathForEvent:event];
    [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
}

- (BOOL)isIndexPathVisible:(NSIndexPath *)indexPath
{
    return [[self.tableView indexPathsForVisibleRows] containsObject:indexPath];
}

#warning There are going to be a lot of "what if" scenarios around these downloads (lossed network, user deletes video, etc.)

- (void)videoWasDownloadedForEvent:(ADEvent *)event
{
#warning What if this object was deleted while we were off doing the downloading?
    NSIndexPath *indexPath = [self indexPathForEvent:event];
    [self.downloading removeObjectForKey:event.videoName];
    [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
}

- (NSIndexPath *)indexPathForEvent:(ADEvent *)event
{
    NSUInteger row = [[self objects] indexOfObject:event];
    return [NSIndexPath indexPathForRow:row inSection:0];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"DetailEventSegue"]) {
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        ADDetailEventViewController *detailEventVC = segue.destinationViewController;
        detailEventVC.event = (ADEvent *)[self objectAtIndexPath:indexPath];
        detailEventVC.delegate = self;
    }
}

#pragma mark - EventAndVideoDeletionDelegate methods

- (void)didDeleteLocalVideoForEvent:(ADEvent *)event
{
    [self.tableView reloadData];
}

- (void)didPermanentlyDeleteEvent:(ADEvent *)event
{
    [self loadObjects];
}

#pragma mark - Getters and Setters

// Holds an NSDate for the last time the download progress for an Event is updated
// The keys are the videoName of ADEvents, which are unique for a user
- (NSMutableDictionary *)downloading
{
    if (!_downloading) {
        _downloading = [[NSMutableDictionary alloc] init];
    }
    return _downloading;
}

@end
