//
//  TSMasterViewController.h
//  Sawyer
//
//  Created by Shawn on 6/5/13.
//  Copyright (c) 2013 Sotto, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TSRiverDelegate.h"

@class TSDetailViewController;

@interface TSMasterViewController : UITableViewController<TSRiverDelegate>

@property (strong, nonatomic) TSDetailViewController *detailViewController;

@end
