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
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
    }
    
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
{
    DLog(@"");
    NSDate *whenRiverUpdatedDate = [TSRiverManager sharedManager].river.whenRiverUpdatedDate;
    
    self.refreshRiverObserver = [[NSNotificationCenter defaultCenter] addObserverForName:TSRiverManagerCompletedRefreshRiverNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        NSError *error = note.userInfo[@"error"];
        
        if (error != nil) {
            DLog(@"Background fetch failed.");
            completionHandler(UIBackgroundFetchResultFailed);
        } else {
            DLog(@"Background fetch successful.");
            completionHandler([whenRiverUpdatedDate compare:[TSRiverManager sharedManager].river.whenRiverUpdatedDate] == NSOrderedSame ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData);
        }

        [[NSNotificationCenter defaultCenter] removeObserver:self.refreshRiverObserver];
        self.refreshRiverObserver = nil;
    }];
    
    if ([[TSRiverManager sharedManager] refreshRiverIgnoringCache:NO] == NO) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.refreshRiverObserver];
        self.refreshRiverObserver = nil;
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler;
{
    DLog(@"");
    [TSRiverManager sharedManager].sessionCompletionHandler = completionHandler;
}

@end
