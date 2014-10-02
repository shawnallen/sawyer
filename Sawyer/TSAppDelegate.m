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
@property (nonatomic) id refreshRiverObserver;
@end

@implementation TSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifndef DEBUG
    [Crashlytics startWithAPIKey:CRASHLYTICS_API_KEY];
#endif
    
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
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
    __block BOOL hasNotifiedCompletionHandler;
    
    self.refreshRiverObserver = [[NSNotificationCenter defaultCenter] addObserverForName:TSRiverManagerCompletedRefreshRiverNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        id refreshRiverObserver = self.refreshRiverObserver;
        self.refreshRiverObserver = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:refreshRiverObserver];

        NSError *error = note.userInfo[@"error"];
        
        if (error != nil) {
            DLog(@"Background fetch failed.");
            if (hasNotifiedCompletionHandler == NO) {
                hasNotifiedCompletionHandler = YES;
                completionHandler(UIBackgroundFetchResultFailed);
            }
        } else {
            DLog(@"Background fetch successful.");
            if (hasNotifiedCompletionHandler == NO) {
                hasNotifiedCompletionHandler = YES;
                completionHandler([whenRiverUpdatedDate compare:[TSRiverManager sharedManager].river.whenRiverUpdatedDate] == NSOrderedSame ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData);
            }
        }
    }];
    
    if ([[TSRiverManager sharedManager] refreshRiverIgnoringCache:NO] == NO) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.refreshRiverObserver];
        self.refreshRiverObserver = nil;
        hasNotifiedCompletionHandler = YES;
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

@end
