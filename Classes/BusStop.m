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
    
    times = [[NSMutableArray alloc] init];
    
    return self;
}

- (id)initWithName:(NSString*)theName
{
    self = [super init];
    
    if (self)
    {
        name = theName;
        
        times = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)addTime:(NSDictionary*)time
{
    int routeNumber = [[time valueForKey:@"route"] intValue];
    
    int insertIndex = 0;
    
    for(NSDictionary *t in times)
    {
        int lookupRouteNumber = [[t valueForKey:@"route"] intValue];
        
        if (lookupRouteNumber >= routeNumber)
        {
            break;
        }
        
        insertIndex++;
    }
    
    [times insertObject:time atIndex:insertIndex];
}

- (NSInteger)timesCount
{
    return [times count];
}

- (NSDictionary*)timeAtRow:(NSInteger)row
{
    return [times objectAtIndex:row];
}

@end
