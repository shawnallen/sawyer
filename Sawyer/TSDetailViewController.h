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

@property (strong, nonatomic) TSRiverItem *riverItem;

@property (weak, nonatomic) IBOutlet UIView *detailEnclosingView;
@property (weak, nonatomic) IBOutlet UIButton *linkButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *publishedDate;
@property (weak, nonatomic) IBOutlet UITextView *body;
@property (weak, nonatomic) IBOutlet UILabel *noContentSelectedLabel;

- (void)setDetailItem:(TSRiverItem *)newDetailItem;

@end
