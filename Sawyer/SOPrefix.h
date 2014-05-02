/*
 *  SOPrefix.h
 *
 *  Created by Shawn Allen on 1/24/11.
 */

// IsEmpty from Wil Shipley's DMCommonMacros.h, under public domain.

static inline BOOL IsEmpty(id thing) 
{
    return thing == nil
    || ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
    || ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}

static inline void performOnMainThread(void (^block)())
{
    if ([NSThread isMainThread] == YES)
        block();
    else
        dispatch_sync(dispatch_get_main_queue(), block);
}

// Adapted from Marcus Zarra's prefix header file conventions.

#ifdef DEBUG
	#define DLog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
	#define ALog(...) [[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSUTF8StringEncoding] file:[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lineNumber:__LINE__ description:__VA_ARGS__]
#else
	#define DLog(...) do { } while (0)

	#ifndef NS_BLOCK_ASSERTIONS
		#define NS_BLOCK_ASSERTIONS
	#endif

	#define ALog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#endif

#define SOAssert(condition, ...) do { if (!(condition)) { ALog(__VA_ARGS__); }} while(0)