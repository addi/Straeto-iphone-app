//
//  JSONCleaner.m
//  Straeto
//
//  Created by Árni Jónsson on 19.5.2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JSONCleaner.h"

@implementation JSONCleaner

+ (NSString*)cleanJSONString:(NSString*)json
{	
	NSScanner *scanner = [NSScanner scannerWithString:json];
    [scanner setCharactersToBeSkipped:nil];
    
    NSMutableString *cleanJSON = [NSMutableString string];
	NSString *s = nil;
    NSUInteger offset = 0;
    
    while(![scanner isAtEnd])
    {
        if([scanner scanUpToString:@"," intoString:&s])
        {            
            NSCharacterSet *invalidCharsAfterComma = [NSCharacterSet characterSetWithCharactersInString:@"}],"];
            NSUInteger location = [scanner scanLocation];
            NSUInteger lastGoodLocation = location;
            
            if([json length] < location+1)
                break;
            
            [scanner setScanLocation:location+1];
            [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
            
            NSRange nextCharRange = NSMakeRange([scanner scanLocation], 1);
            
            if(location+1 <= [json length] && [json rangeOfCharacterFromSet:invalidCharsAfterComma options:NSCaseInsensitiveSearch range:nextCharRange].location != NSNotFound)
            {
                [cleanJSON appendString:[json substringWithRange:NSMakeRange(offset, lastGoodLocation-offset)]];
                offset = scanner.scanLocation;
            }
            else
            {
                [cleanJSON appendString:[json substringWithRange:NSMakeRange(offset, lastGoodLocation-offset)]];
                offset = lastGoodLocation;
            }
        }
        else
        {
            if(scanner.scanLocation+1 >= [json length])
                break;
            
            offset += 1;
            [scanner setScanLocation:scanner.scanLocation+1];
        }
    }
    
    [cleanJSON appendString:[json substringWithRange:NSMakeRange(offset, [json length]-offset)]];
    
	return cleanJSON;
}

@end
