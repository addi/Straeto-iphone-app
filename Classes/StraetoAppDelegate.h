//
//  StraetoAppDelegate.h
//  Straeto
//
//  Created by Árni Jónsson on 5.1.2012.
//  Copyright 2012 ProNasty. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "StraetoViewController.h"
#import "ScheduleViewController.h"
#import "IASKAppSettingsViewController.h"

@class StraetoViewController;

@interface StraetoAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {
    UIWindow *window;
    
    StraetoViewController *realTimeMapViewController;
    ScheduleViewController *scheduleViewController;
    IASKAppSettingsViewController *appSettingsViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (strong, nonatomic) UITabBarController *tabBarController;

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item;
- (void)registerDefaultsFromSettingsBundle;

@end

