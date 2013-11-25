//
//  RoutHandler.h
//  Straeto
//
//  Created by Árni Jónsson on 20.4.2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <MapKit/MapKit.h>

@interface RoutHandler : NSObject
{
    NSArray *allRoutes;

    NSMutableArray *routes;
}

- (void)setUpFromSettings;

-(NSString*)url;
-(void)debug;

@end
