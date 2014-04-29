//
//  NSDate+HTTP.m
//
//  Created by Shawn on 4/27/14.
//  Copyright (c) 2014 Sotto, LLC. All rights reserved.
//

#import "NSDate+HTTP.h"

@implementation NSDate (HTTP)

+ (NSDateFormatter *)RFC1123DateFormatter;
{
    static NSDateFormatter *__RFC1123DateFormatter;  // RFC 1123 date format - Sun, 06 Nov 1994 08:49:37 GMT

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __RFC1123DateFormatter = createDateFormatter(@"EEE, dd MMM yyyy HH:mm:ss z");
    });
    return __RFC1123DateFormatter;
}

+ (NSDateFormatter *)ANSICDateFormatter;
{
    static NSDateFormatter *__ANSICDateFormatter;  // ANSI C date format - Sun Nov  6 08:49:37 1994
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __ANSICDateFormatter = createDateFormatter(@"EEE MMM d HH:mm:ss yyyy");
    });
    return __ANSICDateFormatter;
}

+ (NSDateFormatter *)RFC850DateFormatter;
{
    static NSDateFormatter *__RFC850DateFormatter;  // RFC 850 date format - Sunday, 06-Nov-94 08:49:37 GMT
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __RFC850DateFormatter = createDateFormatter(@"EEEE, dd-MMM-yy HH:mm:ss z");
    });
    return __RFC850DateFormatter;
}

static inline NSDateFormatter* createDateFormatter(NSString *format)
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    [dateFormatter setDateFormat:format];
    return dateFormatter;
}

+ (NSDate *)dateFromHttpDate:(NSString *)httpDate
{
    static dispatch_queue_t _httpDateQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _httpDateQueue = dispatch_queue_create("com.pearson.NSDate_HTTP", DISPATCH_QUEUE_SERIAL);
    });
    
    __block NSDate *date = nil;
    
    if (IsEmpty(httpDate))
        return nil;
    
    dispatch_sync(_httpDateQueue, ^{
        date = [[NSDate RFC1123DateFormatter] dateFromString:httpDate];
        
        if (date != nil)
            return;
        
        date = [[NSDate ANSICDateFormatter] dateFromString:httpDate];
        
        if (date != nil)
            return;
        
        date = [[NSDate RFC850DateFormatter] dateFromString:httpDate];
    });
    
    return date;
}

+ (NSDate *)expirationDateFromHTTPURLResponse:(NSHTTPURLResponse *)response
{
    switch ([response statusCode]) {
        case 200:
        case 203:
        case 300:
        case 301:
        case 302:
        case 307:
        case 410:
            // Cacheable
            break;
        default:
            // Uncacheable
            return nil;
    }
    
    NSDictionary *headers = [response allHeaderFields];
    
    // TASK: Pragma: no-cache
    if ([[headers objectForKey:@"Pragma"] isEqualToString:@"no-cache"])
        return nil;
    
    NSDate *determinedNow = [NSDate dateFromHttpDate:[headers objectForKey:@"Date"]];

    if (determinedNow == nil)
        determinedNow = [NSDate date];
    
    // TASK: Cache-Control

    NSString *cacheControl = [[headers objectForKey:@"Cache-Control"] lowercaseString];

    if (cacheControl) {
        NSRange foundRange = [cacheControl rangeOfString:@"no-store"];
        if (foundRange.length > 0)
            return nil;
        
        foundRange = [cacheControl rangeOfString:@"max-age"];
        
        if (foundRange.length > 0) {
            NSScanner *cacheControlScanner = [NSScanner scannerWithString:cacheControl];
            [cacheControlScanner setScanLocation:foundRange.location + foundRange.length];
            [cacheControlScanner scanString:@"=" intoString:nil];
            
            NSInteger maxAge;
        
            if ([cacheControlScanner scanInteger:&maxAge]) {
                if (maxAge > 0)
                    return [[NSDate alloc] initWithTimeInterval:maxAge sinceDate:determinedNow];
                else
                    return nil;
            }
        }
    }
    
    // TASK: No Cache-Control found, look for Expires
    NSString *expires = [headers objectForKey:@"Expires"];

    if (expires) {
        NSTimeInterval expirationInterval = 0;
        NSDate *expirationDate = [NSDate dateFromHttpDate:expires];

        if (expirationDate)
            expirationInterval = [expirationDate timeIntervalSinceDate:determinedNow];
        
        if (expirationInterval > 0)
            return [NSDate dateWithTimeIntervalSinceNow:expirationInterval];  // Convert to relative expiration date
        else
            return nil;
    }
    
    if ([response statusCode] == 302 || [response statusCode] == 307)
        return nil;  // No explicit cache control defined, do not cache
    
    // TASK: No explicit cache headers provided.  Attempt to determine from Last-Modified
    NSString *lastModified = [headers objectForKey:@"Last-Modified"];

    if (lastModified) {
        NSTimeInterval age = 0;
        NSDate *lastModifiedDate = [NSDate dateFromHttpDate:lastModified];

        if (lastModifiedDate)
            age = [determinedNow timeIntervalSinceDate:lastModifiedDate];  // Calculate the age of the response by comparing the Date header with the Last-Modified header

        if (age > 0)
            return [NSDate dateWithTimeInterval:(age * 0.10f) sinceDate:determinedNow];  // Last-Modified suggestion by RFC 2616 section 13.2.4
        else
            return nil;
    }
    
    return [NSDate dateWithTimeInterval:(60 * 60 * 1) sinceDate:determinedNow];  // Default to cache for 1 hour from "now"?
}

@end
