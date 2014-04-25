//
//  TSActivityUtilities.m
//  Sawyer
//
//  Created by Shawn on 4/25/14.
//  Copyright (c) 2014 Sotto, LLC. All rights reserved.
//

#import "TSActivityUtilities.h"
#import "TUSafariActivity.h"

@implementation TSActivityUtilities

+ (UIActivityViewController *)activityControllerForURL:(NSURL *)url;
{
    if (IsEmpty(url)) {
        return nil;
    }
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:@[[TUSafariActivity new]]];
    [activityViewController setExcludedActivityTypes:@[UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypePrint, UIActivityTypePostToFlickr, UIActivityTypePostToVimeo]];
    return activityViewController;
}

@end
