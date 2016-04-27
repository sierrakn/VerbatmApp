//
//  FeaturedContentVC.m
//  Verbatm
//
//  Created by Sierra Kaplan-Nelson on 4/15/16.
//  Copyright © 2016 Verbatm. All rights reserved.
//

#import "Channel_BackendObject.h"
#import "ExploreChannelCellView.h"
#import "FeedQueryManager.h"
#import "FeaturedContentVC.h"
#import "FeaturedContentCellView.h"
#import "Follow_BackendManager.h"
#import "ProfileVC.h"
#import "SizesAndPositions.h"
#import "Styles.h"

@interface FeaturedContentVC() <UIScrollViewDelegate, FeaturedContentCellViewDelegate,
ExploreChannelCellViewDelegate>

@property (strong, nonatomic) NSMutableArray *exploreChannels;
@property (strong, nonatomic) NSMutableArray *featuredChannels;

@property (nonatomic) UIRefreshControl *refreshControl;

@property (nonatomic) BOOL loadingMoreChannels;
@property (nonatomic) BOOL refreshing;

#define HEADER_HEIGHT 50.f
#define HEADER_FONT_SIZE 20.f
#define CELL_HEIGHT 350.f

#define LOAD_MORE_CUTOFF 3

@end

@implementation FeaturedContentVC

@dynamic refreshControl;

- (void)viewDidLoad {
	[super viewDidLoad];
	self.loadingMoreChannels = NO;
	self.refreshing = NO;
	self.view.backgroundColor = [UIColor blackColor];
	[self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	self.tableView.allowsMultipleSelection = NO;
	self.tableView.showsHorizontalScrollIndicator = NO;
	self.tableView.showsVerticalScrollIndicator = NO;
	self.tableView.delegate = self;

	//avoid covering last item in uitableview
	//todo: change this when bring back search bar
	UIEdgeInsets inset = UIEdgeInsetsMake(0, 0, TAB_BAR_HEIGHT + STATUS_BAR_HEIGHT, 0);
	self.tableView.contentInset = inset;
	self.tableView.scrollIndicatorInsets = inset;

	[self addRefreshFeature];
	[self refreshChannels];
}

-(void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.tableView reloadData];
}

-(void) viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:0]; ++i) {
		[(FeaturedContentCellView*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]] offScreen];
	}
	for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:1]; ++i) {
		[(ExploreChannelCellView*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:1]] offScreen];
	}
}

-(void) refreshChannels {
	self.refreshing = YES;
	[[FeedQueryManager sharedInstance] loadFeaturedChannelsWithCompletionHandler:^(NSArray *featuredChannels) {
		self.featuredChannels = nil;
		[self.featuredChannels addObjectsFromArray:featuredChannels];
		[self.tableView reloadData];
		self.refreshing = NO;
	}];
	[[FeedQueryManager sharedInstance] refreshExploreChannelsWithCompletionHandler:^(NSArray *exploreChannels) {
		self.exploreChannels = nil;
		[self.refreshControl endRefreshing];
		[self.exploreChannels addObjectsFromArray: exploreChannels];
		[self.tableView reloadData];
		self.refreshing = NO;
	}];
}

-(void) loadMoreChannels {
	self.loadingMoreChannels = YES;
	[[FeedQueryManager sharedInstance] loadMoreExploreChannelsWithCompletionHandler:^(NSArray *exploreChannels) {
		if (exploreChannels.count) {
			[self.exploreChannels addObjectsFromArray: exploreChannels];
			[self.tableView reloadData];
			self.loadingMoreChannels = NO;
		}
	}];
}

-(void)addRefreshFeature{
	self.refreshControl = [[UIRefreshControl alloc] init];
	[self.refreshControl addTarget:self action:@selector(refreshChannels) forControlEvents:UIControlEventValueChanged];
	[self.tableView addSubview:self.refreshControl];
}

-(void) channelSelected:(Channel *)channel {
	ProfileVC * userProfile = [[ProfileVC alloc] init];
	userProfile.isCurrentUserProfile = channel.channelCreator == [PFUser currentUser];
	userProfile.isProfileTab = NO;
	userProfile.userOfProfile = channel.channelCreator;
	userProfile.startChannel = channel;
	[self presentViewController:userProfile animated:YES completion:^{
	}];
}

#pragma mark - Table View delegate methods -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *sectionName;
	switch (section) {
		case 0:
			sectionName = NSLocalizedString(@"Featured Content", @"Featured Content");
			break;
		case 1:
			sectionName = NSLocalizedString(@"Explore", @"Explore");
			break;
		default:
			sectionName = @"";
			break;
	}
	return sectionName;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return HEADER_HEIGHT;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
	// Background color
	view.tintColor = [UIColor blackColor];
	// Text Color
	UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
	[header.textLabel setTextColor:[UIColor whiteColor]];
	[header.textLabel setFont:[UIFont fontWithName:DEFAULT_FONT size:HEADER_FONT_SIZE]];
	[header.textLabel setTextAlignment:NSTextAlignmentCenter];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return 1;
		case 1:
			return self.exploreChannels.count;
		default:
			return 0;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	return CELL_HEIGHT;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// All cells should be non selectable
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *identifier = [NSString stringWithFormat:@"cell,%ld%ld", (long)indexPath.section, (long)indexPath.row % 10]; // reuse cells every 10
	if (indexPath.section == 0) {
		FeaturedContentCellView *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
		if(cell == nil) {
			cell = [[FeaturedContentCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
			[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
			cell.delegate = self;
		}
		if (!cell.alreadyPresented && self.featuredChannels.count > 0) {
			//Only one featured content cell
			[cell presentChannels: self.featuredChannels];
		}

		[cell onScreen];
		return cell;
	} else {
		ExploreChannelCellView *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
		if(cell == nil) {
			cell = [[ExploreChannelCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
			[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
			cell.delegate = self;
		}
		if (self.exploreChannels.count > indexPath.row) {
			Channel *channel = [self.exploreChannels objectAtIndex: indexPath.row];
			if (cell.channelBeingPresented != channel) {
				[cell clearViews];
				[cell presentChannel: channel];
			}
		}
		[cell onScreen];

		if (self.exploreChannels.count - indexPath.row <= LOAD_MORE_CUTOFF &&
			!self.loadingMoreChannels && !self.refreshing) {
			[self loadMoreChannels];
		}
		return cell;
	}
}

//Pause videos
-(void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {

}

// Play videos
- (void) scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {

}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	// If the indexpath is not within visible objects then it is offscreen
	if ([tableView.indexPathsForVisibleRows indexOfObject:indexPath] == NSNotFound) {
		if (indexPath.section == 0) {
			[(FeaturedContentCellView*)cell offScreen];
		} else {
			[(ExploreChannelCellView*)cell offScreen];
		}
	}
}

-(CGFloat) getVisibileCellIndex{
	return self.tableView.contentOffset.y / CELL_HEIGHT;
}

#pragma mark - Lazy Instantiation -

-(NSMutableArray *) exploreChannels {
	if (!_exploreChannels) {
		_exploreChannels =[[NSMutableArray alloc] init];
	}
	return _exploreChannels;
}

-(NSMutableArray *) featuredChannels {
	if (!_featuredChannels) {
		_featuredChannels = [[NSMutableArray alloc] init];
	}
	return _featuredChannels;
}


@end
