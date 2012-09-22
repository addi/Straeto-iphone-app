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
    
    CLLocation *location;
    
//    BOOL shouldGetSchedule;
    
    NSMutableArray *stops;
}

- (void)fetchSchedule;
- (void)parseSchduleData:(NSString *)response;

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) CLLocation *location;

@end
