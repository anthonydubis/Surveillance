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
{
  NSMutableArray *_events; // of ADEvents
}

// A dictionary containing the current download progress of remote videos
@property (nonatomic, strong) NSMutableDictionary *downloading;

@end

@implementation ADEventsTableViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.refreshControl = [[UIRefreshControl alloc] init];
  self.refreshControl.backgroundColor = [UIColor colorWithRed:97/255.0 green:106/255.0 blue:116/255.0 alpha:1.0];
  self.refreshControl.tintColor = [UIColor whiteColor];
  [self.refreshControl addTarget:self action:@selector(_loadEvents) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self _loadEvents];
  
  [ADFileHelper listAllFilesAtToUploadDirectory];
  [ADFileHelper listAllFilesInDownloadsDirectory];
  [ADFileHelper listAllFilesInDownloadsTemporaryDirectory];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
}

#pragma mark - Loading Events

- (void)_loadEvents
{
  [self.refreshControl beginRefreshing];
  
  // Fetch from the local datastore first
  PFQuery *query = [self _queryForTableFromNetwork];
  [query fromLocalDatastore];
  [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task) {
    if (task.error) {
#warning LAUNCH BLOCKER you should probably remove this
      // Since this is the success block, this should never happen - you can remove it after testing
      NSAssert(false, @"Error querying the local datastore");
      NSLog(@"Error: %@", task.error);
    } else {
      _events = [task.result mutableCopy];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.tableView reloadData];
    });
    [self _loadEventsFromNetwork];
    return task;
  }];
}

- (void)_loadEventsFromNetwork
{
  PFQuery *query = [self _queryForTableFromNetwork];
  [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task) {
    if (task.error) {
      NSLog(@"Error: %@", task.error);
      dispatch_async(dispatch_get_main_queue(), ^{
        [self _alertUserOfFailureToFetchData];
        [self _stopRefreshingWithError:YES];
      });
      return task;
    } else {
      // Update the view
      _events = [task.result mutableCopy];
      dispatch_async(dispatch_get_main_queue(), ^{
        [self _stopRefreshingWithError:NO];
        [self.tableView reloadData];
      });
      [ADFileHelper removeDownloadsNotAssociatedWithEvents:task.result];
      // Cache the results
      return [[PFObject unpinAllObjectsInBackgroundWithName:ADParseMyEventsCacheLabel] continueWithSuccessBlock:^id(BFTask *ignored) {
        return [PFObject pinAllInBackground:_events withName:ADParseMyEventsCacheLabel];
      }];
    }
  }];
}

- (void)_alertUserOfFailureToFetchData
{
  UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Unable to Fetch Data"
                                               message:@"Something went wrong connecting to the network. Please make sure you have an internet connection and try again."
                                              delegate:nil
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
  [av show];
}

- (void)_alertUserOfFailureToDownloadVideo
{
  UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Download Failed"
                                               message:@"There was an issue downloading the video. Please make sure you have an internet connection and try again."
                                              delegate:nil
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
  [av show];
}

- (void)_stopRefreshingWithError:(BOOL)error
{
  if (self.refreshControl) {
    if (!error) {
      NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
      [formatter setDateFormat:@"MMM d, h:mm a"];
      NSString *title = [NSString stringWithFormat:@"Last update: %@", [formatter stringFromDate:[NSDate date]]];
      NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                  forKey:NSForegroundColorAttributeName];
      NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
      self.refreshControl.attributedTitle = attributedTitle;
    }
    
    [self.refreshControl endRefreshing];
  }
}

- (PFQuery *)_queryForTableFromNetwork
{
  PFQuery *query = [PFQuery queryWithClassName:[ADEvent parseClassName]];
  [query orderByDescending:@"createdAt"];
  
  return query;
}

#pragma mark - TableView delegate methods

#define CELL_HEIGHT 55.0;

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return _events.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  NSInteger numSections = 0;
  
  if (_events.count) {
    tableView.backgroundView = nil;
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    numSections = 1;
  } else {
    // Display a message when the table is empty
    if (tableView.backgroundView == nil) {
      CGFloat m = 40;
      UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(m/2, 0, self.view.bounds.size.width-m, self.view.bounds.size.height)];
      
      messageLabel.text = @"Your cameras have not captured any events. Please pull down to refresh.";
      messageLabel.textColor = [UIColor blackColor];
      messageLabel.numberOfLines = 0;
      messageLabel.textAlignment = NSTextAlignmentCenter;
      messageLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
      [messageLabel sizeToFit];
      
      self.tableView.backgroundView = messageLabel;
      self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
  }
  
  return numSections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  return (_events.count) ? @"Captured Events" : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
  [self configureCell:cell atIndexPath:indexPath];
  return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
  ADEvent *event = [_events objectAtIndex:indexPath.row];
  cell.textLabel.text = [NSDateFormatter localizedStringFromDate:event.startedRecordingAt
                                                       dateStyle:NSDateFormatterMediumStyle
                                                       timeStyle:NSDateFormatterMediumStyle];
  
  // Set the accessory view
  if (self.downloading[event.videoName])
  {
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
    if ([event.status isEqualToString:EventStatusUploaded]) {
      // The video has been uploaded to the server
      cell.accessoryView = [self accessoryViewForIndexPath:indexPath];
      cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
      // The video is still recording or being uploaded
      cell.accessoryView = nil;
      cell.accessoryType = UITableViewCellAccessoryDetailButton;
    }
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
  ADEvent *event = [_events objectAtIndex:indexPath.row];
  
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
        [self.downloading removeObjectForKey:event.videoName];
        [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
      }
      return nil;
    }];
  }
}

#pragma mark - TableView delegate methods

// This is only called when the user taps an accessoryButton for an event that is still recording or is being uploaded to the server
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
  [tableView.delegate tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  ADEvent *event = [_events objectAtIndex:indexPath.row];
  if (self.downloading[event.videoName]) {
    // The video is currently being downloaded - do nothing
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
  } else if ([ADFileHelper haveDownloadedVideoForEvent:event]) {
    // Video is downloaded
    [self performSegueWithIdentifier:@"DetailEventSegue" sender:indexPath];
  } else if ([event.status isEqualToString:EventStatusUploaded]) {
    // The video has been uploaded to S3 but has not been downloaded to this device
    [self promptUserToDownloadEvent:event atIndexPath:indexPath];
  } else if ([event.status isEqualToString:EventStatusRecording]) {
    // The video is still recording
    [UIAlertView showWithTitle:@"Video is still Recording"
                    andMessage:@"You can download the video when it has stopped recording and has been uploaded to the server."];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
  } else if ([event.status isEqualToString:EventStatusUploading]) {
    [UIAlertView showWithTitle:@"Video is still Uploading"
                    andMessage:@"You can download the video when it has finished uploading to the server. Make sure the device that recorded the video is on has the Surveillance app open."];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
  }
}

- (void)promptUserToDownloadEvent:(ADEvent *)event atIndexPath:(NSIndexPath *)indexPath
{
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
                           [self downloadVideoForEvent:event];
                           [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
                         }
                       }];
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
#warning Show that you're doing work (like an activity indicator) - and you need an error block
                        [ADS3Helper deleteVideoForEvent:event withSuccessBlock:^{
                          [self removeLocalCopyAndDeleteParseObject:event];
                        }];
                      }
                      [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
                    }];
}

// The video should already be removed from the S3 bucket by the time this is called
- (void)removeLocalCopyAndDeleteParseObject:(ADEvent *)event
{
  [ADFileHelper removeLocalCopyOfVideoForEvent:event];
  [event deleteEventually];
  
  NSIndexPath *indexPath = [self indexPathForEvent:event];
  [_events removeObject:event];
  [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)downloadVideoForEvent:(ADEvent *)event
{
  // Weak self for use in blocks
  __weak ADEventsTableViewController *weakSelf = self;
  
  // Handle the case where the event was previously paused
  ADDownloadTask *task = self.downloading[event.videoName];
  if (task.downloadRequest.state == AWSS3TransferManagerRequestStatePaused) {
    [[AWSS3TransferManager defaultS3TransferManager] download:task.downloadRequest];
    return;
  }
  
  // Construct the completion block
  id (^handler)(BFTask *task) = ^id(BFTask *task) {
    if (task.error) {
      if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
        switch (task.error.code) {
          case AWSS3TransferManagerErrorCancelled:
          case AWSS3TransferManagerErrorPaused:
            break;
          default:
            [self _alertUserOfFailureToDownloadVideo];
            break;
        }
        [weakSelf downloadAttemptFinishedForEvent:event];
      } else {
        // Unknown error - likely a lack of internet connection
        [weakSelf _alertUserOfFailureToDownloadVideo];
        [weakSelf downloadAttemptFinishedForEvent:event];
      }
    } else if (task.result) {
      //File downloaded successfully.
      NSLog(@"File downloaded successfully");
      [weakSelf downloadAttemptFinishedForEvent:event];
    }
    return nil;
  };
  
  // Set the progress blocks
  AWSNetworkingDownloadProgressBlock progressBlock = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
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
  
  AWSS3TransferManagerDownloadRequest *request = [ADS3Helper downloadVideoForEvent:event completionBlock:handler progressBlock:progressBlock];
  
  // Create the ADDownloadEvent
  self.downloading[event.videoName] = [[ADDownloadTask alloc] initWithDownloadRequest:request andBytesToBeDownloaded:event.videoSize];
  
  // This updates the ACPDownloadView when the user calls this method by selecting the row rather than the accessory button
  NSIndexPath *indexPath = [self indexPathForEvent:event];
  [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
}

- (BOOL)isIndexPathVisible:(NSIndexPath *)indexPath
{
  return [[self.tableView indexPathsForVisibleRows] containsObject:indexPath];
}

- (void)downloadAttemptFinishedForEvent:(ADEvent *)event
{
  NSIndexPath *indexPath = [self indexPathForEvent:event];
  [self.downloading removeObjectForKey:event.videoName];
  [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
}

- (NSIndexPath *)indexPathForEvent:(ADEvent *)event
{
  NSUInteger row = [_events indexOfObject:event];
  return [NSIndexPath indexPathForRow:row inSection:0];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([segue.identifier isEqualToString:@"DetailEventSegue"]) {
    NSIndexPath *indexPath = (NSIndexPath *)sender;
    ADDetailEventViewController *detailEventVC = segue.destinationViewController;
    detailEventVC.event = [_events objectAtIndex:indexPath.row];
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
  [_events removeObject:event];
  [self.tableView reloadData];
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
