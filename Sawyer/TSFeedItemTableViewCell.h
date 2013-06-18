//
//  TSFeedItemTableViewCell.h
//  Sawyer
//
//  Created by Shawn on 6/5/13.
//  Copyright (c) 2013 Sotto, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TSFeedItemTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *body;
@property (weak, nonatomic) IBOutlet UILabel *date;

@property (nonatomic) BOOL highwaterMark;
@property (nonatomic) BOOL aboveWater;

@end
