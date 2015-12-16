//
//  TSAppDelegate.m
//  Sawyer
//
//  Created by Shawn on 6/5/13.
//  Copyright (c) 2013 Sotto, LLC. All rights reserved.
//

#import "TSAppDelegate.h"
#import "TSRiver.h"

@interface TSAppDelegate ()
@end

@implementation TSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
        splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    }
    
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application;
{
    DLog(@"");
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
{
    DLog(@"");
    NSDate *whenRiverUpdatedDate = [TSRiverManager sharedManager].river.whenRiverUpdatedDate;
    __block BOOL hasCompletionHandlerBeenInvoked = NO;
    __block id refreshRiverObserver = [[NSNotificationCenter defaultCenter] addObserverForName:TSRiverManagerCompletedRefreshRiverNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [[NSNotificationCenter defaultCenter] removeObserver:refreshRiverObserver];
        
        if (hasCompletionHandlerBeenInvoked) {
            return;
        } else {
            hasCompletionHandlerBeenInvoked = YES;
        }

        NSError *error = note.userInfo[@"error"];
        
        if (error != nil) {
            DLog(@"Background fetch failed.");
            completionHandler(UIBackgroundFetchResultFailed);
        } else {
            DLog(@"Background fetch successful.");
            completionHandler([whenRiverUpdatedDate compare:[TSRiverManager sharedManager].river.whenRiverUpdatedDate] == NSOrderedSame ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData);
        }
    }];
    
    if ([[TSRiverManager sharedManager] refreshRiverIgnoringCache:NO] == NO) {
        [[NSNotificationCenter defaultCenter] removeObserver:refreshRiverObserver];
        
        if (hasCompletionHandlerBeenInvoked) {
            return;
        }

        hasCompletionHandlerBeenInvoked = YES;
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

@end
