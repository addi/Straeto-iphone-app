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
    
    NSArray *routes;
}

- (id)initWithData:(NSDictionary *)theData;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) int distance;


@property (readonly) NSArray *routes;

@end
