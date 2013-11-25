//
//  BusStop.m
//  Straeto
//
//  Created by Árni Jónsson on 23.9.2012.
//
//

#import "BusStop.h"

@implementation BusStop

@synthesize name, distance, routes;

- (id)initWithData:(NSDictionary *)theData
{
    self = [super init];
    
    name = theData[@"short_name"];
    
    distance = [theData[@"distance"] integerValue];
    
    routes = theData[@"routes"];
    
    return self;
}

@end
