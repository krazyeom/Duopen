//
//  AppDelegate.h
//  Duopen
//
//  Created by Steve Yeom on 8/29/14.
//  Copyright (c) 2014 2nd Jobs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>
{
	NSMenuItem *systemMenu;
}

@property (assign) IBOutlet NSWindow *window;

@end
