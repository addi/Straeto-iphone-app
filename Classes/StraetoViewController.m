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

#import "JSONCleaner.h"

@interface StraetoViewController()
- (NSArray*)findAllPins;
@end

@implementation StraetoViewController

@synthesize mapView = _mapView;
@synthesize pinsToDelete;
@synthesize lastLocation;

- (void)dealloc
{
    [pinsToDelete release];
    [_mapView release];
    
    [routes release];
    
    [centerOfRvk release];
    
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
        self.title = NSLocalizedString(@"RealTimeMap", @"Rauntímakort");
        self.tabBarItem.image = [UIImage imageNamed:@"mapIcon"];
        
        self.navigationController.navigationBar.translucent = NO;
        
        if ([_mapView respondsToSelector:@selector(pitchEnabled)])
        {
            _mapView.pitchEnabled = NO;
        }
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    pinsToDelete = [[NSMutableArray alloc] init];
    
    routes = [[RoutHandler alloc] init];
    
    updatePosition = YES;
    
    centerOfRvk = [[CLLocation alloc] initWithLatitude:kZoomLocationLat longitude:kZoomLocationLong];
    	
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(centerOfRvk.coordinate, 2000.0, 2000.0);
    
    MKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];                
    
    [_mapView setRegion:adjustedRegion animated:YES];
    
    shouldUpdateView = NO;
    
    [self busDataUpdater];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
//    NSLog(@"viewWillAppear:");
    
    [routes setUpFromSettings];
    
    updateCloseRoutes = YES;
    
    shouldUpdateView = YES;
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"gps_routes"] && lastLocation)
        [routes addRoutesByLocation:lastLocation];
    
    [self fetchBusData];
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
//    double gpsDataAge = [userLocation.location.timestamp timeIntervalSinceNow];
    
    double accuracy = MAX(userLocation.location.horizontalAccuracy, userLocation.location.verticalAccuracy);
    
    if(userLocation.location == nil && accuracy > kMaxGPSAccuracy) //  || gpsDataAge < -5
    {
        return;
    }
    
    self.lastLocation = userLocation.location;
    
//    NSLog(@"date: %@", userLocation.location.timestamp);
//    NSLog(@"gpsDataAge: %f", gpsDataAge);
//    NSLog(@"cords: %f, %f", userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude);
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"gps_routes"])
    {
        //        CLLocation *testLocation = [[CLLocation alloc] initWithLatitude:64.094651 longitude:-21.839232];
        //        [routes addRoutesByLocation:testLocation];
        
        [routes addRoutesByLocation:userLocation.location];
    }
    
    if(updatePosition)
    {
//        NSLog(@"updatePosition");
        
        updatePosition = NO;
        
//        NSLog(@"updateing position");
        
        //    CLLocationDistance distaceFromRVK = [userLocation.location distanceFromLocation:centerOfRvk];
        
        double distanceFromClosestStop = [routes distanceFromClosestStopByLocation:userLocation.location];
        
        //    NSLog(@"distanceFromClosestStop: %f", distanceFromClosestStop);
        
        if( distanceFromClosestStop < kMaxDistanceFromStop)
        {
            //        NSLog(@"distance from rvk: %@", distaceFromRVK);
            //        NSLog(@"set coordinates: %f, %f", userLocation.location.coordinate.longitude, userLocation.location.coordinate.latitude);
            
            [self.mapView setCenterCoordinate: userLocation.location.coordinate
                                     animated: YES];
        }
        
        // a awkward fix
        [self fetchBusData];
    }
    
//    NSLog(@"   ");
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
    
//    NSLog(@"routes: %@", routesUrl);
    
    if ([routesUrl length] <= 0) 
        return;

    NSString *urlPath = [NSString stringWithFormat:kStraetoRoutesAPIURL, routesUrl];
    
//    urlPath = @"http://pronasty.com/straeto.json";
//    urlPath = @"http://arnij.com/json.3-4-5.json";
    
//    NSLog(@"url: %@", urlPath);
        
    NSURL *url = [NSURL URLWithString:urlPath];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];

    [request setDelegate:self];
   
    [request setCompletionBlock:^{
        NSString *responseString = [request responseString];
        
//        NSLog(@"old: %@", responseString);
        
        NSString *jsonString = [JSONCleaner cleanJSONString:responseString];
        
//        NSLog(@"new: %@", jsonString);
        
        [self parseBusData:jsonString];        
    }];
    
    [request setFailedBlock:^{

        warningView.text = @"Næ ekki sambandi við vefþjón";
        warningView.hidden = NO;
        
                
        NSError *error = [request error];
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [request startAsynchronous];
}

- (NSString*)fixJson:(NSString*)jsonString
{    
    NSRange range = NSMakeRange ([jsonString length]-10, 10);
    
    return [jsonString stringByReplacingOccurrencesOfString:@"," withString:@"" options:NSCaseInsensitiveSearch range:range];
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
    {
        warningView.hidden = NO;
        warningView.text = @"Engir vagnar á ferð";
    }
    
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

- (void)applicationDidBecomeActive
{
    updatePosition = YES;
    self.lastLocation = nil;
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
