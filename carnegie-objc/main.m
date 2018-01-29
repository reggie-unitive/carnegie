//
//  main.m
//  carnegie-objc
//
//  Created by Reggie Seagraves on 1/22/18.
//  Copyright © 2018 Reggie Seagraves. All rights reserved.
//

// Please note that as this code wants to be used in a mobile environment, we are using the NSDowloadsDirectory to do our work.

#import <TRVSURLSessionOperation/TRVSURLSessionOperation.h>

void fileAppendData(NSURL* targetFileURL, NSData* data) {
  NSString* filePath = [targetFileURL path];
  NSFileHandle* fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
  if (fileHandle) {
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:data];
    [fileHandle closeFile];
  } else {
    [data writeToFile:filePath atomically:YES];
  }
}

void download(NSURL* url, int parts, int size, NSString* filename) {
  // delete our specified output file
  NSURL* documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDownloadsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
  NSURL* targetFileURL = [documentsDirectoryURL URLByAppendingPathComponent:filename];
  [[NSFileManager defaultManager] removeItemAtURL:targetFileURL error:nil];

  // the queue is intially parallel with no restrictions
  NSOperationQueue* queue = [[NSOperationQueue alloc] init];
  // create a url session
  NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];

  // create and queue up background tasks to download parts to temporary files and wait for all downloads to complete
  for (int i = 0; i < parts; ++i) {
    // set up url request
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    NSString* bytesString = [NSString stringWithFormat:@"bytes=%d-%d", i * size, (i + 1) * size - 1];
    [request addValue:bytesString forHTTPHeaderField:@"Range"];
    // construct an operation and add it to the queue
    [queue addOperation:[[TRVSURLSessionOperation alloc] initWithSession:session request:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
      NSURL* resultURL = [documentsDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", filename, bytesString]];
      NSLog(@"resultURL %@", resultURL);
      [data writeToURL:resultURL atomically:YES];
    }]];
  }
  [queue waitUntilAllOperationsAreFinished];
  NSLog(@"All download requests are complete, merging and deleting temporary files!");
  // Now, let's merge all our temporary files and delete them
  for (int i = 0; i < parts; ++i) {
    NSString* bytesString = [NSString stringWithFormat:@"bytes=%d-%d", i * size, (i + 1) * size - 1];
    NSURL* resultURL = [documentsDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", filename, bytesString]];
    NSData* data = [NSData dataWithContentsOfURL:resultURL];
    fileAppendData(targetFileURL, data);
    [[NSFileManager defaultManager] removeItemAtURL:resultURL error:nil];
  }
}

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    NSString* urlString = @"http://a15cc616.bwtest-aws.pravala.com/384MB.jar";
    NSString* outputFilenameString = @"carnegie-objc-output";
    if (argc == 2) {
      urlString = [NSString stringWithFormat:@"%s", argv[1]];
    } else if (argc == 3) {
      urlString = [NSString stringWithFormat:@"%s", argv[1]];
      outputFilenameString = [NSString stringWithFormat:@"%s", argv[2]];
    } else if (argc != 1) {
      NSLog(@"%@", [NSString stringWithFormat:@"usage %s <urlstring> [<filename>]", argv[0]]);
      return -1;
    }
    NSLog(@"donwloading url %@ to %@", urlString, outputFilenameString);
    NSURL* url = [NSURL URLWithString:urlString];
    download(url, 4, 1 * 1024 * 1024, outputFilenameString);
  }
  return 0;
}
