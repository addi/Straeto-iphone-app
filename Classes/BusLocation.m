//
//  BusLocation.m
//  Straeto
//
//  Created by Árni Jónsson on 5.1.2012.
//  Copyright (c) 2012 Plain Vanilla Games. All rights reserved.
//

#import "BusLocation.h"

@implementation BusLocation

@synthesize number = _number;
@synthesize from_to = _from_to;

@synthesize x = _x, y = _y, debug;

- (id)initWithNumber:(NSString*)number fromTo:(NSString*)fromTo x:(int)x y:(int)y
{
    if ((self = [super init])) {
        _number = [number copy];
        _from_to = [fromTo copy];
        
        _x = x;
        _y = y;
        
        a = 6378137.0;
        f = 1/298.257222101;
        
        lat1 = 64.25;
        lat2 = 65.75;
        latc = 65.00;
        lonc = 19.00;
        
        eps = 0.00000000001;
        
        rho = 45/atan2(1.0,1.0);
        
        e = sqrt(f * (2 - f));

    }
    return self;
}

- (NSString *)title
{
    return _from_to;
}

//- (NSString *)subtitle
//{
//    return _from_to;
//}

- (double)fx:(double)p { return a * cos(p/rho)/sqrt(1 - pow(e*sin(p/rho),2)); }
- (double)f1:(double)p { return log( (1 - p)/(1 + p) ); }
- (double)f2:(double)p { return [self f1:p] - e * [self f1:(e * p)]; }
- (double)f3:(double)p { return pol1*exp( ([self f2:(sin(p/rho))]- f2sin1)*sint/2); }

- (CLLocationCoordinate2D)coordinate
{

    //NSLog(@"Asking for coordinate");
    
    if (debug)
    {
//        NSLog()
        
        //        NSLog("%i", _x);
        //        NSLog("y: %i", _y);
    }
    
    
    
    dum = [self f2:(sin(lat1/rho))] - [self f2:(sin(lat2/rho))];
    sint = 2 * (log([self fx:lat1]) - log( [self fx:lat2])) / dum;
    f2sin1 = [self f2:(sin(lat1/rho))];
    pol1 = [self fx:lat1]/sint;
    polc = [self f3:latc] + 500000.0;
    peq = a * cos(latc/rho)/(sint*exp(sint*log((45-latc/2)/rho)));
    pol = sqrt(pow(_x-500000,2) + pow(polc-_y,2));
    lat = 90 - 2 * rho * atan( exp( log( pol / peq ) / sint ) );
    lon = 0.0;
    fact = rho * cos(lat / rho) / sint / pol;
    
    double delta = 1.0;
    
    eps = 0.00000000001;   

    
    while( delta > eps )
    {
        delta = ( [self f3:lat] - pol ) * fact;
        
        lat += delta;
                
        if(delta < 0.0)
            delta *= -1.0;
    }
    
    lon = -(lonc + rho * atan( (500000 - _x) / (polc - _y) ) / sint);
        
//    NSLog(@"%f,%f", lat, lon);
    
    CLLocationCoordinate2D cords;
    cords.latitude = lat;
    cords.longitude = lon;
    
    return cords;
}

- (void)dealloc
{
    [_number release];
    _number = nil;
    
    [_from_to release];
    _from_to = nil;

    [super dealloc];
}

@end
