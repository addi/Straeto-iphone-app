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

@interface ScheduleViewController ()

@end

@implementation ScheduleViewController

@synthesize locationManager;

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

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if (shouldGetSchedule)
    {
        NSLog(@"new location: %@", newLocation);
        
        [self fetchSchedule:newLocation];
        
        shouldGetSchedule = NO;
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Error: %@", error);
}

- (void)fetchSchedule:(CLLocation *)newLocation
{
    NSString *urlPath = [NSString stringWithFormat:kGulurAPIURL, newLocation.coordinate.latitude, newLocation.coordinate.longitude];
    
    NSLog(@"url: %@", urlPath);
        
    NSURL *url = [NSURL URLWithString:urlPath];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
    [request setCompletionBlock:^{
        NSString *responseString = [request responseString];
                
//        NSLog(@"response: %@", responseString);
        
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
    
    int lastStopId = -1;
    
    for(NSDictionary *r in routes)
    {
//        NSString *routeName = [r valueForKey:@"route"];        

        NSDictionary *stop = [r valueForKey:@"stop"];
        
//        NSString *stopName = [stop valueForKey:@"shortName"];
        int stopId = [[stop valueForKey:@"stopId"] intValue];
        
//        NSLog(@"routeName: %@", routeName);
//        NSLog(@"stopName: %@", stopName);
//        NSLog(@" ");
        
        if (stopId != lastStopId)
        {
            [stops addObject:[NSMutableArray array]];
        }
        
        [[stops lastObject] addObject:r];
        
        lastStopId = stopId;
    }
    
    NSLog(@"done");
    
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [locationManager startUpdatingLocation];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    shouldGetSchedule = YES;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{    
    return [stops count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[stops objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[[[stops objectAtIndex:section] firstObject] valueForKey:@"stop"] valueForKey:@"shortName"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *CellNib = @"ScheduleCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
//
//        cell.userInteractionEnabled = NO;
        
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:CellNib owner:self options:nil];
        
        cell = (UITableViewCell *)[nib objectAtIndex:0];
    }
    
    NSDictionary *route = [[stops objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    UILabel *routeLabel = (UILabel *) [cell viewWithTag:1];       
    routeLabel.text = [[route valueForKey:@"route"] stringValue];
    
    UILabel *endStopLable = (UILabel *) [cell viewWithTag:2];       
    endStopLable.text = [[route valueForKey:@"endStop"] valueForKey:@"shortName"];
    
    UILabel *time1Lable = (UILabel *) [cell viewWithTag:3];       
    time1Lable.text = [[route valueForKey:@"times"] firstObject];
    
    UILabel *time2Lable = (UILabel *) [cell viewWithTag:4];       
    time2Lable.text = [[route valueForKey:@"times"] objectAtIndex:1];

    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

@end
