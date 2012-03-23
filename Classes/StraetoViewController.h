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
    
    NSArray *routes;
    NSString *routesUrl;
    
    BOOL shouldUpdateView;
    
    BOOL showError;
    
    NSTimeInterval lastUpdate;
    
    IASKAppSettingsViewController *appSettingsViewController;
    
    UIView *warningView;
}

@property (nonatomic, retain) IBOutlet MKMapView *mapView;
@property (readwrite, retain) NSMutableArray *pinsToDelete;

@property (readwrite, retain) NSString *routesUrl;

@property (nonatomic, retain) IASKAppSettingsViewController *appSettingsViewController;

- (void)setUpRouteUrlFromSettings;

- (NSArray*)findAllPins;

- (void)busDataUpdater;
- (void)fetchBusData;
- (void)parseBusData:(NSString *)busDataString;

- (void)loadSettingsView;

@end
