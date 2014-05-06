//
//  TSRiver.m
//  Sawyer
//
//  Created by Shawn on 6/5/13.
//  Copyright (c) 2013 Sotto, LLC. All rights reserved.
//

#import "TSRiver.h"
#import "NSDate+HTTP.h"

@implementation TSRiverEnclosure

@end

@implementation TSRiverFeed

@end

@implementation TSRiverItem

- (NSUInteger)hash;
{
    return [self identifier] == nil ? (NSUInteger)self : [[self identifier] hash];
}

- (BOOL)isEqual:(id)other;
{
    if ([other isKindOfClass:[self class]] == NO)
        return NO;
    
    return [self hash] == [other hash];
}

@end

NSString * const TSRiverDefaultURLString = @"http://static.scripting.com/river3/rivers/iowa.js";
NSString * const TSRiverDefaultPaddingFunctionName = @"onGetRiverStream";

@interface TSRiver ()

@property (nonatomic, readwrite) NSArray *feeds;
@property (nonatomic, readwrite) NSDate *fetchedDate;
@property (nonatomic, readwrite) NSDate *whenRiverUpdatedDate;
@property (nonatomic, readwrite) NSURL *url;
@property (nonatomic, readwrite) NSURL *originalURL;
@property (nonatomic) NSString *version;
@property (nonatomic) NSString *paddingFunctionName;

- (id)initWithURL:(NSURL *)url;
- (BOOL)populateRiverFromData:(NSData *)data error:(NSError **)error;

@end

@implementation TSRiver

#pragma mark -
#pragma mark Class extension

- (BOOL)populateRiverFromData:(NSData *)data error:(NSError **)error;
{
    __block NSDictionary *newRiver;
    
    performOnMainThread(^{
        UIWebView *deserializationWebView = [[UIWebView alloc] init];
        NSString *riverJavaScript = [NSString stringWithFormat:@"function %@(river){return JSON.stringify(river);};%@;", self.paddingFunctionName, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        
        NSString *riverResult = [deserializationWebView stringByEvaluatingJavaScriptFromString:riverJavaScript];
        newRiver = [NSJSONSerialization JSONObjectWithData:[riverResult dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES] options:0 error:error];
    });
    
    if (IsEmpty(newRiver)) {
        return *error != nil;
    }
    
    [self setWhenRiverUpdatedDate:[NSDate dateFromHttpDate:[newRiver valueForKeyPath:@"metadata.whenGMT"]]];
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
            [newFeed setUpdatedDate:[NSDate dateFromHttpDate:whenLastUpdateString]];
        
        NSMutableArray *newItems = [NSMutableArray arrayWithCapacity:[feed[@"item"] count]];
        
        for (NSDictionary *item in feed[@"item"]) {
            TSRiverItem *newItem = [[TSRiverItem alloc] init];
            
            [newItem setBody:item[@"body"]];

            NSString *permalinkUrlString = item[@"permaLink"];
            
            if (IsEmpty(permalinkUrlString) == NO)
                [newItem setPermaLink:[NSURL URLWithString:permalinkUrlString]];
            
            NSString *pubDateString = item[@"pubDate"];
            
            if (IsEmpty(pubDateString) == NO)
                [newItem setPublicationDate:[NSDate dateFromHttpDate:pubDateString]];

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
        
        [newItems sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"publicationDate" ascending:NO]]];
        
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
        [self setFetchedDate:[NSDate distantPast]];
        [self setWhenRiverUpdatedDate:[NSDate distantPast]];
        [self setFeeds:[NSArray array]];
        [self setPaddingFunctionName:TSRiverDefaultPaddingFunctionName];
    }
    
    return self;
}

- (TSRiverItem *)itemForIdentifier:(NSString *)identifier;
{
    if (IsEmpty(identifier))
        return nil;
    
    for (TSRiverFeed *feed in [self feeds]) {
        for (TSRiverItem *item in [feed items]) {
            if ([[item identifier] isEqualToString:identifier])
                return item;
        }
    }
    
    return nil;
}

#pragma mark -
#pragma mark NSObject

- (id)init
{
    return [self initWithURL:[NSURL URLWithString:TSRiverDefaultURLString]];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"TSRiver [(%@) updated:%@, riverUpdated:%@, version:%@]", [self url], [self fetchedDate] == [NSDate distantPast] ? @"(none)" : [self fetchedDate], [self whenRiverUpdatedDate] == nil ? @"(unknown)" : [self whenRiverUpdatedDate], [self version] == nil ? @"(unknown)" : [self version]];
}

@end

NSString * const TSRiverManagerBeganRefreshRiverNotification = @"TSRiverManagerBeganRefreshRiverNotification";
NSString * const TSRiverManagerWillRefreshRiverNotification = @"TSRiverManagerWillRefreshRiverNotification";
NSString * const TSRiverManagerDidRefreshRiverNotification = @"TSRiverManagerDidRefreshRiverNotification";
NSString * const TSRiverManagerURLSessionConfigurationIdentifier = @"TSRiverManagerURLSessionConfigurationIdentifier";
NSString * const TSRiverManagerCompletedRefreshRiverNotification = @"TSRiverManagerCompletedRefreshRiverNotification";
NSString * const TSRiverManagerRiverURLKey = @"river_url";
NSTimeInterval const TSRiverUpdateInterval = 60 * 20;  // 20 minute time interval

@interface TSRiverManager () <NSURLSessionDelegate, NSURLSessionDownloadDelegate>
@property (nonatomic, readwrite) TSRiver *river;
@property (nonatomic, readwrite) BOOL isLoading;
@property (nonatomic, readwrite) NSError *lastError;
@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSOperationQueue *sessionQueue;
@property (nonatomic) NSURLSessionDownloadTask *currentTask;

- (TSRiver *)initialRiver;
- (BOOL)shouldRiverBeUpdated;
- (void)updateRiverFromRequest:(NSURLRequest *)request response:(NSURLResponse *)response data:(NSData *)data;
- (void)userDefaultsDidChange:(NSNotification *)notification;
@end

@implementation TSRiverManager

#pragma mark -
#pragma mark Class extension

- (TSRiver *)initialRiver;
{
    DLog(@"");
    NSString *riverURLString = [[NSUserDefaults standardUserDefaults] stringForKey:TSRiverManagerRiverURLKey];
    
    if (IsEmpty(riverURLString)) {
        return [TSRiver new];
    }
    
    NSURL *riverURL = [NSURL URLWithString:riverURLString];
    
    if (riverURL == nil) {
        ALog(@"Invalid River URL was specified [%@].", riverURLString);
        return [TSRiver new];
    }

    TSRiver *initialRiver = [[TSRiver alloc] initWithURL:riverURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:initialRiver.url];
    NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    
    if (cachedResponse != nil) {
        NSError *error;
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)cachedResponse.response;
        initialRiver.fetchedDate = [NSDate dateFromHttpDate:response.allHeaderFields[@"Date"]];
        if ([initialRiver populateRiverFromData:cachedResponse.data error:&error] == NO) {
            ALog(@"Error occurred when populating initial River [%@]", [error localizedDescription]);
            return [[TSRiver alloc] initWithURL:riverURL];
        }
    }
    
    return initialRiver;
}

- (BOOL)shouldRiverBeUpdated;
{
    SOAssert(self.river != nil, @"River is unexpectedly nil.");
    NSURLRequest *request = [NSURLRequest requestWithURL:self.river.url];
    
    NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    
    if (cachedResponse == nil) {
        return YES;
    }
    
    NSDate *updatedDate = cachedResponse.userInfo[@"updatedDate"];
    
    if (updatedDate != nil) {
        NSDate *anticipatedRiverUpdateDate = [updatedDate dateByAddingTimeInterval:TSRiverUpdateInterval];
        
        if ([anticipatedRiverUpdateDate timeIntervalSinceNow] <= 0) {
            return YES;
        }
        
        return NO;
    }
    
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)cachedResponse.response;
    NSDate *expirationDate = [NSDate expirationDateFromHTTPURLResponse:response];
    
    if (expirationDate == nil || [expirationDate timeIntervalSinceNow] <= 0) {
        return YES;
    }
    
    return NO;
}

- (void)updateRiverFromRequest:(NSURLRequest *)request response:(NSURLResponse *)response data:(NSData *)data;
{
    DLog(@"");
    // ASSUME: We have successfully downloaded the River.  Let's deserialize the data, update our River, call the completion handler, and notify our consumers.
    
    if (response == nil) {
        DLog(@"Response is empty, no update will be performed.");
        return;
    }
    
    if (data == nil) {
        DLog(@"Data is empty, no update will be performed.");
        return;
    }
    
    if (request == nil) {
        DLog(@"Request is empty, no update will be performed.");
        return;
    }
    
    TSRiver *updatedRiver = [[TSRiver alloc] initWithURL:response.URL];
    
    if (updatedRiver == nil) {
        ALog(@"Unable to allocate a new River instance.  No update will be performed");
        return;
    }
    
    if ([updatedRiver.url isEqual:request.URL] == NO) {
        updatedRiver.originalURL = request.URL;
    }
    
    updatedRiver.fetchedDate = [NSDate date];
    
    NSError *deserializationError;
    
    if ([updatedRiver populateRiverFromData:data error:&deserializationError] == NO) {
        self.lastError = deserializationError;
    }
    
    if (self.lastError == nil) {
        NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data userInfo:@{ @"updatedDate": updatedRiver.whenRiverUpdatedDate == nil ? [NSDate distantPast] : updatedRiver.whenRiverUpdatedDate } storagePolicy:NSURLCacheStorageAllowed];
        [[NSURLCache sharedURLCache] storeCachedResponse:cachedResponse forRequest:request];
        
        TSRiver *previousRiver = self.river;
        [[NSNotificationCenter defaultCenter] postNotificationName:TSRiverManagerWillRefreshRiverNotification object:nil userInfo:@{ @"river": self.river }];
        self.river = updatedRiver;
        [[NSNotificationCenter defaultCenter] postNotificationName:TSRiverManagerDidRefreshRiverNotification object:nil userInfo:@{ @"river" : self.river, @"previousRiver" : previousRiver}];
    }
}

- (void)userDefaultsDidChange:(NSNotification *)notification;
{
    NSString *riverURLString = [[NSUserDefaults standardUserDefaults] stringForKey:TSRiverManagerRiverURLKey];
    
    if (IsEmpty(riverURLString)) {
        return;
    }
    
    NSURL *changedRiverURL = [NSURL URLWithString:riverURLString];
    
    if (changedRiverURL == nil) {
        ALog(@"Invalid River URL was specified [%@].", riverURLString);
        return;
    }

    if ([self.river.url isEqual:changedRiverURL] || [self.river.originalURL isEqual:changedRiverURL]) {
        return;
    }

    DLog(@"River URL has changed to [%@] from [%@].  Refreshing River.", changedRiverURL, self.river.url);
    self.river = [[TSRiver alloc] initWithURL:changedRiverURL];
    [self refreshRiverIgnoringCache:YES];
}


#pragma mark -
#pragma mark API

+ (TSRiverManager *)sharedManager;
{
    static TSRiverManager *_riverManager;
    static dispatch_once_t sharedManagerToken;
    dispatch_once(&sharedManagerToken, ^{
        _riverManager = [TSRiverManager new];
    });
    
    return _riverManager;
}

- (BOOL)refreshRiverIgnoringCache:(BOOL)ignoringCache;
{
    if (self.isLoading) {
        DLog(@"Superfluous call to refresh river [%@].", self.river);
        return NO;
    }
    
    if (self.currentTask != nil) {
        switch (self.currentTask.state) {
            case NSURLSessionTaskStateSuspended:
                DLog(@"Canceling suspended data task [%@].", self.currentTask.taskDescription);
                [self.currentTask cancel];
                return NO;
            case NSURLSessionTaskStateRunning:
                DLog(@"A task is already running, but we have requested a superfluous one through a race.");
                return NO;
            case NSURLSessionTaskStateCanceling:
            case NSURLSessionTaskStateCompleted:
                DLog(@"A task in a terminal state was encountered.  Enqueuing a new data task.");
                break;
            default:
                ALog(@"Unexpected task state encountered.  Enqueuing new data task.");
                break;
        }
    }
    
    if (ignoringCache == NO && [self shouldRiverBeUpdated] == NO) {
        DLog(@"River is still current and the cached copy is being used.");
        return NO;
    }

    DLog(@"Performing refresh of River [%@]", self.river);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:self.river.url cachePolicy:(ignoringCache ? NSURLRequestReloadIgnoringLocalCacheData : NSURLRequestUseProtocolCachePolicy) timeoutInterval:60];
    self.currentTask = [self.session downloadTaskWithRequest:request];
    self.lastError = nil;
    self.isLoading = YES;
    [self.currentTask resume];
    [[NSNotificationCenter defaultCenter] postNotificationName:TSRiverManagerBeganRefreshRiverNotification object:nil userInfo:@{ @"river": self.river }];
    return YES;
}

#pragma mark -
#pragma mark NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error;
{
    DLog(@"");
    [self URLSession:session task:self.currentTask didCompleteWithError:error];
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session;
{
    DLog(@"");
    SOAssert(self.session == session, @"Unknown session was supplied.");
    
    TSRiverManagerBackgroundSessionCompletionHandler sessionCompletionHandler = self.sessionCompletionHandler;
    self.sessionCompletionHandler = nil;
    
    if (sessionCompletionHandler != nil) {
        sessionCompletionHandler();
    }
    
    DLog(@"Background session complete.");
}

#pragma mark -
#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error;
{
    SOAssert(self.session == session, @"Unknown session was supplied.");

    if (self.currentTask != task) {
        DLog(@"Reestablishing backgrounded, completed download task.");
        
        if (self.currentTask != nil) {
            DLog(@"A download task was present when the session presented a different, completed one.  Undefined behavior will result.");
        }
        
        self.currentTask = (NSURLSessionDownloadTask *)task;
    }

    SOAssert(self.currentTask.state != NSURLSessionTaskStateRunning, @"Current task was running at the time of completion notification.");
    
    self.lastError = error != nil ? error : self.currentTask.error;
    self.currentTask = nil;
    self.isLoading = NO;
    
    NSMutableDictionary *userInfo = self.river == nil ? [NSMutableDictionary dictionary] : [NSMutableDictionary dictionaryWithDictionary:@{ @"river" : self.river }];
    
    if (error != nil) {
        userInfo[@"error"] = error;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TSRiverManagerCompletedRefreshRiverNotification object:nil userInfo:userInfo];
}

#pragma mark -
#pragma mark NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location;
{
    DLog(@"");
    SOAssert(self.session == session, @"Unknown session was supplied.");
    
    if (downloadTask.error != nil) {
        DLog(@"Error occurred during download [%@].", [downloadTask.error localizedDescription]);
        return;
    }
    
    [self updateRiverFromRequest:downloadTask.originalRequest response:downloadTask.response data:[NSData dataWithContentsOfURL:location]];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes;
{
    DLog(@"");
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;
{
    DLog(@"");
}

#pragma mark -
#pragma mark NSObject

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.sessionQueue = [NSOperationQueue new];
        self.sessionQueue.name = @"TSRiverManager";
        self.sessionQueue.maxConcurrentOperationCount = 1;
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration backgroundSessionConfiguration:TSRiverManagerURLSessionConfigurationIdentifier] delegate:self delegateQueue:self.sessionQueue];
        self.river = [self initialRiver];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:NSUserDefaultsDidChangeNotification];
}

@end
