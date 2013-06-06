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

@property (nonatomic) TSRiver *river;
@property (nonatomic) id settingsObserver;

- (TSRiverFeed *)feedForSection:(NSInteger)section;
- (BOOL)prepareRiver;
- (IBAction)refreshRiver;

@end

@implementation TSMasterViewController

#pragma mark -
#pragma mark Class extension

- (TSRiverFeed *)feedForSection:(NSInteger)section;
{
    return [[self river] feeds][section];
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
    [[self refreshControl] setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Refreshing...", nil)]];
    
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
    [self setRefreshControl:[[UIRefreshControl alloc] init]];
    [[self refreshControl] addTarget:self action:@selector(refreshRiver) forControlEvents:UIControlEventValueChanged];
    [self setDetailViewController:(TSDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController]];

    if ([self prepareRiver] == YES)
        [self refreshRiver];

    [self setSettingsObserver:[[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        if ([self prepareRiver] == YES)
            [self refreshRiver];
    }]];
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
    return [[[self feedForSection:section] items] count];
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

    return [[self feedForSection:section] title];
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        [[self detailViewController] setDetailItem:[[self river] itemForIndexPath:indexPath] feed:[[self river] feedForIndexPath:indexPath]];
}

@end
