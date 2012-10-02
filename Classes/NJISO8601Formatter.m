/*
 *  NJISO8601Formatter.m
 *  NJFoundation
 *
 *  Created by han9kin on 2012-03-21.
 *  Copyright (c) 2012 NHN. All rights reserved.
 *
 */

#import "NJISO8601Formatter.h"


id NJISO8601ParseString(NSString *aString, NSString **aError);


static BOOL NJIsLeapYear(int aYear)
{
    if ((((aYear % 4) == 0) && ((aYear % 100) != 0)) || ((aYear % 400) == 0))
    {
        return YES;
    }
    else
    {
        return NO;
    }
}


static int NJDayOfYearFromCalendarDate(int aYear, int aMonth, int aDay)
{
    static int sDays365[] = { 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 };
    static int sDays366[] = { 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335 };

    NSCParameterAssert(aMonth >= 1);
    NSCParameterAssert(aMonth <= 12);

    if (NJIsLeapYear(aYear))
    {
        return sDays366[aMonth - 1] + aDay;
    }
    else
    {
        return sDays365[aMonth - 1] + aDay;
    }
}


static int NJWeekOfYearFromCalendarDate(int *aYear, int aMonth, int aDay, int aDayOfWeek)
{
    /*
     * Algorithm from http://en.wikipedia.org/wiki/Talk:ISO_week_date#Algorithms
     */

    int sThursday;
    int sThursdayOrdinal;

    sThursday = aDay + 4 - aDayOfWeek;

    if ((aMonth == 12) && (sThursday > 31))
    {
        *aYear    += 1;
        aMonth     = 1;
        sThursday -= 31;
    }
    else if ((aMonth == 1) && (sThursday < 1))
    {
        *aYear    -= 1;
        aMonth     = 12;
        sThursday += 31;
    }

    sThursdayOrdinal = NJDayOfYearFromCalendarDate(*aYear, aMonth, sThursday);

    return 1 + (sThursdayOrdinal - 1) / 7;
}


static BOOL NJISO8601GetObjectFromString(id *aObject, NSString *aString, NSString **aError)
{
    NSString *sError = nil;
    id        sObject;

    if (aString)
    {
        sObject = NJISO8601ParseString(aString, &sError);
    }
    else
    {
        sObject = nil;
        sError  = @"Null string.";
    }

    if (sObject)
    {
        if (aObject)
        {
            *aObject = sObject;
        }

        return YES;
    }
    else
    {
        if (aError)
        {
            *aError = sError;
        }

        return NO;
    }
}


NSDate *NJISO8601DateFromString(NSString *aString)
{
    if (aString)
    {
        id sObject;

        if (NJISO8601GetObjectFromString(&sObject, aString, NULL))
        {
            return [sObject isKindOfClass:[NSDate class]] ? sObject : nil;
        }
    }

    return nil;
}


@interface NJISO8601Formatter ()
{
    NJISO8601FormatterDateStyle          mDateStyle;
    NJISO8601FormatterTimeStyle          mTimeStyle;
    NJISO8601FormatterTimeZoneStyle      mTimeZoneStyle;
    NJISO8601FormatterFractionSeparator  mFractionSeparator;
    int                                  mFractionDigits;
    NSTimeZone                          *mTimeZone;
}

@end


@implementation NJISO8601Formatter (Formatting)


- (BOOL)appendDateStringWithYear:(int)aYear month:(int)aMonth day:(int)aDay absoluteTime:(CFAbsoluteTime)aAbsoluteTime timeZone:(CFTimeZoneRef)aTimeZone toString:(NSMutableString *)aString
{
    int sDayOfWeek;
    int sWeekOfYear;

    if ((mDateStyle == NJISO8601FormatterDateStyleWeekExtended) || (mDateStyle == NJISO8601FormatterDateStyleWeekBasic))
    {
        sDayOfWeek  = CFAbsoluteTimeGetDayOfWeek(aAbsoluteTime, aTimeZone);
        sWeekOfYear = NJWeekOfYearFromCalendarDate(&aYear, aMonth, aDay, sDayOfWeek);
    }

    if ((aYear < 0) || (aYear > 9999))
    {
        if (mDateStyle == NJISO8601FormatterDateStyleOrdinalBasic)
        {
            return NO;
        }

        [aString appendFormat:@"%+.4d", aYear];
    }
    else
    {
        [aString appendFormat:@"%.4d", aYear];
    }

    switch (mDateStyle)
    {
        case NJISO8601FormatterDateStyleCalendarExtended:
            [aString appendFormat:@"-%02d-%02d", aMonth, aDay];
            break;
        case NJISO8601FormatterDateStyleCalendarBasic:
            [aString appendFormat:@"%02d%02d", aMonth, aDay];
            break;
        case NJISO8601FormatterDateStyleOrdinalExtended:
            [aString appendFormat:@"-%03d", NJDayOfYearFromCalendarDate(aYear, aMonth, aDay)];
            break;
        case NJISO8601FormatterDateStyleOrdinalBasic:
            [aString appendFormat:@"%03d", NJDayOfYearFromCalendarDate(aYear, aMonth, aDay)];
            break;
        case NJISO8601FormatterDateStyleWeekExtended:
            [aString appendFormat:@"-W%02d-%d", sWeekOfYear, sDayOfWeek];
            break;
        case NJISO8601FormatterDateStyleWeekBasic:
            [aString appendFormat:@"W%02d%d", sWeekOfYear, sDayOfWeek];
            break;
    }

    return YES;
}


- (void)appendTimeStringWithHour:(int)aHour minute:(int)aMinute second:(double)aSecond toString:(NSMutableString *)aString
{
    if (mTimeStyle == NJISO8601FormatterTimeStyleExtended)
    {
        [aString appendFormat:@"T%02d:%02d:", aHour, aMinute];
    }
    else
    {
        [aString appendFormat:@"T%02d%02d", aHour, aMinute];
    }

    if (mFractionDigits > 0)
    {
        [aString appendFormat:@"%0*.*lf", (mFractionDigits + 3), mFractionDigits, aSecond];

        if (mFractionSeparator == NJISO8601FormatterFractionSeparatorComma)
        {
            [aString replaceCharactersInRange:NSMakeRange([aString length] - mFractionDigits - 1, 1) withString:@","];
        }
    }
    else
    {
        [aString appendFormat:@"%02.0lf", aSecond];
    }
}


- (void)appendTimeZoneStringForTimeZone:(CFTimeZoneRef)aTimeZone absoluteTime:(CFAbsoluteTime)aAbsoluteTime toString:(NSMutableString *)aString
{
    if (mTimeZoneStyle == NJISO8601FormatterTimeZoneStyleNone)
    {
    }
    else if (mTimeZoneStyle == NJISO8601FormatterTimeZoneStyleUTC)
    {
        [aString appendFormat:@"Z"];
    }
    else
    {
        NSInteger sMinutesFromGMT = (NSInteger)CFTimeZoneGetSecondsFromGMT(aTimeZone, aAbsoluteTime) / 60;

        if (sMinutesFromGMT < 0)
        {
            sMinutesFromGMT *= -1;

            [aString appendFormat:@"-%02d", (sMinutesFromGMT / 60)];
        }
        else
        {
            [aString appendFormat:@"+%02d", (sMinutesFromGMT / 60)];
        }

        if (mTimeZoneStyle == NJISO8601FormatterTimeZoneStyleExtended)
        {
            [aString appendFormat:@":%02d", (sMinutesFromGMT % 60)];
        }
        else
        {
            [aString appendFormat:@"%02d", (sMinutesFromGMT % 60)];
        }
    }
}


@end


@implementation NJISO8601Formatter


@synthesize dateStyle         = mDateStyle;
@synthesize timeStyle         = mTimeStyle;
@synthesize timeZoneStyle     = mTimeZoneStyle;
@synthesize fractionSeparator = mFractionSeparator;
@synthesize fractionDigits    = mFractionDigits;
@synthesize timeZone          = mTimeZone;


- (void)dealloc
{
    [mTimeZone release];
    [super dealloc];
}


- (NSString *)stringForObjectValue:(id)aObject
{
    if ([aObject isKindOfClass:[NSDate class]])
    {
        return [self stringFromDate:aObject];
    }
    else
    {
        return nil;
    }
}


- (BOOL)getObjectValue:(id *)aObject forString:(NSString *)aString errorDescription:(NSString **)aError
{
    return NJISO8601GetObjectFromString(aObject, aString, aError);
}


- (NSDate *)dateFromString:(NSString *)aString
{
    return NJISO8601DateFromString(aString);
}


- (NSString *)stringFromDate:(NSDate *)aDate
{
    if (aDate)
    {
        NSMutableString *sString;
        CFTimeZoneRef    sTimeZone;
        CFAbsoluteTime   sAbsoluteTime;
        CFGregorianDate  sGregorianDate;

        sString = [NSMutableString string];

        if (mTimeZoneStyle == NJISO8601FormatterTimeZoneStyleUTC)
        {
            sTimeZone = NULL;
        }
        else
        {
            sTimeZone = (CFTimeZoneRef)(mTimeZone ? mTimeZone : [NSTimeZone localTimeZone]);
        }

        sAbsoluteTime  = [aDate timeIntervalSinceReferenceDate];
        sGregorianDate = CFAbsoluteTimeGetGregorianDate(sAbsoluteTime, sTimeZone);

        if (![self appendDateStringWithYear:sGregorianDate.year month:sGregorianDate.month day:sGregorianDate.day absoluteTime:sAbsoluteTime timeZone:sTimeZone toString:sString])
        {
            return nil;
        }

        if (mTimeStyle != NJISO8601FormatterTimeStyleNone)
        {
            [self appendTimeStringWithHour:sGregorianDate.hour minute:sGregorianDate.minute second:sGregorianDate.second toString:sString];
            [self appendTimeZoneStringForTimeZone:sTimeZone absoluteTime:sAbsoluteTime toString:sString];
        }

        return sString;
    }
    else
    {
        return nil;
    }
}


@end
