//
//  ScheduleViewController.m
//  Straeto
//
//  Created by Árni Jónsson on 18.9.2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ScheduleViewController.h"

#import "ASIHTTPRequest.h"
#import "SBJson.h"
#import "Constants.h"

#import "BusStop.h"

#define ISO_TIMEZONE_UTC_FORMAT @"Z"
#define ISO_TIMEZONE_OFFSET_FORMAT @"%+02d%02d"

@interface ScheduleViewController ()

@end

@implementation ScheduleViewController

@synthesize locationManager;
@synthesize location;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self)
    {        
        self.title = NSLocalizedString(@"Schedule", @"Tímatafla");
        self.tabBarItem.image = [UIImage imageNamed:@"sheduleIcon"];
        
        self.locationManager = [[[CLLocationManager alloc] init] autorelease];
		self.locationManager.delegate = self;
        
        stops = [[NSMutableArray alloc] init];
        
        isiPad = ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad );
    }
    
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    
    if (self)
    {
        self.title = NSLocalizedString(@"Schedule", @"Tímatafla");
    }

    return self;
}

- (void)dealloc
{
    [locationManager release];
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [locationManager startUpdatingLocation];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (location)
    {
        [self fetchSchedule];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    [super didRotateFromInterfaceOrientation:interfaceOrientation];
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return MAX([stops count], 1);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([stops count] > 0)
    {
        return [[stops objectAtIndex:section] timesCount];
    }
    
    else
    {
        return 0;
    }
    
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if ([stops count] == 0)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ScheduleErrorView" owner:self options:nil];
        UIView *view = (UIView *)[nib objectAtIndex:0];
        
        view.userInteractionEnabled = NO;
        
        return view;
    }
    
    else
    {
        return nil;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([stops count] == 0)
    {
        return nil;
    }
    
    BusStop *tmpStop = [stops objectAtIndex:section];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ScheduleHeader" owner:self options:nil];
    UIView *view = (UIView *)[nib objectAtIndex:0];
    
    UILabel *titleLable = (UILabel *) [view viewWithTag:1];
    titleLable.text = tmpStop.name;
    
    UILabel *distanceLabel = (UILabel *) [view viewWithTag:2];
    
    distanceLabel.text = [NSString stringWithFormat:@"%d m", tmpStop.distance];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *CellNib = @"ScheduleCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:CellNib owner:self options:nil];
        
        cell = (UITableViewCell *)[nib objectAtIndex:0];
    }
    
    BusStop *tmpStop = [stops objectAtIndex:indexPath.section];
    
    NSDictionary *route = [tmpStop timeAtRow:indexPath.row];
    
    UILabel *routeLabel = (UILabel *) [cell viewWithTag:1];      
    routeLabel.text = [[route valueForKey:@"route"] stringValue];
    
    UILabel *endStopLable = (UILabel *) [cell viewWithTag:2];       
    endStopLable.text = [[route valueForKey:@"endStop"] valueForKey:@"shortName"];
    
    NSArray *times = [route valueForKey:@"times"];
    
    UILabel *time1Lable = (UILabel *) [cell viewWithTag:3];
    UILabel *time2Lable = (UILabel *) [cell viewWithTag:4];
    UILabel *time3Lable = (UILabel *) [cell viewWithTag:5];
    UILabel *time4Lable = (UILabel *) [cell viewWithTag:6];
    
    NSArray *timeLabels = [NSArray arrayWithObjects:time1Lable, time2Lable, time3Lable, time4Lable, nil];
    
    int startAtLabel = 0;
    
    if ((self.interfaceOrientation == UIDeviceOrientationPortrait || self.interfaceOrientation == UIDeviceOrientationPortraitUpsideDown) && !isiPad)
    {
        startAtLabel = 2;
    }
    
    if([times count] < 4)
    {
        int shouldStartAt = 4 - [times count];
        
        if(startAtLabel < shouldStartAt)
        {
            startAtLabel = shouldStartAt;
        }
    }
    
    for (int tl = 0; tl < [timeLabels count]; tl++)
    {
        UILabel *tmpLabel = [timeLabels objectAtIndex:tl];
        
        if(tl < startAtLabel)
        {
            tmpLabel.hidden = YES;
        }
        
        else
        {
            tmpLabel.hidden = NO;
            
            int timeIndex = tl-startAtLabel;
            
            tmpLabel.text = [times objectAtIndex:timeIndex];
        }
    }
    
    return cell;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    BOOL shouldFetchSchedule = (location == nil);
    
    self.location = newLocation;
    
    if (shouldFetchSchedule)
    {
        [self fetchSchedule];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Error: %@", error);
}

- (NSString *)strFromISO8601:(NSDate *)date
{
    static NSDateFormatter* sISO8601 = nil;
    
    if (!sISO8601)
    {
        sISO8601 = [[NSDateFormatter alloc] init];
        
        NSTimeZone *timeZone = [NSTimeZone localTimeZone];
        int offset = [timeZone secondsFromGMT];
        
        NSMutableString *strFormat = [NSMutableString stringWithString:@"yyyy-MM-dd'T'HH:mm:ss"];
        offset /= 60; //bring down to minutes
        
        if (offset == 0)
            [strFormat appendString:ISO_TIMEZONE_UTC_FORMAT];
        else
            [strFormat appendFormat:ISO_TIMEZONE_OFFSET_FORMAT, offset / 60, offset % 60];
        
        [sISO8601 setTimeStyle:NSDateFormatterFullStyle];
        [sISO8601 setDateFormat:strFormat];
    }

    return[sISO8601 stringFromDate:date];
}

- (void)fetchSchedule
{
    NSDate *fromDate = [[NSDate date] dateByAddingTimeInterval:-2*60];
    NSDate *toDate = [[NSDate date] dateByAddingTimeInterval:2*60*60];
    
//    fromDate = [fromDate dateByAddingTimeInterval:60*60*12];
//    toDate = [fromDate dateByAddingTimeInterval:60*60*12];
    
    NSString *fromString = [self strFromISO8601:fromDate];
    NSString *toString = [self strFromISO8601:toDate];
        
    NSString *urlPath = [NSString stringWithFormat:kGulurAPIURL, location.coordinate.latitude, location.coordinate.longitude, fromString, toString];
    
    NSLog(@"url: %@", urlPath);
    
    NSURL *url = [NSURL URLWithString:urlPath];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setAllowCompressedResponse:YES]; 
    
    [request setCompletionBlock:^{
        NSString *responseString = [request responseString];
        
        [self parseSchduleData:responseString];
    }];
    
    [request setFailedBlock:^{
        NSError *error = [request error];
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [request startAsynchronous];
}

- (void)parseSchduleData:(NSString *)response
{
    NSArray *routes = [response JSONValue];
    
    [stops removeAllObjects];
    
    for(NSDictionary *r in routes)
    {
        [self addTimeToStop:r];
    }
        
    [self.tableView reloadData];
}

- (void)addTimeToStop:(NSDictionary*)time
{
    NSString *stopName = [[time valueForKey:@"stop"] valueForKey:@"shortName"];
    
    BusStop *stop = nil;
    
    for(BusStop *s in stops)
    {
        if ([s.name isEqualToString:stopName])
        {
            stop = s;
            break;
        }
    }
    
    // add the busstop if it was not in the array
    if(!stop)
    {
        stop = [[BusStop alloc] initWithName:stopName];
        
        NSArray *locationArray = [[time valueForKey:@"stop"] valueForKey:@"location"];
        
        CLLocation *stopLocation = [[[CLLocation alloc] initWithLatitude:[[locationArray objectAtIndex:0] doubleValue] longitude:[[locationArray objectAtIndex:1] doubleValue]] autorelease];
        
        stop.distance = [location distanceFromLocation:stopLocation];
        
        [stops addObject:stop];
    }
    
    [stop addTime:time];
}

- (void)applicationDidBecomeActive
{
    location = nil;
}

@end
