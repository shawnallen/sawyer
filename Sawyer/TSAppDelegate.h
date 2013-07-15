//
//  TSAppDelegate.h
//  Sawyer
//
//  Created by Shawn on 6/5/13.
//  Copyright (c) 2013 Sotto, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TSRiverDelegate.h"

@interface TSAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (weak, nonatomic) id<TSRiverDelegate> riverDelegate;

@end
