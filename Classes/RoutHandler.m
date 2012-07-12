//
//  RoutHandler.m
//  Straeto
//
//  Created by Árni Jónsson on 20.4.2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RoutHandler.h"
#import "Constants.h"

@implementation RoutHandler

- (id)init {
    self = [super init];
    if (self)
    {
        allRoutes = [[NSArray arrayWithObjects:@"1", @"2", @"3", @"4", @"5", @"6", @"11", @"12", @"13", @"14", @"15", @"17", @"18", @"19", @"21", @"22", @"23", @"24", @"26", @"27", @"28", @"33", @"34", @"35",@"51",@"52",@"57", nil] retain];
        
        routes = [[NSMutableSet alloc] init];
        settingsRoutes = [[NSMutableSet alloc] init];
        
        busStops = [[NSMutableArray array] retain];
        
        [self loadBusStops];
    }
    return self;
}

- (void)loadBusStops
{
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSString *finalPath = [path stringByAppendingPathComponent:@"bus_stops.plist"];
    
    NSArray *plistBusStops = [NSArray arrayWithContentsOfFile:finalPath];
    
    busStops = [[NSMutableArray arrayWithCapacity:[plistBusStops count]] retain];
    
    CLLocation *tmpLoc;
    
    double tmpLat, tmpLong;
    
    NSDictionary *tmpStop;
    
    for(NSDictionary *stop in plistBusStops)
    {
        tmpLat = [[stop objectForKey:@"lat"] doubleValue];
        tmpLong = [[stop objectForKey:@"long"] doubleValue];
        
        tmpLoc = [[CLLocation alloc] initWithLatitude:tmpLat longitude:tmpLong];
        
        tmpStop = [NSDictionary dictionaryWithObjectsAndKeys:tmpLoc, @"location", [stop objectForKey:@"routes"], @"routes", nil];
        
        [busStops addObject:tmpStop];
    }
}

- (void)setUpFromSettings
{
    [routes removeAllObjects];
    [settingsRoutes removeAllObjects];
    
    for (NSString *r in allRoutes)
    {
        NSString *settingName = [NSString stringWithFormat:@"route_%@", r];
        
        if([[NSUserDefaults standardUserDefaults] boolForKey:settingName])
            [settingsRoutes addObject:r];
    }
    
    [routes unionSet:settingsRoutes];
}

-(void)addRoutesByLocation:(CLLocation*)location
{
    // reset the routes 
    [routes removeAllObjects];
    [routes unionSet:settingsRoutes];
    
    double accuracy = MAX(location.horizontalAccuracy, location.verticalAccuracy);
    
    double maxRadius = (accuracy/2)+kMaxDistanceFromGPS;
    
    CLLocation *tmpStopLocation;
    
    for(NSDictionary *stop in busStops)
    {
        tmpStopLocation = [stop objectForKey:@"location"];
        
        double distance = [location distanceFromLocation:tmpStopLocation];
        
        if(distance < maxRadius)
        {
            NSArray *closeStops = [stop objectForKey:@"routes"];
            
            for(NSString *r in closeStops)
            {
//                NSLog(@"FOUND: %@", r);
                
                [routes addObject:r];
            }
        }
    }
}

-(double)distanceFromClosestStopByLocation:(CLLocation*)location
{
    double minDistance = kMaxDistanceFromStop;
    
    if(!location)
        return minDistance;
    
    CLLocation *tmpStopLocation;
    
    for(NSDictionary *stop in busStops)
    {
        tmpStopLocation = [stop objectForKey:@"location"];
        
        double distance = [location distanceFromLocation:tmpStopLocation];
        
        if(distance < minDistance)
        {
            minDistance = distance;
        }
    }
    
    return minDistance;
}

-(NSString*)url
{
    return [[routes allObjects] componentsJoinedByString:kURLSplitter];
}

-(void)debug
{
    NSLog(@"routes: %@", [[routes allObjects] componentsJoinedByString:@"-"]);
}

- (void)dealloc
{
    [allRoutes release];
    [routes release];
    
    [settingsRoutes release];
    
    [super dealloc];
}

@end
