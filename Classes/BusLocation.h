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
    int x, y;
    
    NSString *number;
    
    NSString *fromTo;
    
    Boolean debug;
    
    CLLocationCoordinate2D _coordinate;
    
    double a ,f ,lat1 ,lat2 ,latc ,lonc ,eps ,rho ,e, f2sin1, sint, pol1, dum, polc, peq, pol, lat, lon, fact;
}

@property (readonly) NSString *number;

@property Boolean debug;


- (id)initWithData:(NSDictionary *)theData;
- (NSString *)title;


- (CLLocationCoordinate2D)coordinate;

@end
