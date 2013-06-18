//
//  TSFeedItemTableViewCell.m
//  Sawyer
//
//  Created by Shawn on 6/5/13.
//  Copyright (c) 2013 Sotto, LLC. All rights reserved.
//

#import "TSFeedItemTableViewCell.h"

@implementation TSFeedItemTableViewCell

#pragma mark -
#pragma mark API

- (void)setAboveWater:(BOOL)aboveWater;
{
    if (_aboveWater == aboveWater)
        return;
    
    _aboveWater = aboveWater;
    [self assertWatermarkState];
}

- (void)setHighwaterMark:(BOOL)highwaterMark;
{
    if (_highwaterMark == highwaterMark)
        return;
    
    _highwaterMark = highwaterMark;
    [self assertWatermarkState];
}

- (void)assertWatermarkState
{
    self.title.textColor = [UIColor darkTextColor];
    self.body.textColor = [UIColor lightGrayColor];
    
    if (_highwaterMark) {
        self.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"wave"]];
        return;
    }
    
    if (_aboveWater)
        self.backgroundView.backgroundColor = [UIColor whiteColor];
    else {
        self.backgroundView.backgroundColor = [UIColor colorWithRed:203.0/255.0 green:217.0/255.0 blue:239.0/255.0 alpha:1.0];
        self.title.textColor = [UIColor blackColor];
        self.body.textColor = [UIColor darkTextColor];
    }
}

- (void)prepareForReuse;
{
    [self assertWatermarkState];
}

#pragma mark -
#pragma mark NSObject

- (void)awakeFromNib
{
    self.backgroundView = [[UIView alloc] initWithFrame:self.frame];
    self.backgroundView.alpha = 0.5;
    self.highwaterMark = NO;
    self.aboveWater = YES;
}

@end
