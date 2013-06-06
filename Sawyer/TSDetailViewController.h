//
//  TSDetailViewController.h
//  Sawyer
//
//  Created by Shawn on 6/5/13.
//  Copyright (c) 2013 Sotto, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TSRiver.h"

@interface TSDetailViewController : UIViewController <UISplitViewControllerDelegate>


- (void)setDetailItem:(TSRiverItem *)detailItem feed:(TSRiverFeed *)feed;
@end
