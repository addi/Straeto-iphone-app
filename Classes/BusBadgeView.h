//
//  BusBadgeView.h
//  Straeto
//
//  Created by Árni Jónsson on 18.1.2012.
//  Copyright (c) 2012 Plain Vanilla Games. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface BusBadgeView : MKAnnotationView
{
	UIFont *badgeFont;
	UIColor *badgeColor, *textColor;
	NSString *badgeString;
}

@property (nonatomic, readwrite, strong) UIFont *badgeFont;
@property (nonatomic, readwrite, strong) UIColor *badgeColor, *textColor;
@property (nonatomic, readwrite, strong) NSString *badgeString;


@end
