//
//  TSWebViewController.m
//  Sawyer
//
//  Created by Shawn on 6/5/13.
//  Copyright (c) 2013 Sotto, LLC. All rights reserved.
//

#import "TSWebViewController.h"

@interface TSWebViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *forwardButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (nonatomic) NSURL *link;

@end

@implementation TSWebViewController

#pragma mark -
#pragma mark API

- (void)setLink:(NSURL *)link;
{
    _link = link;
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[self webView] loadRequest:[NSURLRequest requestWithURL:[self link]]];
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView;
{
    [self setTitle:[[self webView] stringByEvaluatingJavaScriptFromString:@"document.title"]];
}

- (void)webViewDidStartLoad:(UIWebView *)webView;
{
    [self setTitle:NSLocalizedString(@"Loading...", nil)];
}

@end
