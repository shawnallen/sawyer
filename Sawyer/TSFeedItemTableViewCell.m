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
#pragma mark NSObject

- (void)awakeFromNib
{
    self.backgroundView = [[UIView alloc] initWithFrame:self.frame];
    self.backgroundView.alpha = 0.5;
    self.backgroundView.opaque = YES;
}

@end
