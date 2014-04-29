//
//  TSAppDelegate.m
//  Sawyer
//
//  Created by Shawn on 6/5/13.
//  Copyright (c) 2013 Sotto, LLC. All rights reserved.
//

#import "TSAppDelegate.h"
#import "TSRiver.h"

@implementation TSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
    }
    
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
{
    DLog(@"");
    NSDate *whenRiverUpdatedDate = [TSRiverManager sharedManager].river.whenRiverUpdatedDate;
    
    [[TSRiverManager sharedManager] refreshWithCompletionHandler:^(NSError *error) {
        if (error != nil) {
            completionHandler(UIBackgroundFetchResultFailed);
        }
        
        completionHandler([whenRiverUpdatedDate compare:[TSRiverManager sharedManager].river.whenRiverUpdatedDate] == NSOrderedSame ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData);
    } ignoringCache:NO];
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler;
{
    DLog(@"");
    [TSRiverManager sharedManager].sessionCompletionHandler = completionHandler;
}

@end
