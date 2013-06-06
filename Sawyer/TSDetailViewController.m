//
//  TSDetailViewController.m
//  Sawyer
//
//  Created by Shawn on 6/5/13.
//  Copyright (c) 2013 Sotto, LLC. All rights reserved.
//

#import "TSDetailViewController.h"

@interface TSDetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) TSRiverItem *riverItem;
@property (strong, nonatomic) TSRiverFeed *riverFeed;
- (void)configureView;
@end

@implementation TSDetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(TSRiverItem *)detailItem feed:(TSRiverFeed *)feed;
{
    if ([self riverItem] != detailItem || [self riverFeed] != feed) {
        [self setRiverItem:detailItem];
        [self setRiverFeed:feed];
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
        return;
    }
}

- (void)configureView
{
    if (IsEmpty([self riverFeed]))
        [self setTitle:NSLocalizedString(@"Detail", nil)];
    else
        [self setTitle:[[self riverFeed] title]];
    
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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showLink"]) {
        [[segue destinationViewController] setLink:[[self riverItem] link]];
    }
}

#pragma mark - Split view

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
