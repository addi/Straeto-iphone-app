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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{    
    return [stops count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[stops objectAtIndex:section] timesCount];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    BusStop *tmpStop = [stops objectAtIndex:section];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ScheduleHeader" owner:self options:nil];
    UIView *view = (UIView *)[nib objectAtIndex:0];
    
    UILabel *titleLable = (UILabel *) [view viewWithTag:1];
    titleLable.text = tmpStop.name;
    
    UILabel *distanceLabel = (UILabel *) [view viewWithTag:2];
    
    distanceLabel.text = [NSString stringWithFormat:@"%d m", tmpStop.distance];
    
    return view;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    BusStop *tmpStop = [stops objectAtIndex:section];
    
    return tmpStop.name;
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
    
    if ([times count] > 1)
    {
        time1Lable.text = [times objectAtIndex:0];
        
        time2Lable.text = [times objectAtIndex:1];
    }
    
    else if([times count] == 1)
    {
        time1Lable.hidden = YES;
        
        time2Lable.text = [times objectAtIndex:0];
    }
    
    else
    {
        time1Lable.hidden = YES;
        time2Lable.hidden = YES;
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
    NSDate *toDate = [[NSDate date] dateByAddingTimeInterval:60*60];
    
    NSString *fromString = [self strFromISO8601:fromDate];
    NSString *toString = [self strFromISO8601:toDate];
    
    NSLog(@"from date: %@", fromString);
    NSLog(@"to date: %@", toString);
    
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
    
    if ([routes count] > 0)
    {
        NSLog(@"found routes");
        warningView.hidden = YES;
    }
    
    else
    {
        NSLog(@"No routes");
        
        warningView.hidden = NO;
        warningView.text = @"Engir vagnar á ferð";
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
