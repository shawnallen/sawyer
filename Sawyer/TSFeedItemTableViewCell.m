//
//  TSFeedItemTableViewCell.m
//  Sawyer
//
//  Created by Shawn on 6/5/13.
//  Copyright (c) 2013 Sotto, LLC. All rights reserved.
//

#import "TSFeedItemTableViewCell.h"
#import "TSRiver.h"

@interface TSFeedItemTableViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *body;
@property (weak, nonatomic) IBOutlet UILabel *date;
- (void)designatedInit;
@end

@implementation TSFeedItemTableViewCell

#pragma mark -
#pragma mark Class extension

- (void)designatedInit;
{
    [self addObserver:self forKeyPath:@"riverItem" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark -
#pragma mark UITableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        [self designatedInit];
    }
    
    return self;
}

#pragma mark -
#pragma mark NSObject

- (void)awakeFromNib;
{
    [super awakeFromNib];
    [self designatedInit];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"riverItem"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
    if ([keyPath isEqualToString:@"riverItem"]) {
        self.title.text = self.riverItem.title;
        self.body.text = self.riverItem.body;
        self.date.text = [NSDateFormatter localizedStringFromDate:self.riverItem.publicationDate dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
