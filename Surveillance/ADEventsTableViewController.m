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
#import "ADDownloadProgress.h"

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

    // With this commented out, the objects are loaded everything the view loads
    // We should eventually fetch from the local store first, then try the remote one
//    // If no objects are loaded in memory, we look to the cache
//    // first to fill the table and then subsequently do a query
//    // against the network.
//    if ([self.objects count] == 0) {
//        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
//    }
    
    [query orderByDescending:@"createdAt"];
    
    return query;
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
                                                         dateStyle:NSDateFormatterShortStyle
                                                         timeStyle:NSDateFormatterLongStyle];
    
    // Set the accessory view
    if (self.downloading[event.videoName])
    {
        // We are downloading the video - this check must come first because a partially downloaded file
        // will cause the haveDownloadedVideoForEvent method to come true
        NSLog(@"Downloading in progress");
        ADDownloadProgress *downloadProgress = self.downloading[event.videoName];
        cell.detailTextLabel.text = [event percentDownloadedStringForBytesReceived:downloadProgress.bytesDownloaded];
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        cell.accessoryView = activityIndicator;
        [activityIndicator startAnimating];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else if ([ADFileHelper haveDownloadedVideoForEvent:event])
    {
        NSLog(@"The filename exists");
        // We already have the video
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text = [event descriptionOfMetadata];
    }
    else
    {
        // The video has not been downloaded yet
        cell.accessoryView = [self cloudDownloadAccessoryButtonForIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.text = [event descriptionOfMetadata];
    }
}

#define CLOUD_ICON_SIZE 30.0

- (UIButton *)cloudDownloadAccessoryButtonForIndexPath:(NSIndexPath *)indexPath
{
    /*
    ADEvent *event = (ADEvent *)[self objectAtIndexPath:indexPath];
    ACPDownloadView *accessoryView = [[ACPDownloadView alloc] initWithFrame:CGRectMake(0, 0, CLOUD_ICON_SIZE, CLOUD_ICON_SIZE)];
    accessoryView.backgroundColor = [UIColor clearColor];
    [accessoryView setProgress:0.0 animated:NO];
    
    [accessoryView setActionForTap:^(ACPDownloadView *downloadView, ACPDownloadStatus status){
        switch (status) {
            case ACPDownloadStatusNone:
                [downloadView setProgress:[self.progress[event.videoName] floatValue] animated:YES];
                [downloadView setIndicatorStatus:ACPDownloadStatusRunning];
                break;
            case ACPDownloadStatusRunning:
                [downloadView setIndicatorStatus:ACPDownloadStatusNone];
                break;
            default:
                break;
        }
    }];
    
    return accessoryView;
     */
    // Create the button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setImage:[UIImage imageNamed:@"cloudDownload.png"] forState:UIControlStateNormal];
    [button setFrame:CGRectMake(0, 0, CLOUD_ICON_SIZE, CLOUD_ICON_SIZE)];
    
    // Set it's target
    [button addTarget:self action:@selector(cloudDownloadAccessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

#pragma mark - TableView delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ADEvent *event = (ADEvent *)[self objectAtIndexPath:indexPath];
    if ([ADFileHelper haveDownloadedVideoForEvent:event]) {
        [self performSegueWithIdentifier:@"DetailEventSegue" sender:indexPath];
    } else {
        NSLog(@"Video is not there.");
    }
}

- (void)cloudDownloadAccessoryButtonTapped:(UIButton *)button withEvent:(UIEvent *)event
{
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:self.tableView]];
    if (indexPath) {
        // Download the video
        ADEvent *event = (ADEvent *)[self objectAtIndexPath:indexPath];
        self.downloading[event.videoName] = [[ADDownloadProgress alloc] init];
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
            ADDownloadProgress *progress = weakSelf.downloading[event.videoName];
            if ([progress secondsSinceLastUpdate] >= 1) {
                progress.bytesDownloaded = [NSNumber numberWithLong:totalBytesWritten];
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
        
        // Start the process with the transfer manager
        AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
        [[transferManager download:downloadRequest] continueWithExecutor:[BFExecutor mainThreadExecutor]
                                                               withBlock:handler];
        
        
        
        
        /*
        __weak ADEventsTableViewController *weakSelf = self;
        [ADS3Helper downloadVideoForEvent:event toURL:(NSURL *)url withCompletionBlock:^{
            [weakSelf videoWasDownloadedForEvent:event];
        }];
         */
        [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
    }
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
    NSLog(@"Local vid was deleted for event: %@", event);
    [self.tableView reloadData];
}

- (void)didPermanentlyDeleteEvent:(ADEvent *)event
{
    NSLog(@"Event was permanently deleted: %@", event);
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
