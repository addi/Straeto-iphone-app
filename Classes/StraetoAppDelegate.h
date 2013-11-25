//
//  StraetoAppDelegate.h
//  Straeto
//
//  Created by Árni Jónsson on 5.1.2012.
//  Copyright 2012 ProNasty. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RealtimeLocationViewController.h"
#import "ScheduleViewController.h"
//#import "IASKAppSettingsViewController.h"

@class RealtimeLocationViewController;

@interface StraetoAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {
    UIWindow *window;
    
    RealtimeLocationViewController *realTimeMapViewController;
    ScheduleViewController *scheduleViewController;
//    IASKAppSettingsViewController *appSettingsViewController;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;

@property (strong, nonatomic) UITabBarController *tabBarController;

//- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item;
- (void)registerDefaultsFromSettingsBundle;

@end

