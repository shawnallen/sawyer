//
//  TSRiverDelegate.h
//  Sawyer
//
//  Created by Shawn Allen on 7/13/13.
//  Copyright (c) 2013 Sotto, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TSRiverDelegate <NSObject>

@required
- (void)performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

@end
