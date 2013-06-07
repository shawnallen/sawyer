//
//  TSMasterViewController.m
//  Sawyer
//
//  Created by Shawn on 6/5/13.
//  Copyright (c) 2013 Sotto, LLC. All rights reserved.
//

#import "TSMasterViewController.h"
#import "TSDetailViewController.h"
#import "TSRiver.h"
#import "TSFeedItemTableViewCell.h"

@interface TSMasterViewController () {
    NSString *_highWatermarkIdentifier;
}

@property (nonatomic) NSString *highWatermarkIdentifier;
@property (nonatomic) TSRiver *river;
@property (nonatomic) id settingsObserver;
@property (nonatomic) UITableViewHeaderFooterView *watermarkView;
@property (nonatomic) NSIndexPath *watermarkIndexPath;

- (BOOL)isWatermarkAtSection:(NSInteger)section;
- (NSIndexPath *)recalculateWatermark;
- (void)invalidateWatermark;
- (BOOL)prepareRiver;  // Returns YES if the URL of the River has changed
- (void)prepareWatermarkView;
- (IBAction)refreshRiver;
- (IBAction)showTwain:(id)sender;

@end

@implementation TSMasterViewController

#pragma mark -
#pragma mark Class extension

@dynamic highWatermarkIdentifier;

NSString * const kHighWatermarkIdentifierKey = @"highWatermarkIdentifier";
NSString * const kWatermarkReuseIdentifier = @"Watermark";

- (NSString *)highWatermarkIdentifier
{
    if (_highWatermarkIdentifier == nil)
        _highWatermarkIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:kHighWatermarkIdentifierKey];

    return _highWatermarkIdentifier;
}

- (void)setHighWatermarkIdentifier:(NSString *)highWatermarkIdentifier;
{
    [[NSUserDefaults standardUserDefaults] setValue:highWatermarkIdentifier forKey:kHighWatermarkIdentifierKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self invalidateWatermark];
    _highWatermarkIdentifier = highWatermarkIdentifier;
}

- (BOOL)isWatermarkAtSection:(NSInteger)section;
{
    if (section <= 0)
        return NO;
    
    if ([self watermarkIndexPath] != nil)
        return [[self watermarkIndexPath] section] == section;
    
    return [[self recalculateWatermark] section] == section;
}

- (NSIndexPath *)recalculateWatermark;
{
    NSIndexPath *watermarkIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];  // we do not have a watermark, but we need to not recalculate until that is invalidated
    
    if (IsEmpty([self highWatermarkIdentifier])) {
        [self setWatermarkIndexPath:watermarkIndexPath];
        return watermarkIndexPath;
    }
        
    TSRiverItem *watermarkItem = [[self river] itemForIdentifier:[self highWatermarkIdentifier]];
    
    if (watermarkItem == nil) {
        [self setWatermarkIndexPath:watermarkIndexPath];
        return watermarkIndexPath;
    }
    
    watermarkIndexPath = [[self river] indexPathForItem:watermarkItem];
    [self setWatermarkIndexPath:watermarkIndexPath];  // permuted again only in invalidateWatermark
    return watermarkIndexPath;
}

- (void)invalidateWatermark;
{
    [self setWatermarkIndexPath:nil];
}

- (BOOL)prepareRiver;
{
    NSString *riverURLString = [[NSUserDefaults standardUserDefaults] valueForKey:@"river_url"];
    
    if (IsEmpty(riverURLString)) {
        [[NSUserDefaults standardUserDefaults] setValue:TSRiverDefaultURLString forKey:@"river_url"];
        riverURLString = TSRiverDefaultURLString;
    }
    
    NSURL *riverURL = [NSURL URLWithString:riverURLString];
    
    if (riverURL == nil) {
        ALog(@"User-specified river is an invalid URL");
        riverURL = [NSURL URLWithString:TSRiverDefaultURLString];
    }
    
    if ([self river] != nil && [[[self river] url] isEqual:riverURL])
        return NO;
    
    [self setRiver:[[TSRiver alloc] initWithURL:riverURL]];
    return YES;
}

- (void)prepareWatermarkView;
{
    [self setWatermarkView:[[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:kWatermarkReuseIdentifier]];
    [[self watermarkView] setBounds:CGRectMake(0, 0, 0, 10)];
    [[self watermarkView] setTintColor:[UIColor colorWithRed:54.0/255.0 green:67.0/255.0 blue:149.0/255.0 alpha:1]];
}

- (void)refreshRiver;
{
    if ([self river] == nil || [[self river] isRefreshing])
        return;
    
    [[self refreshControl] beginRefreshing];
    [[self refreshControl] setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Refreshing...", nil)]];
    
    NSString *highWatermarkIdentifier = [[[self river] itemForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] identifier];
    
    if (IsEmpty(highWatermarkIdentifier) == NO)
        [self setHighWatermarkIdentifier:highWatermarkIdentifier];
    
    [[self river] refreshWithCompletionHandler:^(NSError *error) {
        [[self refreshControl] endRefreshing];
        NSString *localizedDateString = [NSDateFormatter localizedStringFromDate:[[self river] updatedDate] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
        [[self refreshControl] setAttributedTitle:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Last updated at %@", nil), localizedDateString]]];
        
        if (error != nil) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Fetching River", nil) message:[error description] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            DLog(@"%@", error);
        };
        
        [[self tableView] reloadData];
    }];
}

- (IBAction)showTwain:(id)sender
{
    NSIndexPath *watermarkIndexPath = [self recalculateWatermark];
    
    if (watermarkIndexPath == nil || [[self tableView] numberOfSections] == 0)
        return;
    
    [[self tableView] scrollToRowAtIndexPath:[self watermarkIndexPath] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

#pragma mark -
#pragma mark NSObject

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self prepareWatermarkView];
    [self setRefreshControl:[[UIRefreshControl alloc] init]];
    [[self refreshControl] addTarget:self action:@selector(refreshRiver) forControlEvents:UIControlEventValueChanged];
    [self setDetailViewController:(TSDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController]];

    if ([self prepareRiver] == YES)
        [self refreshRiver];

    [self setSettingsObserver:[[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        if ([self prepareRiver] == YES)
            [self refreshRiver];
    }]];
    
    [[self tableView] setSectionIndexMinimumDisplayRowCount:1];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[NSNotificationCenter defaultCenter] removeObserver:[self settingsObserver]];
    [self setRiver:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        [(TSDetailViewController *)[segue destinationViewController] setDetailItem:[[self river] itemForIndexPath:indexPath] feed:[[self river] feedForIndexPath:indexPath]];
    }
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[[self river] feeds] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[[self river] feedForSection:section] items] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TSFeedItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    TSRiverItem *item = [[self river] itemForIndexPath:indexPath];
    cell.title.text = [item title];
    cell.body.text = [item body];
    cell.date.text = [NSDateFormatter localizedStringFromDate:[item publicationDate] dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
{
    return [[[self river] feedForSection:section] title];
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        [[self detailViewController] setDetailItem:[[self river] itemForIndexPath:indexPath] feed:[[self river] feedForIndexPath:indexPath]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section;
{
    if ([self isWatermarkAtSection:section])
        return CGRectGetHeight([[self watermarkView] bounds]);
    
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section;
{
    if ([self isWatermarkAtSection:section] == NO)
        return nil;
    
    UITableViewHeaderFooterView *watermarkView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kWatermarkReuseIdentifier];
    
    if (watermarkView == nil)
        watermarkView = [self watermarkView];
    
    [self invalidateWatermark];
    return watermarkView;
}

@end
