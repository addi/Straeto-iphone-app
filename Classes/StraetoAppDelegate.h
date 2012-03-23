//
//  StraetoAppDelegate.h
//  Straeto
//
//  Created by Árni Jónsson on 5.1.2012.
//  Copyright 2012 ProNasty. All rights reserved.
//

#import <UIKit/UIKit.h>

@class StraetoViewController;

@interface StraetoAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    StraetoViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet StraetoViewController *viewController;
@property (retain, nonatomic) IBOutlet UINavigationController *navigationController;

- (void)registerDefaultsFromSettingsBundle;

@end

