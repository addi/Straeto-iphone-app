//
//  ScheduleViewController.h
//  Straeto
//
//  Created by Árni Jónsson on 18.9.2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreLocation/CoreLocation.h>

@interface ScheduleViewController : UITableViewController <CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
    
    BOOL shouldGetSchedule;
    
    NSMutableArray *stops;
}

- (void)fetchSchedule:(CLLocation *)newLocation;
- (void)parseSchduleData:(NSString *)response;

@property (nonatomic, retain) CLLocationManager *locationManager;

@end
