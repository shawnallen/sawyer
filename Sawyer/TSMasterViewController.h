//
//  TSMasterViewController.h
//  Sawyer
//
//  Created by Shawn on 6/5/13.
//  Copyright (c) 2013 Sotto, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TSDetailViewController;

@interface TSMasterViewController : UITableViewController

@property (strong, nonatomic) TSDetailViewController *detailViewController;

@end
