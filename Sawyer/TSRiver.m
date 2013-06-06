//
//  TSRiver.m
//  Sawyer
//
//  Created by Shawn on 6/5/13.
//  Copyright (c) 2013 Sotto, LLC. All rights reserved.
//

#import "TSRiver.h"

@implementation TSRiverFeed

@end

@implementation TSRiverEnclosure

@end

@implementation TSRiverItem

@end

NSString * const TSRiverDefaultURLString = @"http://dl.dropbox.com/u/19672994/newsriver/admin.json";

@interface TSRiver ()

@property (nonatomic, readwrite) NSArray *feeds;
@property (nonatomic, readwrite) NSDate *updatedDate;
@property (nonatomic, readwrite) NSURL *url;
@property (nonatomic, readwrite) NSURL *redirectedURL;
@property (nonatomic, readwrite) BOOL refreshing;
@property (nonatomic) NSString *version;
@property (nonatomic) NSDate *whenRiverUpdatedDate;

@property (nonatomic) NSOperationQueue *fetchQueue;
@property (nonatomic) NSError *lastError;

- (BOOL)populateRiverFromData:(NSData *)data error:(NSError **)error;

+ (NSDateFormatter *)dateFormatter;

@end

@implementation TSRiver

#pragma mark -
#pragma mark Class extension

+ (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *__RFC1123DateFormatter;  // RFC 1123 date format - Sun, 06 Nov 1994 08:49:37 GMT
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        [dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss z"];
        __RFC1123DateFormatter = dateFormatter;
    });
    return __RFC1123DateFormatter;
}

- (BOOL)populateRiverFromData:(NSData *)data error:(NSError **)error;
{
    NSDictionary *newRiver = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    
    if (IsEmpty(newRiver))
        return NO;
    
    [self setWhenRiverUpdatedDate:[[TSRiver dateFormatter] dateFromString:[newRiver valueForKeyPath:@"metadata.whenGMT"]]];
    [self setVersion:[newRiver valueForKeyPath:@"metadata.version"]];
    
    NSArray *updatedFeeds = [newRiver valueForKeyPath:@"updatedFeeds.updatedFeed"];
    NSMutableArray *newFeeds = [NSMutableArray arrayWithCapacity:[updatedFeeds count]];
    
    for (NSDictionary *feed in updatedFeeds) {
        TSRiverFeed *newFeed = [[TSRiverFeed alloc] init];
        NSString *urlString = feed[@"feedUrl"];
        
        if (IsEmpty(urlString) == NO)
            [newFeed setUrl:[NSURL URLWithString:urlString]];
        
        NSString *websiteUrlString = feed[@"websiteUrl"];
        
        if (IsEmpty(websiteUrlString) == NO)
            [newFeed setWebsite:[NSURL URLWithString:websiteUrlString]];
        
        [newFeed setTitle:feed[@"feedTitle"]];
        [newFeed setDescription:feed[@"feedDescription"]];

        NSString *whenLastUpdateString = feed[@"whenLastUpdate"];
        
        if (IsEmpty(whenLastUpdateString) == NO)
            [newFeed setUpdatedDate:[[TSRiver dateFormatter] dateFromString:whenLastUpdateString]];
        
        NSMutableSet *newItems = [NSMutableSet setWithCapacity:[feed[@"item"] count]];
        
        for (NSDictionary *item in feed[@"item"]) {
            TSRiverItem *newItem = [[TSRiverItem alloc] init];
            
            [newItem setBody:item[@"body"]];

            NSString *permalinkUrlString = item[@"permaLink"];
            
            if (IsEmpty(permalinkUrlString) == NO)
                [newItem setPermaLink:[NSURL URLWithString:permalinkUrlString]];
            
            NSString *pubDateString = item[@"pubDate"];
            
            if (IsEmpty(pubDateString) == NO)
                [newItem setPublicationDate:[[TSRiver dateFormatter] dateFromString:pubDateString]];

            [newItem setTitle:item[@"title"]];
            
            NSString *linkString = item[@"link"];
            
            if (IsEmpty(linkString) == NO)
                [newItem setLink:[NSURL URLWithString:linkString]];
            
            NSArray *enclosure = item[@"enclosure"];
            
            if (IsEmpty(enclosure) == NO) {
                TSRiverEnclosure *newEnclosure = [[TSRiverEnclosure alloc] init];
        
                NSString *urlString = enclosure[0][@"url"];
                
                if (IsEmpty(urlString) == NO)
                    [newEnclosure setUrl:[NSURL URLWithString:urlString]];
                
                [newEnclosure setMIMEType:enclosure[0][@"type"]];
                [newEnclosure setLength:[enclosure[0][@"length"] integerValue]];
                [newItem setEnclosure:newEnclosure];
            }
    
            [newItem setIdentifier:item[@"id"]];
            [newItems addObject:newItem];
        }
        
        [newFeed setItems:newItems];
        [newFeeds addObject:newFeed];
    }
    
    [self setFeeds:newFeeds];
    
    return YES;
}

#pragma mark -
#pragma mark API

- (id)initWithURL:(NSURL *)url;
{
    self = [super init];
    
    if (self) {
        [self setUrl:url];
        [self setUpdatedDate:[NSDate distantPast]];
        [self setFeeds:[NSArray array]];
        [self setLastError:nil];
        [self setFetchQueue:[[NSOperationQueue alloc] init]];
        [[self fetchQueue] setName:@"TSRiverFetchQueue"];
    }
    
    return self;
}

- (BOOL)isRefreshing;
{
    return _refreshing;
}

- (TSRiverItem *)itemForIndexPath:(NSIndexPath *)indexPath;
{
    TSRiverFeed *feed = [self feeds][[indexPath section]];
    return [[feed items] allObjects][[indexPath row]];
}

- (void)refreshWithCompletionHandler:(void (^)(NSError *))handler;
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[self url]];
    
    if ([self isRefreshing]) {
        ALog(@"Superfluous call to refresh river [%@].", self);

        [[self fetchQueue] addOperationWithBlock:^{
            handler([self lastError]);
        }];
        
        return;
    }
    
    [self setLastError:nil];
    [self setRefreshing:YES];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[self fetchQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            SOAssert([NSRunLoop mainRunLoop] == [NSRunLoop currentRunLoop], @"Potential user interface interaction not occurring on the main run loop");
            
            [self setLastError:error];
            [self setRefreshing:NO];
            
            if (error != nil) {
                handler(error);
                return;
            }
            
            [self setUpdatedDate:[NSDate date]];
            // TODO: Set redirected URL based on the properties of the response
            
            NSError *deserializationError;
            
            if ([self populateRiverFromData:data error:&deserializationError] == NO)
                [self setLastError:deserializationError];
            
            handler(error);
        }];
    }];
}


#pragma mark -
#pragma mark NSObject

- (id)init
{
    return [self initWithURL:[NSURL URLWithString:TSRiverDefaultURLString]];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"TSRiver [(%@) updated:%@, riverUpdated:%@, version:%@]", [self url], [self updatedDate] == [NSDate distantPast] ? @"(none)" : [self updatedDate], [self whenRiverUpdatedDate] == nil ? @"(unknown)" : [self whenRiverUpdatedDate], [self version] == nil ? @"(unknown)" : [self version]];
}

@end
