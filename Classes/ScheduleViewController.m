//
//  ScheduleViewController.m
//  Straeto
//
//  Created by Árni Jónsson on 18.9.2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ScheduleViewController.h"

#import "Constants.h"

#import "BusStop.h"

#import <AFNetworking/AFNetworking.h>

@interface ScheduleViewController ()

@end

@implementation ScheduleViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self)
    {        
        self.title = NSLocalizedString(@"Schedule", @"Tímatafla");
        self.tabBarItem.image = [UIImage imageNamed:@"sheduleIcon"];
        
        locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;
        
        stops = [[NSMutableArray alloc] init];
        
        isiPad = ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad );
        
        self.navigationController.navigationBar.translucent = NO;
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


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    {
        self.tableView.contentInset = UIEdgeInsetsMake(20.0f, 0.0f, 0.0f, 0.0f);
        
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.extendedLayoutIncludesOpaqueBars = NO;
    }
    
#if (TARGET_IPHONE_SIMULATOR)
    [self fakeLocation];
#endif
    
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
        BusStop *tmpBusStop = stops[section];
        
        return [tmpBusStop.routes count];
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
        UIView *view = (UIView *)nib[0];
        
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
    
    BusStop *tmpStop = stops[section];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ScheduleHeader" owner:self options:nil];
    UIView *view = (UIView *)nib[0];
    
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
        
        cell = (UITableViewCell *)nib[0];
    }
    
    BusStop *tmpStop = stops[indexPath.section];
    
    NSDictionary *route = tmpStop.routes[indexPath.row];
    
    UILabel *routeLabel = (UILabel *) [cell viewWithTag:1];
    routeLabel.text = route[@"route"];
    
    UILabel *endStopLable = (UILabel *) [cell viewWithTag:2];       
    endStopLable.text = route[@"last_stop_name"];
    
    NSArray *times = route[@"current_times"];
    
    UILabel *time1Lable = (UILabel *) [cell viewWithTag:3];
    UILabel *time2Lable = (UILabel *) [cell viewWithTag:4];
    UILabel *time3Lable = (UILabel *) [cell viewWithTag:5];
    UILabel *time4Lable = (UILabel *) [cell viewWithTag:6];
    
    NSArray *timeLabels = @[time1Lable, time2Lable, time3Lable, time4Lable];
    
    int startAtLabel = 0;
    
    if ((self.interfaceOrientation == UIDeviceOrientationPortrait ||
         self.interfaceOrientation == UIDeviceOrientationPortraitUpsideDown) &&
        !isiPad)
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
        UILabel *tmpLabel = timeLabels[tl];
        
        if(tl < startAtLabel)
        {
            tmpLabel.hidden = YES;
        }
        
        else
        {
            tmpLabel.hidden = NO;
            
            int timeIndex = tl-startAtLabel;
            
            tmpLabel.text = times[timeIndex];
        }
    }
    
    return cell;
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    BOOL shouldFetchSchedule = (location == nil);
    
    location = newLocation;
    
    if (shouldFetchSchedule)
    {
        [self fetchSchedule];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Error: %@", error);
}

- (void)fakeLocation
{
    location = [[CLLocation alloc] initWithLatitude:64.139398
                                          longitude:-21.917950];
    
    [self fetchSchedule];
}

- (void)fetchSchedule
{
    NSString *urlPath = [NSString stringWithFormat:kScheduleURL,
                         location.coordinate.latitude,
                         location.coordinate.longitude];
    
    NSURL *url = [NSURL URLWithString:urlPath];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
    {
        NSArray *data = JSON;
        
        [self parseSchduleData:data];
    }
                                                                                        failure:nil];
    
    [operation start];
}

- (void)parseSchduleData:(NSArray *)stopsData
{
    [stops removeAllObjects];
    
    for(NSDictionary *stopData in stopsData)
    {
        BusStop *stop = [[BusStop alloc] initWithData:stopData];
        
        [stops addObject:stop];
    }
        
    [self.tableView reloadData];
}

- (void)applicationDidBecomeActive
{
    location = nil;
}

@end
