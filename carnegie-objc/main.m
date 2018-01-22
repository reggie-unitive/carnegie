//
//  main.m
//  carnegie-objc
//
//  Created by Reggie Seagraves on 1/22/18.
//  Copyright © 2018 Reggie Seagraves. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <Foundation/Foundation.h>

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

static int sCurrentParts = -1;

void download(NSURL* url, int parts, int size, NSString* basename) {
  sCurrentParts = parts;
  NSURL* documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDownloadsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
  NSURL* targetFileURL = [documentsDirectoryURL URLByAppendingPathComponent:basename];
  [[NSFileManager defaultManager] removeItemAtURL:targetFileURL error:nil];
  for (int i = 0; i < parts; ++i) {
    @autoreleasepool {
      NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
      AFURLSessionManager* manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
      NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
      NSString* bytesString = [NSString stringWithFormat:@"bytes=%d-%d", i * size, (i + 1) * size - 1];
      [request addValue:bytesString forHTTPHeaderField:@"Range"];
      NSURLSessionDownloadTask* downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSString* filenameString = [NSString stringWithFormat:@"%@.%@", basename, bytesString];
        return [documentsDirectoryURL URLByAppendingPathComponent:filenameString];
      } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSData* fileData = [NSData dataWithContentsOfURL:filePath];
        fileAppendData(targetFileURL, fileData);
        [[NSFileManager defaultManager] removeItemAtURL:filePath error:nil];
        --sCurrentParts;
      }];
      [downloadTask resume];
    }
  }
  NSRunLoop *theRL = [NSRunLoop currentRunLoop];
  while (sCurrentParts != 0 && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
  NSLog(@"downloaded %@ to %@", url, [targetFileURL absoluteString]);
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
    } else {
      NSLog(@"%@", [NSString stringWithFormat:@"usage %s <urlstring> [<filename>]", argv[0]]);
      return -1;
    }
    NSURL* url = [NSURL URLWithString:urlString];
    download(url, 4, 1 * 1024 * 1024, outputFilenameString);
  }
  return 0;
}
