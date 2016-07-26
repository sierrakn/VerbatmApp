//
//  SearchResultsVC.m
//  Verbatm
//
//  Created by Sierra Kaplan-Nelson on 7/1/16.
//  Copyright © 2016 Verbatm. All rights reserved.
//

#import "SearchResultsVC.h"

#import <Crashlytics/Crashlytics.h>
#import "ParseBackendKeys.h"
#import <Parse/PFObject.h>
#import <Parse/PFQuery.h>
#import "ProfileVC.h"
#import "Icons.h"
#define SEARCH_RESULTS_LIMIT 50

@interface SearchResultsVC ()

@property (strong, nonatomic) NSArray *searchResults;
@property (strong, nonatomic) PFQuery *currentQuery;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@property (nonatomic) UIImageView * noSearchResults;

#define NOTIFICATION_XOFFSET 10.f
#define NOTIFICATION_YOFFSET 30.f

@end

@implementation SearchResultsVC

-(void) viewDidLoad {
	self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
}

-(void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if ([self.spinner isAnimating]) {
		[self.spinner stopAnimating];
		[self.spinner removeFromSuperview];
	}
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleDefault;
}

-(BOOL) prefersStatusBarHidden {
	return NO;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
	searchController.searchBar.placeholder = @"Search for blog names or usernames";
	//set frame for activity indicator
	NSString *searchText = searchController.searchBar.text;
	if (!searchText.length) {
		searchController.searchBar.tintColor = [UIColor whiteColor];
		return;
	}
	[self setNeedsStatusBarAppearanceUpdate];
	searchController.searchBar.tintColor = [UIColor blueColor];
	if (![self.spinner isAnimating]) {
		UITextField *searchField = [searchController.searchBar valueForKey:@"_searchField"];
		self.spinner.center = CGPointMake(searchField.frame.size.width - self.spinner.frame.size.width - 10.f,
										  searchController.searchBar.center.y);
		[searchController.searchBar addSubview: self.spinner];
		[self.spinner startAnimating];
	}
	[self filterResults: searchText];
}

-(void)filterResults:(NSString *)searchTerm {
	PFQuery *channelNameQuery = [[PFQuery alloc] initWithClassName:CHANNEL_PFCLASS_KEY];
	[channelNameQuery whereKey:CHANNEL_NAME_KEY matchesRegex:searchTerm modifiers:@"i"];
	PFQuery *channelCreatorQuery = [PFQuery queryWithClassName:CHANNEL_PFCLASS_KEY];
	[channelCreatorQuery whereKey:CHANNEL_CREATOR_NAME_KEY matchesRegex:searchTerm modifiers:@"i"];
	if (self.currentQuery) [self.currentQuery cancel];
	self.currentQuery = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects: channelNameQuery, channelCreatorQuery, nil]];
	[self.currentQuery orderByDescending:CHANNEL_NUM_FOLLOWS];
	self.currentQuery.limit = SEARCH_RESULTS_LIMIT;
	[self.currentQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
		if ([self.spinner isAnimating]) {
			[self.spinner stopAnimating];
			[self.spinner removeFromSuperview];
		}
		if (error) {
			[[Crashlytics sharedInstance] recordError:error];
            [self presentNoSearchResultsIcon];
		} else {
			self.searchResults = objects;
            [self.tableView reloadData];
            if(!objects || objects.count == 0){
                [self presentNoSearchResultsIcon];
            }else{
                [self removeNoSearchResultsIcon];
            }
		}
	}];
}

-(void)presentNoSearchResultsIcon{
    if(!self.noSearchResults){
        CGFloat width = self.view.frame.size.width - (2*NOTIFICATION_XOFFSET);
        CGFloat height = width * EMTPY_SEARCH_ICON_HeightWidth_RATIO;
        self.noSearchResults = [[UIImageView alloc] initWithImage:[UIImage imageNamed:EMPTY_SEARCH_RESULTS_ICON]];
        self.noSearchResults.frame = CGRectMake(NOTIFICATION_XOFFSET, NOTIFICATION_YOFFSET, width, height);
        [self.view addSubview:self.noSearchResults];
    }
}

-(void)removeNoSearchResultsIcon{
    if(self.noSearchResults){
        [self.noSearchResults removeFromSuperview];
        self.noSearchResults = nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *identifier = [NSString stringWithFormat:@"cell,%ld", (long)indexPath.row];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

	if(cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	} else {
		[cell removeFromSuperview];
	}
	PFObject *result = self.searchResults[indexPath.row];
	[result[CHANNEL_CREATOR_KEY] fetchIfNeededInBackground];
	NSString *userName = result[CHANNEL_CREATOR_NAME_KEY];
	NSString *blogText = result[CHANNEL_NAME_KEY];
	if(userName) {
		blogText = [blogText stringByAppendingString:@" by "];
		blogText = [blogText stringByAppendingString:userName];
	}
	[cell.textLabel setText: blogText];
    [self removeNoSearchResultsIcon];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	PFObject *channelObj = self.searchResults[indexPath.row];
	//todo: when someone navigates to a channel from search or a list they need the follow object
	Channel *channel = [[Channel alloc] initWithChannelName:channelObj[CHANNEL_NAME_KEY]
												   andParseChannelObject:channelObj
													   andChannelCreator:channelObj[CHANNEL_CREATOR_KEY] andFollowObject:nil];
	ProfileVC * userProfile = [[ProfileVC alloc] init];
	userProfile.isCurrentUserProfile = [channel.channelCreator.objectId isEqualToString:[PFUser currentUser].objectId];
	userProfile.isProfileTab = NO;
	userProfile.ownerOfProfile = channel.channelCreator;
	userProfile.channel = channel;
	[self presentViewController:userProfile animated:YES completion:^{
	}];
}

@end
