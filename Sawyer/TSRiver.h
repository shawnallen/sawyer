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
@property (nonatomic) NSString *description;
@property (nonatomic) NSDate *updatedDate;
@property (nonatomic) NSSet *items;

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

extern NSString * const TSRiverDefaultURLString;

@interface TSRiver : NSObject

@property (nonatomic, readonly) NSArray *feeds;
@property (nonatomic, readonly) NSDate *updatedDate;
@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) NSURL *redirectedURL;
@property (nonatomic, readonly, getter=isRefreshing) BOOL refreshing;

- (id)initWithURL:(NSURL *)url;
- (TSRiverFeed *)feedForIndexPath:(NSIndexPath *)indexPath;
- (TSRiverItem *)itemForIndexPath:(NSIndexPath *)indexPath;
- (void)refreshWithCompletionHandler:(void (^)(NSError *error))handler;

@end
