//
//  JSONCleaner.h
//  Straeto
//
//  Created by Árni Jónsson on 19.5.2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSONCleaner : NSObject

+ (NSString*)cleanJSONString:(NSString*)json;

@end
