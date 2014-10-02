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

@interface TSMasterViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *lastUpdatedButton;
@property (nonatomic) NSString *highWatermarkIdentifier;
@property (nonatomic) TSRiver *river;
@property (nonatomic) id riverBeganRefreshObserver;
@property (nonatomic) id riverCompletedRefreshObserver;
@property (nonatomic) NSIndexPath *watermarkIndexPath;
@property (nonatomic) BOOL showingLastUpdated;

- (NSIndexPath *)recalculateWatermark;
- (void)deselectTwainRow;
- (void)updateDateDisplay;
- (IBAction)showTwain:(id)sender;
- (IBAction)toggleUpdatedDate:(id)sender;
- (void)showDetail:(UIStoryboardSegue *)segue sender:(id)sender;
- (IBAction)pulledToRefresh:(id)sender;
- (void)prepareDisplayForRiverUpdate;
- (void)updateLatestRiverAndDisplay;
- (void)riverRefreshTimeout:(NSTimer *)timer;
- (void)scheduleRiverRefreshWatchdog;
- (void)cancelRiverRefreshWatchdog;

- (TSRiverFeed *)feedForIndexPath:(NSIndexPath *)indexPath;
- (TSRiverFeed *)feedForSection:(NSInteger)section;
- (TSRiverItem *)itemForIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForItem:(TSRiverItem *)item;

@end

NSTimeInterval const TSRiverRefreshUITimeout = 60 * 1;

@implementation TSMasterViewController

#pragma mark -
#pragma mark Class extension

NSString * const kHighWatermarkIdentifierKey = @"highWatermarkIdentifier";

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
    
    watermarkIndexPath = [self indexPathForItem:watermarkItem];
    [self setWatermarkIndexPath:watermarkIndexPath];
    return watermarkIndexPath;
}

- (IBAction)pulledToRefresh:(id)sender;
{
    NSString *highWatermarkIdentifier = [[self itemForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] identifier];
    
    if (IsEmpty(highWatermarkIdentifier) == NO) {
        self.highWatermarkIdentifier = highWatermarkIdentifier;
    }

    [[TSRiverManager sharedManager] refreshRiverIgnoringCache:YES];
}

- (void)prepareDisplayForRiverUpdate;
{
    SOAssert([NSThread mainThread] == [NSThread currentThread], @"UI update is not occurring on main thread!");
    [self.refreshControl beginRefreshing];
    self.lastUpdatedButton.title = NSLocalizedString(@"Refreshing...", nil);
}

- (void)updateDisplayFollowingRiverUpdate;
{
    [self.refreshControl endRefreshing];
    [self updateDateDisplay];
    [self recalculateWatermark];
    [self.tableView reloadData];
}

- (void)updateLatestRiverAndDisplay;
{
    DLog(@"");
    SOAssert([NSThread mainThread] == [NSThread currentThread], @"UI update is not occurring on main thread!");
    
    self.river = [[TSRiverManager sharedManager] river];
    [self updateDisplayFollowingRiverUpdate];

    if ([TSRiverManager sharedManager].lastError != nil) {
        ALog(@"Error fetching River: %@", [[TSRiverManager sharedManager].lastError description]);
    }
}

- (IBAction)showTwain:(id)sender
{
    if (self.isEditing) {
        [self setEditing:NO animated:YES];
        return;
    }
    
    NSIndexPath *watermarkIndexPath = [self recalculateWatermark];
    
    if (watermarkIndexPath == nil || [[self tableView] numberOfSections] == 0)
        return;
    
    [[self tableView] selectRowAtIndexPath:self.watermarkIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    [self performSelector:@selector(deselectTwainRow) withObject:nil afterDelay:1.0];
}

- (void)deselectTwainRow;
{
    [self.tableView deselectRowAtIndexPath:self.watermarkIndexPath animated:YES];
}

- (IBAction)toggleUpdatedDate:(id)sender;
{
    if ([self.refreshControl isRefreshing]) {
        return;
    }
    
    self.showingLastUpdated = !self.showingLastUpdated;
    [self updateDateDisplay];
}

- (void)updateDateDisplay;
{
    if ([self.refreshControl isRefreshing]) {
        return;
    }
    
    NSString *dateTitleForDisplay;
    
    if (self.showingLastUpdated) {
        NSString *localizedDateString = [NSDateFormatter localizedStringFromDate:[[self river] fetchedDate] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
        dateTitleForDisplay = [NSString stringWithFormat:NSLocalizedString(@"Last updated at %@", nil), localizedDateString];
    } else {
        NSString *localizedDateString = [NSDateFormatter localizedStringFromDate:[[self river] whenRiverUpdatedDate] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
        dateTitleForDisplay = [NSString stringWithFormat:NSLocalizedString(@"Feed updated at %@", nil), localizedDateString];
    }
    
    self.lastUpdatedButton.title = dateTitleForDisplay;
        
}

- (void)showDetail:(UIStoryboardSegue *)segue sender:(id)sender;
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    [(TSDetailViewController *)segue.destinationViewController setDetailItem:[self itemForIndexPath:indexPath] feed:[self feedForIndexPath:indexPath]];
}

- (TSRiverFeed *)feedForIndexPath:(NSIndexPath *)indexPath;
{
    if (self.river.feeds.count <= indexPath.section)
        return nil;
    
    return self.river.feeds[indexPath.section];
}

- (TSRiverFeed *)feedForSection:(NSInteger)section;
{
    return self.river.feeds[section];
}

- (TSRiverItem *)itemForIndexPath:(NSIndexPath *)indexPath;
{
    NSArray *riverItems = [self feedForIndexPath:indexPath].items;
    
    if (riverItems.count <= indexPath.row) {
        return nil;
    }
    
    return riverItems[indexPath.row];
}

- (NSIndexPath *)indexPathForItem:(TSRiverItem *)item;
{
    if (item == nil) {
        return nil;
    }
    
    for (int feedIndex = 0; feedIndex < self.river.feeds.count; feedIndex++) {
        NSInteger itemIndex = [[[self.river feeds][feedIndex] items] indexOfObject:item];
        
        if (itemIndex == NSNotFound) {
            continue;
        }
        
        return [NSIndexPath indexPathForRow:itemIndex inSection:feedIndex];
    }
    
    return nil;
}

- (void)riverRefreshTimeout:(NSTimer *)timer;
{
    DLog(@"River refresh timed out.");
    [self updateLatestRiverAndDisplay];
}

- (void)scheduleRiverRefreshWatchdog;
{
    [self performSelector:@selector(riverRefreshTimeout:) withObject:nil afterDelay:TSRiverRefreshUITimeout];
}

- (void)cancelRiverRefreshWatchdog;
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(riverRefreshTimeout:) object:nil];
}

#pragma mark -
#pragma mark NSObject

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    
    [super awakeFromNib];
    [self addObserver:self forKeyPath:@"highWatermarkIdentifier" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"highWatermarkIdentifier"]) {
        [[NSUserDefaults standardUserDefaults] setValue:[self highWatermarkIdentifier] forKey:kHighWatermarkIdentifierKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self recalculateWatermark];
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"highWatermarkIdentifier"];
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setDetailViewController:(TSDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController]];
    self.showingLastUpdated = YES;
    [self setHighWatermarkIdentifier:[[NSUserDefaults standardUserDefaults] stringForKey:kHighWatermarkIdentifierKey]];
    [[self lastUpdatedButton] setTitleTextAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:12.0], NSForegroundColorAttributeName : [UIColor blackColor]} forState:UIControlStateNormal];
    [self.tableView setSectionIndexMinimumDisplayRowCount:1];
    
    self.riverBeganRefreshObserver = [[NSNotificationCenter defaultCenter] addObserverForName:TSRiverManagerBeganRefreshRiverNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self prepareDisplayForRiverUpdate];
        [self scheduleRiverRefreshWatchdog];
    }];
    
    self.riverCompletedRefreshObserver = [[NSNotificationCenter defaultCenter] addObserverForName:TSRiverManagerCompletedRefreshRiverNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        TSRiver *refreshedRiver = note.userInfo[@"river"];
        [self cancelRiverRefreshWatchdog];
        
        if (refreshedRiver == nil) {
            DLog(@"River refresh notification received without a new River.  Updating UI with current River.");
            
            if (self.river == nil) {
                ALog(@"We do not have a current River.  Creating a mock, empty River.");
                self.river = [TSRiver new];
            }
            
            [self updateDisplayFollowingRiverUpdate];
            return;
        }
        
        if (self.river == refreshedRiver || [self.river.fetchedDate isEqualToDate:refreshedRiver.fetchedDate]) {
            DLog(@"River refresh notification received.  Display is already up-to-date.");
            [self updateDisplayFollowingRiverUpdate];
            return;
        }
        
        DLog(@"River refresh notification received.  Updating display.");
        [self updateLatestRiverAndDisplay];
    }];
    
    if ([[TSRiverManager sharedManager] refreshRiverIgnoringCache:NO] == YES) {
        return;
    }
    
    [self updateLatestRiverAndDisplay];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[NSNotificationCenter defaultCenter] removeObserver:self.riverBeganRefreshObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.riverCompletedRefreshObserver];
    [self setRiver:nil];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
{
    [super setEditing:editing animated:animated];
    
    if (editing) {
        [[[self navigationItem] rightBarButtonItem] setTitle:NSLocalizedString(@"Cancel", nil)];
    } else {
        [[[self navigationItem] rightBarButtonItem] setTitle:NSLocalizedString(@"Twain", nil)];
    }
    
    [self.tableView setEditing:editing animated:animated];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.river.feeds.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[self feedForSection:section] items] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TSFeedItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    TSRiverItem *item = [self itemForIndexPath:indexPath];
    
    SOAssert(item != nil, @"Nil item was returned when populating a cell!");
    
#ifndef DEBUG
    if (item == nil) {
        DLog("Forcing crash.");
        [[Crashlytics sharedInstance] crash];
    }
#endif
    
    cell.riverItem = item;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
{
    return [[self feedForSection:section] title];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    [self setHighWatermarkIdentifier:[self itemForIndexPath:indexPath].identifier];
    [self recalculateWatermark];
    [self performSelector:@selector(setEditing:) withObject:NO afterDelay:0.0];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return NSLocalizedString(@"Mark Twain", nil);
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [[self detailViewController] setDetailItem:[self itemForIndexPath:indexPath] feed:[self feedForIndexPath:indexPath]];
        return;
    }
}

@end
