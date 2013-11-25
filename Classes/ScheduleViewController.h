//
//  ScheduleViewController.h
//  Straeto
//
//  Created by Árni Jónsson on 18.9.2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreLocation/CoreLocation.h>

#import "NJISO8601Formatter.h"

@interface ScheduleViewController : UITableViewController <CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
    
    CLLocation *location;
    
    NSMutableArray *stops;
    
    BOOL isiPad;
}

- (void)fetchSchedule;

- (void)applicationDidBecomeActive;

@end
