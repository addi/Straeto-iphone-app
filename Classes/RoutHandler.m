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

- (id)init
{
    self = [super init];
    
    if (self)
    {
        allRoutes = @[@"1", @"2", @"3", @"4", @"5", @"6", @"11", @"12", @"13", @"14", @"15", @"17", @"18", @"19", @"21", @"22", @"23", @"24", @"26", @"27", @"28", @"33", @"34", @"35",@"51",@"52",@"57"];
        
        routes = [NSMutableArray array];
    }
    
    return self;
}

- (void)setUpFromSettings
{
    [routes removeAllObjects];
    
    for (NSString *r in allRoutes)
    {
        NSString *settingName = [NSString stringWithFormat:@"route_%@", r];
        
        if([[NSUserDefaults standardUserDefaults] boolForKey:settingName])
            [routes addObject:r];
    }
}

-(NSString*)url
{
    return [routes componentsJoinedByString:kURLSplitter];
}

-(void)debug
{
    NSLog(@"routes: %@", [routes componentsJoinedByString:@"-"]);
}


@end
