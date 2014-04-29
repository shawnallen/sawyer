//
//  NSDate+HTTP.h
//
//  Created by Shawn on 4/27/14.
//  Copyright (c) 2014 Sotto, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (HTTP)

+ (NSDate *)dateFromHttpDate:(NSString *)httpDate;
+ (NSDate *)expirationDateFromHTTPURLResponse:(NSHTTPURLResponse *)response;

@end
