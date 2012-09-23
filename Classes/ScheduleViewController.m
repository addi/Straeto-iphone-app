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

- (void)fetchSchedule
{
    NSString *urlPath = [NSString stringWithFormat:kGulurAPIURL, location.coordinate.latitude, location.coordinate.longitude];
    
    NSLog(@"url: %@", urlPath);
    
    NSURL *url = [NSURL URLWithString:urlPath];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
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
        
        [stops addObject:stop];
    }
    
    [stop addTime:time];
}

@end
