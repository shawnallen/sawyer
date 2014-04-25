//
//  UIViewController+SASegueAdditions.m
//
//  Created by Shawn Allen on 4/25/14.
//

#import "UIViewController+SASegueAdditions.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation UIViewController (SASegueAdditions)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender;
{
    [self sa_prepareForSegue:segue sender:sender];
}
#pragma clang diagnostic pop

- (void)sa_prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender;
{
    if ([[segue identifier] length] == 0) {
        return;
    }
    
    if ([[segue identifier] rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
        NSAssert(false, @"Segue identifier is not a valid Objective-C identifier [%@]", [segue identifier]);
        return;
    }

    NSString *selectorString = [NSString stringWithFormat:@"%@:sender:", [segue identifier]];

    SEL identifierSelector = sel_registerName([selectorString UTF8String]);
    
    if ([self respondsToSelector:identifierSelector] == NO) {
        NSLog(@"Unimplemented segue method -[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(identifierSelector));
        return;
    }
    
    ((id (*)(id, SEL, UIStoryboardSegue *, id))objc_msgSend)(self, identifierSelector, segue, sender);
}

@end
