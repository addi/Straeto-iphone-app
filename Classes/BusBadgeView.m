//
//  BusBadgeView.m
//  Straeto
//
//  Created by Árni Jónsson on 18.1.2012.
//  Copyright (c) 2012 Plain Vanilla Games. All rights reserved.
//

#import "BusBadgeView.h"

@implementation BusBadgeView

@synthesize textColor, badgeFont, badgeColor, badgeString;

- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]))
    {
        CGRect frame = self.frame;

        frame.size = CGSizeMake(30.0, 30.0);
        self.frame = frame;
        
        self.badgeFont = [UIFont boldSystemFontOfSize:14.0];

        self.badgeColor = [UIColor colorWithRed:207.0/255.0 green:35.0/255.0 blue:42.0/255.0 alpha:1.0];
        
		self.textColor = [UIColor whiteColor];
        
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (void)setBadgeString:(NSString*)string
{
	if(badgeString != string)
		[badgeString release];
	
	badgeString = [string copy];
	
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect 
{	
	if(badgeString != nil)
	{
		CGSize countSize = [badgeString sizeWithFont:badgeFont];
		
		CGRect countRect = self.bounds;
        
		countRect.size.width = 26.0;
        countRect.size.height = 26.0;

		countRect.origin.x = countRect.origin.x+(self.bounds.size.width - countRect.size.width);
		        
		[badgeColor set];
		
		CGFloat radius = 13.5;		
		UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:countRect cornerRadius:radius];
		
		CGRect textRect = countRect;
		textRect.origin.x = countRect.origin.x + ((countRect.size.width / 2.0) - countSize.width / 2.0);
        
		textRect.origin.y += 4.0;
		
		CGContextRef ctx = UIGraphicsGetCurrentContext();
		CGContextSaveGState(ctx);
		
		[path fill];
        
        [[UIColor whiteColor] set];
        
        [path stroke];
		
		CGContextRestoreGState(ctx);
		
		[textColor set];
		
		[badgeString drawInRect:textRect withFont:badgeFont];
	}
}

- (void)dealloc
{
	[badgeString release];
	[textColor release];
	[badgeColor release];
	[badgeFont release];

    [super dealloc];
}

@end
