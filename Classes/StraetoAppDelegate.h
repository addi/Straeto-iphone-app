//
//  StraetoAppDelegate.h
//  Straeto
//
//  Created by Árni Jónsson on 5.1.2012.
//  Copyright 2012 ProNasty. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScheduleViewController.h"

@class StraetoViewController;

@interface StraetoAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    
    ScheduleViewController *scheduleViewController;
//    StraetoViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
//@property (nonatomic, retain) IBOutlet StraetoViewController *viewController;
@property (retain, nonatomic) IBOutlet UINavigationController *navigationController;

@property (strong, nonatomic) UITabBarController *tabBarController;

- (void)registerDefaultsFromSettingsBundle;

@end

