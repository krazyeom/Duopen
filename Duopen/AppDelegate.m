//
//  AppDelegate.m
//  Duopen
//
//  Created by Steve Yeom on 8/29/14.
//  Copyright (c) 2014 2nd Jobs. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  // Insert code here to initialize your application
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
  
  NSPipe *pipe = [NSPipe pipe];
  NSTask *task = [[NSTask alloc] init];
  
  task.launchPath = @"/usr/bin/open";
  task.arguments = @[@"-n", filename];
  task.standardOutput = pipe;

  [task launch];
  
  return YES;
}

@end
