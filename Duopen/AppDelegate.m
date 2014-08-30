//
//  AppDelegate.m
//  Duopen
//
//  Created by Steve Yeom on 8/29/14.
//  Copyright (c) 2014 2nd Jobs. All rights reserved.
//

#import "AppDelegate.h"
#import <Carbon/Carbon.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[self registerAppInStatusBar];
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
  
  NSTask *task = [[NSTask alloc] init];
  
  task.launchPath = @"/usr/bin/open";
  task.arguments = @[@"-n", filename];

  [task launch];
  
  return YES;
}



#pragma mark Handling to start this app automatically at login.

- (BOOL) shouldStartAnilAppAtLogin
{
    Boolean foundIt = false;
    NSBundle *prefPaneBundle = [NSBundle mainBundle];
    NSString *pathToGHA   = [prefPaneBundle bundlePath ];
	
    if(pathToGHA)
	{
        //get the file url to GHA.
        CFURLRef urlToGHA = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)pathToGHA, kCFURLPOSIXPathStyle, true);
		
        UInt32 seed = 0U;
		LSSharedFileListRef loginItems = LSSharedFileListCreate(kCFAllocatorDefault, kLSSharedFileListSessionLoginItems, /*options*/ NULL);
        NSArray *currentLoginItems = (__bridge NSArray *)(LSSharedFileListCopySnapshot(loginItems, &seed));
        for (id itemObject in currentLoginItems)
		{
            LSSharedFileListItemRef item = (__bridge LSSharedFileListItemRef)itemObject;
			
            UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
            CFURLRef URL = NULL;
            OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
            if (err == noErr)
			{
                foundIt = CFEqual(URL, urlToGHA);
                CFRelease(URL);
				
                if (foundIt)
                    break;
            }
        }
		
        CFRelease(urlToGHA);
    }
	
    return foundIt;
}

- (void) setStartAtLogin:(NSString *)path enabled:(BOOL)enabled
{
    OSStatus status;
    CFURLRef URLToToggle = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    LSSharedFileListItemRef existingItem = NULL;
	
    UInt32 seed = 0U;
	LSSharedFileListRef loginItems = LSSharedFileListCreate(kCFAllocatorDefault, kLSSharedFileListSessionLoginItems, /*options*/ NULL);
    NSArray *currentLoginItems = (__bridge NSArray *)(LSSharedFileListCopySnapshot(loginItems, &seed));
    for (id itemObject in currentLoginItems)
	{
        LSSharedFileListItemRef item = (__bridge LSSharedFileListItemRef)itemObject;
		
        UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
        CFURLRef URL = NULL;
        OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
        if (err == noErr)
		{
            Boolean foundIt = CFEqual(URL, URLToToggle);
            CFRelease(URL);
			
            if (foundIt)
			{
                existingItem = item;
                break;
            }
        }
    }
	
    if (enabled && (existingItem == NULL))
	{
        NSString *displayName = [[NSFileManager defaultManager] displayNameAtPath:path];
        IconRef icon = NULL;
        FSRef ref;
        Boolean gotRef = CFURLGetFSRef(URLToToggle, &ref);
        if (gotRef) {
            status = GetIconRefFromFileInfo(&ref,
                                            /*fileNameLength*/ 0, /*fileName*/ NULL,
                                            kFSCatInfoNone, /*catalogInfo*/ NULL,
                                            kIconServicesNormalUsageFlag,
                                            &icon,
                                            /*outLabel*/ NULL);
            if (status != noErr)
                icon = NULL;
        }
		
        LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst, (__bridge CFStringRef)displayName, icon, URLToToggle, /*propertiesToSet*/ NULL, /*propertiesToClear*/ NULL);
    }
	else if (!enabled && (existingItem != NULL))
	{
        LSSharedFileListItemRemove(loginItems, existingItem);
	}
}

- (void) setShouldStartAnilAppAtLogin:(BOOL)flag
{
    //get the prefpane bundle and find GHA within it.
	
    //NSBundle *prefPaneBundle = [NSBundle bundleWithIdentifier:@"com.yourcompany.appname"];
    NSBundle *prefPaneBundle = [NSBundle mainBundle];
	
    NSString *pathToGHA   = [prefPaneBundle bundlePath ];
	
    [self setStartAtLogin:pathToGHA enabled:flag];
}


#pragma mark - process menu items

- (void)startAtLogin:(id)sender
{
	NSMenuItem *menuItem = (NSMenuItem *)sender;
	[self setShouldStartAnilAppAtLogin:menuItem.state == NSOffState ? YES : NO];
}

- (void)duOpen:(id)sender
{
	NSMenuItem *menuItem = (NSMenuItem *)sender;
	if(menuItem.tag == 0)
		return;
	
	NSWorkspace *workSpace = [NSWorkspace sharedWorkspace];
	NSArray *applications = [workSpace runningApplications];
	NSRunningApplication *app = [applications objectAtIndex:menuItem.tag];
	[workSpace launchApplicationAtURL:app.executableURL options:NSWorkspaceLaunchDefault | NSWorkspaceLaunchNewInstance configuration:nil error:nil];
}

- (void)menuWillOpen:(NSMenu *)menu
{
	if(_systemMenu != menu)
		return;
	
	[_systemMenu removeAllItems];
	
	NSWorkspace *workSpace = [NSWorkspace sharedWorkspace];
	NSArray *applications = [workSpace runningApplications];
	int n = 0;
	for(NSRunningApplication *app in applications)
	{
		// We should get only regular apps except Finder app and Duopen.app itself.
		if(	app.activationPolicy == NSApplicationActivationPolicyRegular &&		// should be regular
		   [app.executableURL.absoluteString rangeOfString:@"Finder.app"].location == NSNotFound &&	// shoud be not Finder app
		   ![app isEqualTo:[NSRunningApplication currentApplication]] )	// shoud be not Duopen app itself
		{
			NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:app.localizedName action:@selector(duOpen:) keyEquivalent:@""];
			menuItem.image = app.icon;
			menuItem.tag = n;
			[_systemMenu addItem:menuItem];
		}
		n++;
	}
	
	// Add "Start automatically" setting menu
	[_systemMenu addItem:[NSMenuItem separatorItem]];
	NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Start at login" action:@selector(startAtLogin:) keyEquivalent:@""];
	menuItem.state = [self shouldStartAnilAppAtLogin] ? NSOnState : NSOffState;
	[_systemMenu addItem:menuItem];
}

- (void)registerAppInStatusBar
{
	if(!_systemMenu)
		_systemMenu = [[NSMenu alloc] init];
	_systemMenu.delegate = self;
	
	NSStatusBar *bar = [NSStatusBar systemStatusBar];
    _statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
	[_statusItem setImage:[NSImage imageNamed:@"SystemAppIcon"]];
    [_statusItem setHighlightMode:YES];
    [_statusItem setMenu:_systemMenu];
}



@end
