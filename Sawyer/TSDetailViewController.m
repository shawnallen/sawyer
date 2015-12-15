//
//  TSDetailViewController.m
//  Sawyer
//
//  Created by Shawn on 6/5/13.
//  Copyright (c) 2013 Sotto, LLC. All rights reserved.
//

#import "TSDetailViewController.h"
#import "TSRiver.h"
#import "TSActivityUtilities.h"
@import SafariServices;

@interface TSDetailViewController () <SFSafariViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *detailEnclosingView;
@property (weak, nonatomic) IBOutlet UIButton *feedTitleButton;
@property (weak, nonatomic) IBOutlet UIButton *linkButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *publishedDate;
@property (weak, nonatomic) IBOutlet UITextView *body;
@property (weak, nonatomic) IBOutlet UILabel *noContentSelectedLabel;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) TSRiverItem *riverItem;
@property (strong, nonatomic) TSRiverFeed *riverFeed;

- (void)configureView;
- (IBAction)showActions:(id)sender;
- (IBAction)showLink:(id)sender;
- (IBAction)showFeedWebsite:(id)sender;
@end

@implementation TSDetailViewController

#pragma mark -
#pragma mark Class extension

- (void)configureView
{
    if (IsEmpty([self riverFeed])) {
        [[self feedTitleButton] setTitle:NSLocalizedString(@"", nil) forState:UIControlStateNormal];
        [self setTitle:NSLocalizedString(@"", nil)];
    } else {
        [[self feedTitleButton] setTitle:[[self riverFeed] title] forState:UIControlStateNormal];
        [self setTitle:NSLocalizedString(@"Item", nil)];
    }
    
    if (IsEmpty([self riverItem])) {
        [[self noContentSelectedLabel] setHidden:NO];
        [[self detailEnclosingView] setHidden:YES];
        return;
    }
    
    [[self noContentSelectedLabel] setHidden:YES];
    [[self detailEnclosingView] setHidden:NO];
    
    [[self titleLabel] setText:[[self riverItem] title]];
    [[self publishedDate] setText:[NSDateFormatter localizedStringFromDate:[[self riverItem] publicationDate] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
    [[self body] setText:[[self riverItem] body]];
}

- (IBAction)showActions:(id)sender
{
    if (IsEmpty([self riverItem])) {
        return;
    }
    
    UIActivityViewController *activityController = [TSActivityUtilities activityControllerForURL:[[self riverItem] link]];

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

- (void)showLink:(UIStoryboardSegue *)segue sender:(id)sender;
{
    [[segue destinationViewController] setLink:[[self riverItem] link]];
}

- (void)showFeedWebsite:(UIStoryboardSegue *)segue sender:(id)sender;
{
    [[segue destinationViewController] setLink:[[self riverFeed] website]];
}

- (IBAction)showLink:(id)sender;
{
    NSURL *targetURL = [[self riverItem] link];
    
    if (IsEmpty(targetURL)) {
        return;
    }
    
    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:targetURL];
    safariViewController.delegate = self;
    [self presentViewController:safariViewController animated:YES completion:nil];
}

- (IBAction)showFeedWebsite:(id)sender;
{
    NSURL *targetURL = [[self riverFeed] website];
    
    if (IsEmpty(targetURL)) {
        return;
    }
    
    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:targetURL];
    safariViewController.delegate = self;
    [self presentViewController:safariViewController animated:YES completion:nil];
}

#pragma mark -
#pragma mark API

- (void)setDetailItem:(TSRiverItem *)detailItem feed:(TSRiverFeed *)feed;
{
    if ([self riverItem] != detailItem || [self riverFeed] != feed) {
        [self setRiverItem:detailItem];
        [self setRiverFeed:feed];
        [self configureView];
    }

    if ([self masterPopoverController] != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }

    if (self.navigationController.visibleViewController != self) {
        [self.navigationController popToViewController:self animated:YES];
    }
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureView];
}

#pragma mark -
#pragma mark UISplitViewControllerDelegate

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Sawyer", nil);
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

@end
