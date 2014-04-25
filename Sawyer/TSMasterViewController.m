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
@property (nonatomic) id settingsObserver;
@property (nonatomic) NSIndexPath *watermarkIndexPath;
@property (nonatomic) BOOL showingLastUpdated;
@property (nonatomic) BOOL didRiverUpdateSinceLastUse;

- (NSIndexPath *)recalculateWatermark;
- (BOOL)prepareRiver;  // Returns YES if the URL of the River has changed
- (void)deselectTwainRow;
- (void)updateDateDisplay;
- (IBAction)refreshRiver;
- (IBAction)showTwain:(id)sender;
- (IBAction)toggleUpdatedDate:(id)sender;
- (void)showDetail:(UIStoryboardSegue *)segue sender:(id)sender;

@end

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
    
    watermarkIndexPath = [[self river] indexPathForItem:watermarkItem];
    [self setWatermarkIndexPath:watermarkIndexPath];
    return watermarkIndexPath;
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

- (void)refreshRiver;
{
    if ([self river] == nil || [[self river] isRefreshing])
        return;
    
    [[self refreshControl] beginRefreshing];
    self.lastUpdatedButton.title = NSLocalizedString(@"Refreshing...", nil);
    
    NSString *highWatermarkIdentifier = [[[self river] itemForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] identifier];
    
    if (IsEmpty(highWatermarkIdentifier) == NO)
        [self setHighWatermarkIdentifier:highWatermarkIdentifier];
    
    [[self river] refreshWithCompletionHandler:^(NSError *error) {
        [[self refreshControl] endRefreshing];
        [self updateDateDisplay];
        
        if (error != nil) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Fetching River", nil) message:[error description] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            DLog(@"%@", error);
        };
        
        [self recalculateWatermark];
        [[self tableView] reloadData];
    }];
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
    self.showingLastUpdated = !self.showingLastUpdated;
    [self updateDateDisplay];
}

- (void)updateDateDisplay;
{
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
    [(TSDetailViewController *)[segue destinationViewController] setDetailItem:[[self river] itemForIndexPath:indexPath] feed:[[self river] feedForIndexPath:indexPath]];
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
    [[self refreshControl] addTarget:self action:@selector(refreshRiver) forControlEvents:UIControlEventValueChanged];
    [self setDetailViewController:(TSDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController]];
    self.showingLastUpdated = YES;
    [self setHighWatermarkIdentifier:[[NSUserDefaults standardUserDefaults] stringForKey:kHighWatermarkIdentifierKey]];

    [[self lastUpdatedButton] setTitleTextAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:12.0], NSForegroundColorAttributeName : [UIColor blackColor]} forState:UIControlStateNormal];
    

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
    [[NSNotificationCenter defaultCenter] removeObserver:self.settingsObserver];
    [self setRiver:nil];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
{
    [super setEditing:editing animated:animated];
    
    if (editing)
        [[[self navigationItem] rightBarButtonItem] setTitle:NSLocalizedString(@"Cancel", nil)];
    else
        [[[self navigationItem] rightBarButtonItem] setTitle:NSLocalizedString(@"Twain", nil)];
    
    [[self tableView] setEditing:editing animated:animated];
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
    cell.riverItem = item;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
{
    return [[[self river] feedForSection:section] title];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    [self setHighWatermarkIdentifier:[self.river itemForIndexPath:indexPath].identifier];
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
        [[self detailViewController] setDetailItem:[[self river] itemForIndexPath:indexPath] feed:[[self river] feedForIndexPath:indexPath]];
        return;
    }
}

@end
