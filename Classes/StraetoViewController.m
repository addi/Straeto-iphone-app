//
//  StraetoViewController.m
//  Straeto
//
//  Created by Árni Jónsson on 5.1.2012.
//  Copyright 2012 ProNasty. All rights reserved.
//

#import "StraetoViewController.h"
#import "BusLocation.h"
#import "ASIHTTPRequest.h"
#import "SBJson.h"
#import <MessageUI/MessageUI.h>
#import "IASKSpecifier.h"
#import "IASKSettingsReader.h"
#import "BusBadgeView.h"
#import "Constants.h"

#import "TestFlight.h"

@interface StraetoViewController()
- (NSArray*)findAllPins;
@end

@implementation StraetoViewController

@synthesize mapView = _mapView;
@synthesize pinsToDelete;

@synthesize appSettingsViewController;

- (void)dealloc
{
    [pinsToDelete release];
    [_mapView release];
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [self loadBusStops];
    
    pinsToDelete = [[NSMutableArray alloc] init];
    
    routes = [[RoutHandler alloc] init];
    
    updatePosition = YES;
    
    centerOfRvk = [[CLLocation alloc] initWithLatitude:kZoomLocationLat longitude:kZoomLocationLong];
    	
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(centerOfRvk.coordinate, 3000.0, 3000.0);
    
    MKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];                
    
    [_mapView setRegion:adjustedRegion animated:YES];
    
    self.title = NSLocalizedString(@"RealTimeMap", @"Rauntímakort");
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Routes", @"Leiðir") style:UIBarButtonItemStylePlain target:self action:@selector(loadSettingsView)] autorelease];
    
    shouldUpdateView = NO;
    
    warningView = [self.view viewWithTag:2];
    
    [self busDataUpdater];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [routes setUpFromSettings];
    
    updateCloseRoutes = YES;
    
    shouldUpdateView = YES;
    showError = YES;
    
    [self fetchBusData];
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if( updatePosition && [userLocation.location distanceFromLocation:centerOfRvk] < kMaxDistanceFromRVK)
    {
        updatePosition = NO;
        [self.mapView setCenterCoordinate: userLocation.location.coordinate
                                 animated: YES];
    }
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"gps_routes"])
    {
//        CLLocation *testLocation = [[CLLocation alloc] initWithLatitude:64.094651 longitude:-21.839232];
//        [routes addRoutesByLocation:testLocation];

        [routes addRoutesByLocation:userLocation.location];
    }
}

- (IASKAppSettingsViewController*)appSettingsViewController
{	
    if (!appSettingsViewController)
    {
		appSettingsViewController = [[IASKAppSettingsViewController alloc] initWithNibName:@"IASKAppSettingsView" bundle:nil];
        
        appSettingsViewController.title = NSLocalizedString(@"Routes", @"Leiðir");
		appSettingsViewController.delegate = self;
	}
    
	return appSettingsViewController;
}

- (void)loadSettingsView
{    
    self.appSettingsViewController.showDoneButton = NO;
	[self.navigationController pushViewController:self.appSettingsViewController animated:YES];
}

- (void)busDataUpdater
{
    if(shouldUpdateView)
        [self fetchBusData];
    
    [self performSelector:@selector(busDataUpdater) withObject:nil afterDelay:kDataUpdateFrequency];
}

- (void)fetchBusData
{
    NSString *routesUrl = [routes url];
    
    NSLog(@"routes: %@", routesUrl);
    
    if ([routesUrl length] <= 0) 
        return;
    NSString *urlPath = [NSString stringWithFormat:kStraetoRoutesAPIURL, routesUrl];
    
//    urlPath = @"http://pronasty.com/straeto.json";
    
    NSURL *url = [NSURL URLWithString:urlPath];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];

    [request setDelegate:self];
   
    [request setCompletionBlock:^{
        NSString *responseString = [request responseString];
        
//        NSLog(@"responseString: %@", responseString);
        
        [self parseBusData:responseString];        
    }];
    
    [request setFailedBlock:^{

        if(showError)
        {
            UIAlertView* aiv = [[[UIAlertView alloc] initWithTitle:@"Villa" message:@"Næ ekki sambandi við vefþjón" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
            
            [aiv show];
            
            showError = NO;
        }
                
        NSError *error = [request error];
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [request startAsynchronous];
}

- (NSArray*)findAllPins
{
    NSMutableArray *pins = [NSMutableArray array];
    
    for(NSObject<MKAnnotation>* annotation in [_mapView annotations])
    {
        if([annotation isKindOfClass:[BusLocation class]])
            [pins addObject:annotation];
    }
    
    return pins;
}

- (void)parseBusData:(NSString *)busDataString
{   
    NSDictionary * root = [busDataString JSONValue];
    
    NSArray *routeList = [root objectForKey:@"routes"];
    
    [self.pinsToDelete addObjectsFromArray:[self findAllPins]];
    
    for(NSDictionary *r in routeList)
    {
        NSArray *busses = [r objectForKey:@"busses"];
        
        for(NSDictionary *b in busses)
        {
            NSString *nr = [b objectForKey:@"BUSNR"];
            NSNumber *x = [b objectForKey:@"X"];
            NSNumber *y = [b objectForKey:@"Y"];
            
            NSString *from = [b objectForKey:@"FROMSTOP"];
            NSString *to = [b objectForKey:@"TOSTOP"];
            
            NSString* fromTo = [NSString stringWithFormat:@"%@ → %@", from, to];
            
            BusLocation *annotation = [[BusLocation alloc] initWithNumber:nr fromTo:fromTo x:[x intValue] y:[y intValue]];                
            [_mapView addAnnotation:annotation];                
            [annotation release];
        }
    }
    
    if (routeList != nil && [routeList count] < 1)
        warningView.hidden = NO;
    
    if (warningView.hidden == NO && [routeList count] > 0)
        warningView.hidden = YES;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    if([pinsToDelete count])
    {
        [_mapView removeAnnotations:pinsToDelete];
        [pinsToDelete removeAllObjects];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    static NSString *identifier = @"BusLocation";
    
    if ([annotation isKindOfClass:[BusLocation class]])
    {
        BusLocation *busAnnotation = annotation;
        
        BusBadgeView *annotationView = (BusBadgeView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        
        if (annotationView == nil)
            annotationView = [[BusBadgeView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        else
            annotationView.annotation = busAnnotation;

        [annotationView setBadgeString:busAnnotation.number];
                
        annotationView.enabled = YES;
        annotationView.canShowCallout = YES;
        
        return annotationView;
    }
    
    return nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	
	[self setMapView:nil];
    [super viewDidUnload];

}

@end
