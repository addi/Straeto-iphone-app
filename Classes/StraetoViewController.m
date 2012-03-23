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

@interface StraetoViewController()
- (NSArray*)findAllPins;
@end

@implementation StraetoViewController

@synthesize mapView = _mapView;
@synthesize pinsToDelete;

@synthesize routesUrl;

@synthesize appSettingsViewController;

- (void)dealloc
{
    [pinsToDelete release];
    [_mapView release];
    [routes release];
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    routes = [[NSArray arrayWithObjects:@"1", @"2", @"3", @"4", @"5", @"6", @"11", @"12", @"13", @"14", @"15", @"17", @"18", @"19", @"21", @"22", @"23", @"24", @"26", @"27", @"28", @"33", @"34", @"35",@"57", nil] retain];
    
    pinsToDelete = [[NSMutableArray alloc] init];
    
    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = kZoomLocationLat;
    zoomLocation.longitude = kZoomLocationLong;
	
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 3000.0, 3000.0);
    
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
    
    [self setUpRouteUrlFromSettings];
    
    shouldUpdateView = YES;
    showError = YES;
    
    [self fetchBusData];
}
     
- (void)setUpRouteUrlFromSettings
{
//    NSLog(@"setUpUrlFromSettings");
    
    NSMutableArray *activeRoutes = [NSMutableArray array];
    
    // url encodeing for ","
    NSString *splitter = @"%2C";
    
    for (NSString *r in routes)
    {
        NSString *settingName = [NSString stringWithFormat:@"route_%@", r];
        
        BOOL settingValue = [[NSUserDefaults standardUserDefaults] boolForKey:settingName];
        
        if(settingValue)
        {
            [activeRoutes addObject:r];
        }        
    }
    
    self.routesUrl = [activeRoutes componentsJoinedByString:splitter];
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
//    NSLog(@"routes: %@", routesUrl);
    
    NSString *urlPath = [NSString stringWithFormat:kStraetoRoutesAPIURL, routesUrl];
    
//    urlPath = @"http://pronasty.com/straeto.json";
    
    NSURL *url = [NSURL URLWithString:urlPath];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];

    [request setDelegate:self];
   
    [request setCompletionBlock:^{
        NSString *responseString = [request responseString];        
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
