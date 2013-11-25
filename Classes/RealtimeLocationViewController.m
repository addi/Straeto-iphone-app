//
//  StraetoViewController.m
//  Straeto
//
//  Created by Árni Jónsson on 5.1.2012.
//  Copyright 2012 ProNasty. All rights reserved.
//

#import "RealtimeLocationViewController.h"
#import "BusLocation.h"
#import <MessageUI/MessageUI.h>
#import "BusBadgeView.h"
#import "Constants.h"

#import "JSONCleaner.h"

#import <AFNetworking/AFNetworking.h>

@interface RealtimeLocationViewController()
- (NSArray*)findAllPins;
@end

@implementation RealtimeLocationViewController

@synthesize mapView = _mapView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
        self.title = NSLocalizedString(@"RealTimeMap", @"Rauntímakort");
        self.tabBarItem.image = [UIImage imageNamed:@"mapIcon"];
        
        self.navigationController.navigationBar.translucent = NO;
        
        pinsToDelete = [NSMutableArray array];
        
        routes = [[RoutHandler alloc] init];
        
        centerOfRvk = [[CLLocation alloc] initWithLatitude:kZoomLocationLat longitude:kZoomLocationLong];
        
        updatePosition = YES;
        shouldUpdateView = NO;
        
        if ([_mapView respondsToSelector:@selector(pitchEnabled)])
        {
            _mapView.pitchEnabled = NO;
        }
        
        [self busDataUpdater];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(centerOfRvk.coordinate, 2000.0, 2000.0);
    
    MKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];                
    
    [_mapView setRegion:adjustedRegion animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [routes setUpFromSettings];
    
    shouldUpdateView = YES;
    
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
    
    if(updatePosition)
    {
        updatePosition = NO;

//        CLLocationDistance distaceFromRVK = [userLocation.location distanceFromLocation:centerOfRvk];
        
        [self.mapView setCenterCoordinate: userLocation.location.coordinate
                                 animated: YES];
    }
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
    
    if ([routesUrl length] <= 0) 
        return;

    NSString *urlPath = [NSString stringWithFormat:kStraetoRoutesAPIURL, routesUrl];
    
//    urlPath = @"http://pronasty.com/straeto.json";
//    urlPath = @"http://arnij.com/json.3-4-5.json";
    
//    NSLog(@"url: %@", urlPath);
        
    NSURL *url = [NSURL URLWithString:urlPath];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSString *responseString = [[NSString alloc] initWithData:responseObject
                                                         encoding:NSUTF8StringEncoding];
        
        NSString *jsonString = [JSONCleaner cleanJSONString:responseString];
        
        
        
        [self parseBusData:jsonString];
    }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        warningView.text = @"Næ ekki sambandi við vefþjón";
        warningView.hidden = NO;

        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [operation start];
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

- (id)parseJson:(NSString *)theJSON
{
    NSData *data = [theJSON dataUsingEncoding:NSUTF8StringEncoding];
    
    if (data)
    {
        NSError *error = nil;
        
        return [NSJSONSerialization JSONObjectWithData:data
                                               options:kNilOptions
                                                 error:&error];
    }
    
    return nil;
}

- (void)parseBusData:(NSString *)busDataString
{   
    NSDictionary * root = [self parseJson:busDataString];
    
    NSArray *routeList = root[@"routes"];
    
    [pinsToDelete addObjectsFromArray:[self findAllPins]];
    
    for(NSDictionary *r in routeList)
    {
        NSArray *busses = r[@"busses"];
        
        for(NSDictionary *busInfo in busses)
        {
            if ([busInfo[@"FROMSTOP"] isEqualToString:@" "] == NO && [busInfo[@"TOSTOP"] isEqualToString:@" "])
            {
                BusLocation *annotation = [[BusLocation alloc] initWithData:busInfo];
                
                [_mapView addAnnotation:annotation];
            }
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
    lastLocation = nil;
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
