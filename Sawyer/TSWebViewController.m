//
//  TSWebViewController.m
//  Sawyer
//
//  Created by Shawn on 6/5/13.
//  Copyright (c) 2013 Sotto, LLC. All rights reserved.
//

#import "TSWebViewController.h"
#import "TSActivityUtilities.h"

@interface TSWebViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *forwardButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionButton;

- (IBAction)showActions:(id)sender;
- (void)loadLink;
@end

@implementation TSWebViewController

#pragma mark -
#pragma mark API

- (IBAction)showActions:(id)sender
{
    NSString *sharingURLString = [[self webView] stringByEvaluatingJavaScriptFromString:@"document.location.toString()"];

    if (IsEmpty(sharingURLString)) {
        return;
    }

    NSURL *sharingURL = [NSURL URLWithString:sharingURLString];
    
    if (IsEmpty(sharingURL)) {
        return;
    }
    
    UIActivityViewController *activityController = [TSActivityUtilities activityControllerForURL:sharingURL];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:activityController];
        [popoverController presentPopoverFromBarButtonItem:[[self navigationItem] rightBarButtonItem] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
        [activityController setCompletionHandler:^(NSString *activityType, BOOL completed) {
            [popoverController dismissPopoverAnimated:YES];
        }];
    } else {
        [self presentViewController:activityController animated:YES completion:nil];
    }
}

- (void)loadLink;
{
    if ([self isViewLoaded] == NO) {
        return;
    }
    
    [[self webView] loadRequest:[NSURLRequest requestWithURL:[self link]]];
}

#pragma mark -
#pragma mark UIViewController

- (void)awakeFromNib;
{
    [self addObserver:self forKeyPath:@"link" options:NSKeyValueObservingOptionNew context:nil];
    self.navigationItem.leftItemsSupplementBackButton = YES;
}

- (void)viewDidLoad;
{
    [super viewDidLoad];
    [self loadLink];
}

- (void)viewWillDisappear:(BOOL)animated;
{
    if ([[self webView] isLoading]) {
        [[self webView] stopLoading];
    }
    
    [super viewWillDisappear:animated];
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView;
{
    [[self actionButton] setEnabled:YES];
    [self setTitle:[[self webView] stringByEvaluatingJavaScriptFromString:@"document.title"]];
}

- (void)webViewDidStartLoad:(UIWebView *)webView;
{
    [[self actionButton] setEnabled:NO];
    [self setTitle:NSLocalizedString(@"Loading...", nil)];
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"link"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"link"]) {
        [self loadLink];
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:nil];
}

@end
