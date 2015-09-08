//
//  ADDownloadProgress.m
//  Surveillance
//
//  Created by Anthony Dubis on 5/18/15.
//  Copyright (c) 2015 Anthony Dubis. All rights reserved.
//

#import "ADTransferTask.h"

@implementation ADTransferTask

+ (NSString *)sizeStringForBytes:(NSNumber *)bytesNum
{
  long long bytes = bytesNum.longLongValue;
  
  if (bytes < 1000)
    return [NSString stringWithFormat:@"%lli bytes", bytes];
  else if (bytes < 1000000)
    return [NSString stringWithFormat:@"%.1f KB", (float)bytes / 1000];
  else if (bytes < 1000000000)
    return [NSString stringWithFormat:@"%.1f MB", (float)bytes / 1000000];
  else
    return [NSString stringWithFormat:@"%.1f GB", (float)bytes / 1000000000];
}

- (id)init
{
  self = [super init];
  if (self) {
    self.bytesTransferred = [NSNumber numberWithInt:0];
    self.lastUpdate = [NSDate date];
  }
  return self;
}

- (id)initWithBytesToBeTransferred:(NSNumber *)bytes
{
  self = [self init];
  if (self) {
    self.bytesToBeTransferred = bytes;
  }
  return self;
}

- (id)initWithDownloadRequest:(AWSS3TransferManagerDownloadRequest *)request andBytesToBeDownloaded:(NSNumber *)bytes
{
  self = [self initWithBytesToBeTransferred:bytes];
  if (self) {
    self.downloadRequest = request;
  }
  return self;
}

- (int)secondsSinceLastUpdate
{
  return [[NSDate date] timeIntervalSinceDate:self.lastUpdate];
}

- (double)percentageTransferred
{
  if (!self.bytesToBeTransferred || !self.bytesTransferred) {
    return 0.0;
  } else {
    // Handle situations where pieces of a file need to be redownloaded, pushing percentage over 100%
    double percentage = self.bytesTransferred.doubleValue / self.bytesToBeTransferred.doubleValue;
    percentage = MIN(percentage, 1.0);
    
    return percentage;
  }
}

- (NSString *)downloadProgressString
{
  if (self.bytesToBeTransferred.longLongValue == 0)
    return @"Downloading...";
  
  double percentage = [self percentageTransferred];
  
  NSString *desc = [NSString stringWithFormat:@"Downloaded %@ of %@",
                    [ADTransferTask sizeStringForBytes:self.bytesTransferred],
                    [ADTransferTask sizeStringForBytes:self.bytesToBeTransferred]];
  NSString *pctStr = [NSString stringWithFormat:@", %.0f%%", percentage * 100];
  return [desc stringByAppendingString:pctStr];
}

- (NSString *)uploadProgressString
{
  if (self.bytesToBeTransferred.longLongValue == 0)
    return @"Uploading...";
  
  double percentage = [self percentageTransferred];
  
  NSString *desc = [NSString stringWithFormat:@"Uploaded %@ of %@",
                    [ADTransferTask sizeStringForBytes:self.bytesTransferred],
                    [ADTransferTask sizeStringForBytes:self.bytesToBeTransferred]];
  NSString *pctStr = [NSString stringWithFormat:@", %.0f%%", percentage * 100];
  return [desc stringByAppendingString:pctStr];
}

@end
