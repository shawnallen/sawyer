//
//  TSDetailViewController.m
//  Sawyer
//
//  Created by Shawn on 6/5/13.
//  Copyright (c) 2013 Sotto, LLC. All rights reserved.
//

#import "TSDetailViewController.h"
#import "ZYInstapaperActivity.h"

@interface TSDetailViewController ()
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
    if (IsEmpty([self riverItem]))
        return;
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[[[self riverItem] link]] applicationActivities:@[[[ZYInstapaperActivity alloc] init]]];
    [activityViewController setExcludedActivityTypes:@[UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypePrint]];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
        [popoverController presentPopoverFromBarButtonItem:[[self navigationItem] rightBarButtonItem] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
        [activityViewController setCompletionHandler:^(NSString *activityType, BOOL completed) {
            [popoverController dismissPopoverAnimated:YES];
        }];

    } else
        [self presentViewController:activityViewController animated:YES completion:nil];
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

    if (IsEmpty([self masterPopoverController])) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
        return;
    }
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureView];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showLink"]) {
        [[segue destinationViewController] setLink:[[self riverItem] link]];
    }
    
    if ([[segue identifier] isEqualToString:@"showFeedWebsite"]) {
        [[segue destinationViewController] setLink:[[self riverFeed] website]];
    }
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
