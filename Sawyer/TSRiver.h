//
//  TSRiver.h
//  Sawyer
//
//  Created by Shawn on 6/5/13.
//  Copyright (c) 2013 Sotto, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSRiverEnclosure : NSObject

@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *MIMEType;
@property (nonatomic) NSInteger length;

@end

@interface TSRiverFeed : NSObject

@property (nonatomic) NSURL *url;
@property (nonatomic) NSURL *website;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *feedDescription;
@property (nonatomic) NSDate *updatedDate;
@property (nonatomic) NSArray *items;

@end

@interface TSRiverItem : NSObject

@property (nonatomic) NSString *body;
@property (nonatomic) NSURL *permaLink;
@property (nonatomic) NSDate *publicationDate;
@property (nonatomic) NSString *title;
@property (nonatomic) NSURL *link;
@property (nonatomic) TSRiverEnclosure *enclosure;
@property (nonatomic) NSString *identifier;

@end

@interface TSRiver : NSObject

@property (nonatomic, readonly) NSArray *feeds;
@property (nonatomic, readonly) NSDate *fetchedDate;
@property (nonatomic, readonly) NSDate *whenRiverUpdatedDate;
@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) NSURL *originalURL;  // If HTTP Server redirection occurs, the URL for the River may differ.

- (TSRiverItem *)itemForIdentifier:(NSString *)identifier;

@end

extern NSString * const TSRiverManagerBeganRefreshRiverNotification;
extern NSString * const TSRiverManagerWillRefreshRiverNotification;
extern NSString * const TSRiverManagerDidRefreshRiverNotification;
extern NSString * const TSRiverManagerCompletedRefreshRiverNotification;
extern NSString * const TSRiverDefaultURLString;

@interface TSRiverManager : NSObject

@property (nonatomic, readonly) TSRiver *river;
@property (nonatomic, readonly) BOOL isLoading;
@property (nonatomic, readonly) NSError *lastError;

+ (TSRiverManager *)sharedManager;

- (BOOL)refreshRiverIgnoringCache:(BOOL)ignoringCache;

@end
