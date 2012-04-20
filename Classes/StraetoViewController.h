//
//  StraetoViewController.h
//  Straeto
//
//  Created by Árni Jónsson on 5.1.2012.
//  Copyright 2012 ProNasty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "IASKAppSettingsViewController.h"

@interface StraetoViewController : UIViewController <MKMapViewDelegate>
{
	MKMapView *_mapView;
    BOOL debug;
    NSMutableArray *pinsToDelete;
    
    NSArray *allRoutes;
    
    NSMutableSet *routes;
    NSMutableSet *settingsRoutes;
    
    BOOL shouldUpdateView;
    
    BOOL showError;
    
    BOOL updatePosition;
    BOOL updateCloseRoutes;
    
    CLLocation *centerOfRvk;
    
    NSTimeInterval lastUpdate;
    
    NSMutableArray *busStops;
    
    IASKAppSettingsViewController *appSettingsViewController;
    
    UIView *warningView;
}

@property (nonatomic, retain) IBOutlet MKMapView *mapView;
@property (readwrite, retain) NSMutableArray *pinsToDelete;

@property (nonatomic, retain) IASKAppSettingsViewController *appSettingsViewController;

- (void)setUpRouteUrlFromSettings;

- (NSArray*)findAllPins;

- (void)busDataUpdater;
- (void)fetchBusData;
- (void)parseBusData:(NSString *)busDataString;

- (void)loadSettingsView;
- (void)loadBusStops;

-(void)findCloseBusRutesTo:(CLLocation*)location;

@end
