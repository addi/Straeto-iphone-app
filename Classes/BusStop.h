//
//  BusStop.h
//  Straeto
//
//  Created by Árni Jónsson on 23.9.2012.
//
//

#import <Foundation/Foundation.h>

@interface BusStop : NSObject
{
    NSString *name;
    
    int distance;
    
    NSMutableArray *times;
    
    NSArray *routes;
}

- (id)initWithData:(NSDictionary *)theData;
- (id)initWithName:(NSString*)theName;
- (void)addTime:(NSDictionary*)time;

- (NSInteger)timesCount;
- (NSDictionary*)timeAtRow:(NSInteger)row;


@property (nonatomic, retain) NSString *name;
@property (nonatomic, assign) int distance;


@property (readonly) NSArray *routes;

@end
