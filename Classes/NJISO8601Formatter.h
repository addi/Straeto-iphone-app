/*
 *  NJISO8601Formatter.h
 *  NJFoundation
 *
 *  Created by han9kin on 2012-03-21.
 *  Copyright (c) 2012 NHN. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>


/*
 * NSFormatter for ISO 8601:2004
 *
 * Reference: http://dotat.at/tmp/ISO_8601-2004_E.pdf
 *
 *
 * Supported Formats
 *
 * - Calendar Date
 * - Ordinal Date
 * - Week Date
 * - Local Time with Decimal Fractions
 * - Midnight
 * - Time Zone
 *
 * Unsupported Formats
 *
 * - BC Date (CoreFoundation's Gregorian APIs cannot handle years less then zero)
 * - Basic Format of Ordinal Date Expanded Representation (Year > 9999)
 * - Local Time with Leap Second (Second >= 60.0)
 * - Time Inverval
 * - Duration
 * - Recurring Time Interval
 *
 */


typedef enum
{
    NJISO8601FormatterDateStyleCalendarExtended = 0,    /* Default  (YYYY-MM-DD) */
    NJISO8601FormatterDateStyleCalendarBasic,           /*          (YYYYMMDD)   */
    NJISO8601FormatterDateStyleOrdinalExtended,         /*          (YYYY-DDD)   */
    NJISO8601FormatterDateStyleOrdinalBasic,            /*          (YYYYDDD)    */
    NJISO8601FormatterDateStyleWeekExtended,            /*          (YYYY-Www-D) */
    NJISO8601FormatterDateStyleWeekBasic,               /*          (YYYYWwwD)   */
} NJISO8601FormatterDateStyle;


typedef enum
{
    NJISO8601FormatterTimeStyleExtended = 0,            /* Default  (hh:mm:ss)   */
    NJISO8601FormatterTimeStyleBasic,                   /*          (hhmmss)     */
    NJISO8601FormatterTimeStyleNone,
} NJISO8601FormatterTimeStyle;


typedef enum
{
    NJISO8601FormatterTimeZoneStyleUTC = 0,             /* Default  (Z)          */
    NJISO8601FormatterTimeZoneStyleExtended,            /*          (±hh:mm)     */
    NJISO8601FormatterTimeZoneStyleBasic,               /*          (±hhmm)      */
    NJISO8601FormatterTimeZoneStyleNone,
} NJISO8601FormatterTimeZoneStyle;


typedef enum
{
    NJISO8601FormatterFractionSeparatorComma = 0,       /* Default  (,)          */
    NJISO8601FormatterFractionSeparatorDot,             /*          (.)          */
} NJISO8601FormatterFractionSeparator;


NSDate *NJISO8601DateFromString(NSString *aString);


@interface NJISO8601Formatter : NSFormatter


@property(nonatomic, assign) NJISO8601FormatterDateStyle          dateStyle;
@property(nonatomic, assign) NJISO8601FormatterTimeStyle          timeStyle;
@property(nonatomic, assign) NJISO8601FormatterTimeZoneStyle      timeZoneStyle;
@property(nonatomic, assign) NJISO8601FormatterFractionSeparator  fractionSeparator;
@property(nonatomic, assign) int                                  fractionDigits;
@property(nonatomic, retain) NSTimeZone                          *timeZone;


- (NSDate *)dateFromString:(NSString *)aString;
- (NSString *)stringFromDate:(NSDate *)aDate;


@end
