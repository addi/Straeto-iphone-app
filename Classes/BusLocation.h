//
//  BusLocation.h
//  Straeto
//
//  Created by Árni Jónsson on 5.1.2012.
//  Copyright (c) 2012 Plain Vanilla Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface BusLocation : NSObject <MKAnnotation>
{
    NSString *_number;
    NSString *_from_to;
    
    int _x, _y;
    
    Boolean debug;
    
    CLLocationCoordinate2D _coordinate;
    
    double a ,f ,lat1 ,lat2 ,latc ,lonc ,eps ,rho ,e, f2sin1, sint, pol1, dum, polc, peq, pol, lat, lon, fact;
}

@property (copy, readwrite) NSString *number;
@property (copy) NSString *from_to;

@property Boolean debug;

@property int x;
@property int y;

- (id)initWithNumber:(NSString*)number fromTo:(NSString*)fromTo x:(int)x y:(int)y;
- (NSString *)title;
//- (NSString *)subtitle;

- (double)fx:(double)p;
- (double)f1:(double)p;
- (double)f2:(double)p;
- (double)f3:(double)p;

- (CLLocationCoordinate2D)coordinate;

@end
