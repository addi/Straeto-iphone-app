//
//  StraetoAppDelegate.m
//  Straeto
//
//  Created by Árni Jónsson on 5.1.2012.
//  Copyright 2012 ProNasty. All rights reserved.
//

#import "StraetoAppDelegate.h"
#import "StraetoViewController.h"
#import "Constants.h"

#import "Flurry.h"

@implementation StraetoAppDelegate

@synthesize window;
@synthesize tabBarController = _tabBarController;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self registerDefaultsFromSettingsBundle];

    viewController = [[[StraetoViewController alloc] initWithNibName:@"StraetoViewController" bundle:nil] retain];
    
    scheduleViewController = [[[ScheduleViewController alloc] initWithNibName:@"ScheduleViewController" bundle:nil] retain];
    
    appSettingsViewController = [[IASKAppSettingsViewController alloc] initWithNibName:@"IASKAppSettingsView" bundle:nil];
    
    appSettingsViewController.title = NSLocalizedString(@"Settings", @"Stillingar");
    appSettingsViewController.tabBarItem.image = [UIImage imageNamed:@"settingsIcon"];
    appSettingsViewController.showDoneButton = NO;
    
    self.tabBarController = [[[UITabBarController alloc] init] autorelease];
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:viewController, scheduleViewController, appSettingsViewController, nil];

    self.window.rootViewController = self.tabBarController;

    [self.window makeKeyAndVisible];
        
    #ifdef kFlurryKey
        [Flurry startSession:kFlurryKey];    
    #endif

    return YES;
}

- (void)registerDefaultsFromSettingsBundle
{
	NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
	[defs synchronize];

	NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"InAppSettings" ofType:@"bundle"];

	if(!settingsBundle)
	{
        NSLog(@"Could not find InAppSettings.bundle");
        return;
	}

	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
	NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
	NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];

	for (NSDictionary *prefSpecification in preferences)
	{
        NSString *key = [prefSpecification objectForKey:@"Key"];
        
        if(key)
        {
            // check if value readable in userDefaults
            id currentObject = [defs objectForKey:key];

            if (currentObject == nil)
            {
                // not readable: set value from Settings.bundle
                id objectToSet = [prefSpecification objectForKey:@"DefaultValue"];
                [defaultsToRegister setObject:objectToSet forKey:key];
//                NSLog(@"Setting object %@ for key %@", objectToSet, key);
            }

//            else
//            {
//                // already readable: don't touch
//                NSLog(@"Key %@ is readable (value: %@), nothing written to defaults.", key, currentObject);
//            }
        }
    }
    
    if ([defaultsToRegister count] > 0)
    {
        [defs registerDefaults:defaultsToRegister];
        [defs synchronize];
    }
	
	[defaultsToRegister release];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */

    [viewController applicationDidBecomeActive];
    [scheduleViewController applicationDidBecomeActive];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc
{
    [scheduleViewController release];
    [viewController release];
    [appSettingsViewController release];
    
    [_tabBarController release];
    
    [window release];
    
    [super dealloc];
}

@end