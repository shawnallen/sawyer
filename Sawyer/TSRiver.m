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
- (NSString *)stringByUnmanglingAndUnescapingRiverData:(NSData *)riverData;

+ (NSDictionary *)asciiHTMLEscapeMap;

@end

@implementation TSRiver

#pragma mark -
#pragma mark Class extension

+ (NSDictionary *)asciiHTMLEscapeMap;
{
    static dispatch_once_t onceToken;
    static NSDictionary* _asciiHTMLEscapeMap;
    
    dispatch_once(&onceToken, ^{
        // Taken from http://www.w3.org/TR/xhtml1/dtds.html#a_dtd_Special_characters
        // Ordered by uchar lowest to highest for bsearching
        _asciiHTMLEscapeMap = @{
        // A.2.2. Special characters
         @"&quot": @(34),
         @"&amp": @(38),
         @"&apos": @(39),
         @"&lt": @(60),
         @"&gt": @(62),
        
        // A.2.1. Latin-1 characters
         @"&nbsp": @(160),
         @"&iexcl": @(161),
         @"&cent": @(162),
         @"&pound": @(163),
         @"&curren": @(164),
         @"&yen": @(165),
         @"&brvbar": @(166),
         @"&sect": @(167),
         @"&uml": @(168),
         @"&copy": @(169),
         @"&ordf": @(170),
         @"&laquo": @(171),
         @"&not": @(172),
         @"&shy": @(173),
         @"&reg": @(174),
         @"&macr": @(175),
         @"&deg": @(176),
         @"&plusmn": @(177),
         @"&sup2": @(178),
         @"&sup3": @(179),
         @"&acute": @(180),
         @"&micro": @(181),
         @"&para": @(182),
         @"&middot": @(183),
         @"&cedil": @(184),
         @"&sup1": @(185),
         @"&ordm": @(186),
         @"&raquo": @(187),
         @"&frac14": @(188),
         @"&frac12": @(189),
         @"&frac34": @(190),
         @"&iquest": @(191),
         @"&Agrave": @(192),
         @"&Aacute": @(193),
         @"&Acirc": @(194),
         @"&Atilde": @(195),
         @"&Auml": @(196),
         @"&Aring": @(197),
         @"&AElig": @(198),
         @"&Ccedil": @(199),
         @"&Egrave": @(200),
         @"&Eacute": @(201),
         @"&Ecirc": @(202),
         @"&Euml": @(203),
         @"&Igrave": @(204),
         @"&Iacute": @(205),
         @"&Icirc": @(206),
         @"&Iuml": @(207),
         @"&ETH": @(208),
         @"&Ntilde": @(209),
         @"&Ograve": @(210),
         @"&Oacute": @(211),
         @"&Ocirc": @(212),
         @"&Otilde": @(213),
         @"&Ouml": @(214),
         @"&times": @(215),
         @"&Oslash": @(216),
         @"&Ugrave": @(217),
         @"&Uacute": @(218),
         @"&Ucirc": @(219),
         @"&Uuml": @(220),
         @"&Yacute": @(221),
         @"&THORN": @(222),
         @"&szlig": @(223),
         @"&agrave": @(224),
         @"&aacute": @(225),
         @"&acirc": @(226),
         @"&atilde": @(227),
         @"&auml": @(228),
         @"&aring": @(229),
         @"&aelig": @(230),
         @"&ccedil": @(231),
         @"&egrave": @(232),
         @"&eacute": @(233),
         @"&ecirc": @(234),
         @"&euml": @(235),
         @"&igrave": @(236),
         @"&iacute": @(237),
         @"&icirc": @(238),
         @"&iuml": @(239),
         @"&eth": @(240),
         @"&ntilde": @(241),
         @"&ograve": @(242),
         @"&oacute": @(243),
         @"&ocirc": @(244),
         @"&otilde": @(245),
         @"&ouml": @(246),
         @"&divide": @(247),
         @"&oslash": @(248),
         @"&ugrave": @(249),
         @"&uacute": @(250),
         @"&ucirc": @(251),
         @"&uuml": @(252),
         @"&yacute": @(253),
         @"&thorn": @(254),
         @"&yuml": @(255),
        
        // A.2.2. Special characters cont'd
         @"&OElig": @(338),
         @"&oelig": @(339),
         @"&Scaron": @(352),
         @"&scaron": @(353),
         @"&Yuml": @(376),
        
        // A.2.3. Symbols
         @"&fnof": @(402),
        
        // A.2.2. Special characters cont'd
         @"&circ": @(710),
         @"&tilde": @(732),
        
        // A.2.3. Symbols cont'd
         @"&Alpha": @(913),
         @"&Beta": @(914),
         @"&Gamma": @(915),
         @"&Delta": @(916),
         @"&Epsilon": @(917),
         @"&Zeta": @(918),
         @"&Eta": @(919),
         @"&Theta": @(920),
         @"&Iota": @(921),
         @"&Kappa": @(922),
         @"&Lambda": @(923),
         @"&Mu": @(924),
         @"&Nu": @(925),
         @"&Xi": @(926),
         @"&Omicron": @(927),
         @"&Pi": @(928),
         @"&Rho": @(929),
         @"&Sigma": @(931),
         @"&Tau": @(932),
         @"&Upsilon": @(933),
         @"&Phi": @(934),
         @"&Chi": @(935),
         @"&Psi": @(936),
         @"&Omega": @(937),
         @"&alpha": @(945),
         @"&beta": @(946),
         @"&gamma": @(947),
         @"&delta": @(948),
         @"&epsilon": @(949),
         @"&zeta": @(950),
         @"&eta": @(951),
         @"&theta": @(952),
         @"&iota": @(953),
         @"&kappa": @(954),
         @"&lambda": @(955),
         @"&mu": @(956),
         @"&nu": @(957),
         @"&xi": @(958),
         @"&omicron": @(959),
         @"&pi": @(960),
         @"&rho": @(961),
         @"&sigmaf": @(962),
         @"&sigma": @(963),
         @"&tau": @(964),
         @"&upsilon": @(965),
         @"&phi": @(966),
         @"&chi": @(967),
         @"&psi": @(968),
         @"&omega": @(969),
         @"&thetasym": @(977),
         @"&upsih": @(978),
         @"&piv": @(982),
        
        // A.2.2. Special characters cont'd
         @"&ensp": @(8194),
         @"&emsp": @(8195),
         @"&thinsp": @(8201),
         @"&zwnj": @(8204),
         @"&zwj": @(8205),
         @"&lrm": @(8206),
         @"&rlm": @(8207),
         @"&ndash": @(8211),
         @"&mdash": @(8212),
         @"&lsquo": @(8216),
         @"&rsquo": @(8217),
         @"&sbquo": @(8218),
         @"&ldquo": @(8220),
         @"&rdquo": @(8221),
         @"&bdquo": @(8222),
         @"&dagger": @(8224),
         @"&Dagger": @(8225),
        // A.2.3. Symbols cont'd
         @"&bull": @(8226),
         @"&hellip": @(8230),
        
        // A.2.2. Special characters cont'd
         @"&permil": @(8240),
        
        // A.2.3. Symbols cont'd
         @"&prime": @(8242),
         @"&Prime": @(8243),
        
        // A.2.2. Special characters cont'd
         @"&lsaquo": @(8249),
         @"&rsaquo": @(8250),
        
        // A.2.3. Symbols cont'd
         @"&oline": @(8254),
         @"&frasl": @(8260),
        
        // A.2.2. Special characters cont'd
         @"&euro": @(8364),
        
        // A.2.3. Symbols cont'd
         @"&image": @(8465),
         @"&weierp": @(8472),
         @"&real": @(8476),
         @"&trade": @(8482),
         @"&alefsym": @(8501),
         @"&larr": @(8592),
         @"&uarr": @(8593),
         @"&rarr": @(8594),
         @"&darr": @(8595),
         @"&harr": @(8596),
         @"&crarr": @(8629), 
         @"&lArr": @(8656), 
         @"&uArr": @(8657), 
         @"&rArr": @(8658), 
         @"&dArr": @(8659), 
         @"&hArr": @(8660), 
         @"&forall": @(8704), 
         @"&part": @(8706), 
         @"&exist": @(8707), 
         @"&empty": @(8709), 
         @"&nabla": @(8711), 
         @"&isin": @(8712), 
         @"&notin": @(8713), 
         @"&ni": @(8715), 
         @"&prod": @(8719), 
         @"&sum": @(8721), 
         @"&minus": @(8722), 
         @"&lowast": @(8727), 
         @"&radic": @(8730), 
         @"&prop": @(8733), 
         @"&infin": @(8734), 
         @"&ang": @(8736), 
         @"&and": @(8743), 
         @"&or": @(8744), 
         @"&cap": @(8745), 
         @"&cup": @(8746), 
         @"&int": @(8747), 
         @"&there4": @(8756), 
         @"&sim": @(8764), 
         @"&cong": @(8773), 
         @"&asymp": @(8776), 
         @"&ne": @(8800), 
         @"&equiv": @(8801), 
         @"&le": @(8804), 
         @"&ge": @(8805), 
         @"&sub": @(8834), 
         @"&sup": @(8835), 
         @"&nsub": @(8836), 
         @"&sube": @(8838), 
         @"&supe": @(8839), 
         @"&oplus": @(8853), 
         @"&otimes": @(8855), 
         @"&perp": @(8869), 
         @"&sdot": @(8901), 
         @"&lceil": @(8968), 
         @"&rceil": @(8969), 
         @"&lfloor": @(8970), 
         @"&rfloor": @(8971), 
         @"&lang": @(9001), 
         @"&rang": @(9002), 
         @"&loz": @(9674), 
         @"&spades": @(9824), 
         @"&clubs": @(9827), 
         @"&hearts": @(9829), 
         @"&diams": @(9830) };
    });
    
    return _asciiHTMLEscapeMap;
}

- (NSString *)stringByUnmanglingAndUnescapingRiverData:(NSData *)riverData;
{
    NSString *riverString = [[NSString alloc] initWithData:riverData encoding:NSUTF8StringEncoding];
    NSMutableString *unmangledRiverString = [NSMutableString stringWithCapacity:[riverString length]];
    NSScanner *semiColonScanner = [NSScanner scannerWithString:riverString];
    NSString *accumulatedString;
    BOOL isPseudoEscapedCharacter = NO;

    while ([semiColonScanner scanUpToString:@";" intoString:&accumulatedString]) {
        NSRange subrange = [accumulatedString rangeOfString:@"&" options:NSBackwardsSearch];
        
        if (subrange.length == 0) {
            [unmangledRiverString appendString:accumulatedString];
            
            while ([semiColonScanner scanString:@";" intoString:NULL]) {
                ;  // Advance past the semicolon read to, and handle the condition of successive semi-colons in the text.
            }
            
            continue;
        }
        
        NSString *charString;
        NSRange escapeRange = NSMakeRange(subrange.location, [accumulatedString length] - subrange.location);
        NSString *escapeString = [accumulatedString substringWithRange:escapeRange];
        NSUInteger length = [escapeString length];
        
        // NOTE: Portions of this code were adapted from and inspired by from Google Toolbox for Mac's GTMNSString+HTML.m.
        
        // a sequence must be longer than 3 (&lt;) and less than 11 (&thetasym;)
        if (length > 3 && length < 11) {
            if ([escapeString characterAtIndex:1] == '#') {
                unichar char2 = [escapeString characterAtIndex:2];
                if (char2 == 'x' || char2 == 'X') {
                    // Hex escape squences &#xa3;
                    NSString *hexSequence = [escapeString substringWithRange:NSMakeRange(3, length - 4)];
                    NSScanner *scanner = [NSScanner scannerWithString:hexSequence];
                    unsigned value;
                    if ([scanner scanHexInt:&value] &&
                        value < USHRT_MAX &&
                        value > 0
                        && [scanner scanLocation] == length - 4) {
                        unichar uchar = (unichar)value;
                        charString = [NSString stringWithCharacters:&uchar length:1];
                    }
                } else {
                    // Decimal Sequences &#123;  The River publisher produces odd sequences in what appears to be a bug within their XSLT-like behavior.  All sequences need to be adjusted, with many being skipped.
                    NSString *numberSequence = [escapeString substringWithRange:NSMakeRange(2, length - 2)];
                    NSScanner *scanner = [NSScanner scannerWithString:numberSequence];
                    int value;
                    if ([scanner scanInt:&value] &&
                        value < USHRT_MAX &&
                        value > 0
                        && [scanner scanLocation] == length - 2) {
                        unichar uchar = (unichar)value;
                        
                        if (value > 160) {
                            charString = @"";

                            if (value == 195) {
                                isPseudoEscapedCharacter = YES;
                                goto continueProcessing;
                            }
                            
                            if (isPseudoEscapedCharacter == NO) {
                                goto continueProcessing;  // We skip all characters not pseudo-escaped
                            }
                        }

                        if (isPseudoEscapedCharacter) {
                            uchar = (unichar)(value + 64);
                            isPseudoEscapedCharacter = NO;
                        }
                        
                        charString = [NSString stringWithCharacters:&uchar length:1];
                    }
                }
            } else {
                // "standard" sequences
                NSNumber *escapeSequenceNumber = [TSRiver asciiHTMLEscapeMap][escapeString];
                
                if (escapeSequenceNumber != nil) {
                    unichar uchar = [escapeSequenceNumber unsignedShortValue];
                    charString = [NSString stringWithCharacters:&uchar length:1];
                } else {
                    charString = @"";
                }
            }
        }
        
    continueProcessing:
        if (charString != nil) {
            [unmangledRiverString appendString:[accumulatedString substringToIndex:escapeRange.location]];
            [unmangledRiverString appendString:charString];
        } else {
            [unmangledRiverString appendString:accumulatedString];
        }
        
        
        while ([semiColonScanner scanString:@";" intoString:NULL]) {
            ;  // Advance past the semicolon read to, and handle the condition of successive semi-colons in the text.
        }
        
        accumulatedString = nil;
    }
    
    return unmangledRiverString;
}

- (BOOL)populateRiverFromData:(NSData *)data error:(NSError **)error;
{
    __block NSDictionary *newRiver;
    
    performOnMainThread(^{
        UIWebView *deserializationWebView = [[UIWebView alloc] init];
        NSString *riverJavaScript = [NSString stringWithFormat:@"function %@(river){return JSON.stringify(river);};%@;", self.paddingFunctionName, [self stringByUnmanglingAndUnescapingRiverData:data]];
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
        else if (IsEmpty(newFeed.url) == NO) {
            [newFeed setWebsite:[[NSURL alloc] initWithScheme:newFeed.url.scheme host:newFeed.url.host path:@"/"]];
        }
        
        [newFeed setTitle:feed[@"feedTitle"]];
        [newFeed setFeedDescription:feed[@"feedDescription"]];

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
NSString * const TSRiverManagerCompletedRefreshRiverNotification = @"TSRiverManagerCompletedRefreshRiverNotification";
NSString * const TSRiverManagerRiverURLKey = @"river_url";
NSTimeInterval const TSRiverUpdateInterval = 60 * 20;  // 20 minute time interval

@interface TSRiverManager () <NSURLSessionDelegate, NSURLSessionDataDelegate>
@property (nonatomic, readwrite) TSRiver *river;
@property (nonatomic, readwrite) BOOL isLoading;
@property (nonatomic, readwrite) NSError *lastError;
@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSOperationQueue *sessionQueue;
@property (nonatomic) NSURLSessionDataTask *currentTask;
@property (nonatomic) NSMutableData *accumulatedData;

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

        if (updatedRiver.originalURL != nil) {
            [[NSURLCache sharedURLCache] storeCachedResponse:cachedResponse forRequest:[NSURLRequest requestWithURL:cachedResponse.response.URL]];
        }
        
        TSRiver *previousRiver = self.river;
        self.river = updatedRiver;
        
        if (previousRiver == nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName:TSRiverManagerDidRefreshRiverNotification object:nil userInfo:@{ @"river" : self.river }];
            return;
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:TSRiverManagerWillRefreshRiverNotification object:nil userInfo:@{ @"river": previousRiver }];
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
                break;
            case NSURLSessionTaskStateRunning:
                DLog(@"A task is already running, but we have requested a superfluous one through a race.");
                [self.currentTask cancel];
                break;
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
        [[NSNotificationCenter defaultCenter] postNotificationName:TSRiverManagerCompletedRefreshRiverNotification object:nil userInfo:@{ @"river": self.river }];
        return NO;
    }

    DLog(@"Performing refresh of River [%@]", self.river);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:self.river.url cachePolicy:(ignoringCache ? NSURLRequestReloadIgnoringLocalCacheData : NSURLRequestUseProtocolCachePolicy) timeoutInterval:60];
    self.currentTask = [self.session dataTaskWithRequest:request];
    self.lastError = nil;
    self.isLoading = YES;
    self.accumulatedData = [NSMutableData new];
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

#pragma mark -
#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error;
{
    SOAssert(self.session == session, @"Unknown session was supplied.");

    if (self.currentTask != task) {
        DLog(@"Reestablishing prior data task.");
        
        if (self.currentTask != nil) {
            DLog(@"A data task was present when the session presented a different one.  Undefined behavior will result.");
        }
        
        self.currentTask = (NSURLSessionDataTask *)task;
    }

    SOAssert(self.currentTask.state != NSURLSessionTaskStateRunning, @"Current task was running at the time of completion notification.");
    [self updateRiverFromRequest:self.currentTask.originalRequest response:self.currentTask.response data:self.accumulatedData];
    self.lastError = error != nil ? error : self.currentTask.error;
    self.currentTask = nil;
    self.accumulatedData = nil;
    self.isLoading = NO;
    
    NSMutableDictionary *userInfo = self.river == nil ? [NSMutableDictionary dictionary] : [NSMutableDictionary dictionaryWithDictionary:@{ @"river" : self.river }];
    
    if (error != nil) {
        userInfo[@"error"] = error;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TSRiverManagerCompletedRefreshRiverNotification object:nil userInfo:userInfo];
}

#pragma mark -
#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data;
{
    SOAssert(self.session == session, @"Unknown session was supplied.");

    if (dataTask.error != nil) {
        DLog(@"Error occurred during retrieval [%@].", [dataTask.error localizedDescription]);
        return;
    }
    
    [self.accumulatedData appendData:data];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler;
{
    completionHandler(proposedResponse);
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
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.sessionQueue];
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
