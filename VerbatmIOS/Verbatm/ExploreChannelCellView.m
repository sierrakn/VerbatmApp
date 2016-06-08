//
//  ExploreChannelCellView.m
//  Verbatm
//
//  Created by Sierra Kaplan-Nelson on 4/15/16.
//  Copyright © 2016 Verbatm. All rights reserved.
//

#import "ExploreChannelCellView.h"
#import "Icons.h"
#import "Follow_BackendManager.h"
#import "ParseBackendKeys.h"
#import "Page_BackendObject.h"
#import "Post_BackendObject.h"
#import "PostsQueryManager.h"
#import "PostView.h"
#import "SizesAndPositions.h"
#import "Styles.h"

#import <Parse/PFUser.h>

@interface ExploreChannelCellView() <UIScrollViewDelegate, UIGestureRecognizerDelegate>

// view for content so that there can be a black footer in every cell
@property (nonatomic, strong) UIView *mainView;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UILabel *numFollowersLabel;
@property (nonatomic, strong) UILabel *channelNameLabel;

@property (strong, nonatomic) UIScrollView *horizontalScrollView;
@property (strong, nonatomic) NSMutableArray *postViews;
@property (nonatomic) NSInteger indexOnScreen;

@property (nonatomic) BOOL isFollowed;
@property (nonatomic, strong) NSNumber *numFollowers;
@property (weak, readwrite) Channel *channelBeingPresented;


#define MAIN_VIEW_OFFSET 10.f
#define POST_VIEW_OFFSET 10.f
#define POST_VIEW_WIDTH 180.f
#define OFFSET 5.f
#define NUM_FOLLOWERS_WIDTH 40.f

@end

@implementation ExploreChannelCellView

-(instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		self.isFollowed = NO;
		self.indexOnScreen = 0;
		self.backgroundColor = [UIColor clearColor];
		[self addSubview: self.mainView];
		[self.mainView addSubview:self.horizontalScrollView];

		UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTapped:)];
		tap.delegate = self;
		[self addGestureRecognizer:tap];
	}
	return self;
}

-(void) cellTapped:(UITapGestureRecognizer*)gesture {
	[self.delegate channelSelected:self.channelBeingPresented];
}

-(void) layoutSubviews {
	self.mainView.frame = CGRectMake(MAIN_VIEW_OFFSET, MAIN_VIEW_OFFSET,
									 self.frame.size.width - MAIN_VIEW_OFFSET*2,
									 self.frame.size.height - MAIN_VIEW_OFFSET*2);
	self.followButton.frame = CGRectMake(POST_VIEW_OFFSET, OFFSET, FOLLOW_BUTTON_WIDTH, DISCOVER_USERNAME_AND_FOLLOW_HEIGHT);
	self.numFollowersLabel.frame = CGRectMake(self.followButton.frame.origin.x + FOLLOW_BUTTON_WIDTH + OFFSET, OFFSET, NUM_FOLLOWERS_WIDTH,
											  DISCOVER_USERNAME_AND_FOLLOW_HEIGHT);
	CGFloat userNameX = self.numFollowersLabel.frame.origin.x + self.numFollowersLabel.frame.size.width + OFFSET;
	self.userNameLabel.frame = CGRectMake(userNameX, OFFSET, self.mainView.frame.size.width - userNameX - OFFSET, DISCOVER_USERNAME_AND_FOLLOW_HEIGHT);

	self.channelNameLabel.frame = CGRectMake(OFFSET, OFFSET + DISCOVER_USERNAME_AND_FOLLOW_HEIGHT,
											 self.mainView.frame.size.width - (OFFSET*2),
											 DISCOVER_CHANNEL_NAME_HEIGHT);

	CGFloat postScrollViewOffset = self.channelNameLabel.frame.origin.y + self.channelNameLabel.frame.size.height;
	self.horizontalScrollView.frame = CGRectMake(0.f, postScrollViewOffset, self.mainView.frame.size.width,
												 self.mainView.frame.size.height - postScrollViewOffset);

    self.horizontalScrollView.showsHorizontalScrollIndicator = NO;
	CGFloat xCoordinate = POST_VIEW_OFFSET;
	for (PostView *postView in self.postViews) {
		CGRect frame = CGRectMake(xCoordinate, POST_VIEW_OFFSET, POST_VIEW_WIDTH,
								  self.horizontalScrollView.frame.size.height - (POST_VIEW_OFFSET*2));
		postView.frame = frame;
		[postView showPageUpIndicator];
		xCoordinate += POST_VIEW_WIDTH + POST_VIEW_OFFSET;
	}
	self.horizontalScrollView.contentSize = CGSizeMake(xCoordinate, self.horizontalScrollView.contentSize.height);
	[self setPostsOnScreen];
}

-(void) presentChannel:(Channel *)channel {
	self.channelBeingPresented = channel;

	[self.channelNameLabel setText: channel.name];
	[channel getChannelOwnerNameWithCompletionBlock:^(NSString *name) {
		[self.userNameLabel setText: name];
	}];

	__block CGFloat xCoordinate = POST_VIEW_OFFSET;
	[PostsQueryManager getPostsInChannel:channel withLimit:3 withCompletionBlock:^(NSArray *postChannelActivityObjects) {
		for (PFObject *postChannelActivityObj in postChannelActivityObjects) {
			PFObject *post = [postChannelActivityObj objectForKey:POST_CHANNEL_ACTIVITY_POST];
			[Page_BackendObject getPagesFromPost:post andCompletionBlock:^(NSArray * pages) {
				CGRect frame = CGRectMake(xCoordinate, POST_VIEW_OFFSET, POST_VIEW_WIDTH,
										  self.horizontalScrollView.frame.size.height - (POST_VIEW_OFFSET*2));
				PostView *postView = [[PostView alloc] initWithFrame:frame andPostChannelActivityObject:post small:YES];
				[postView postOffScreen];
				[postView renderPostFromPageObjects: pages];
				xCoordinate += POST_VIEW_WIDTH + POST_VIEW_OFFSET;
				self.horizontalScrollView.contentSize = CGSizeMake(xCoordinate, self.horizontalScrollView.contentSize.height);
				[self.horizontalScrollView addSubview: postView];
				if (self.postViews.count >= self.indexOnScreen && self.postViews.count <= self.indexOnScreen+2) {
					[postView postOnScreen];
				} else if (self.postViews.count == (self.indexOnScreen+3)) {
					[postView postAlmostOnScreen];
				}
				[postView showPageUpIndicator];
				[postView muteAllVideos:YES];
				[self.postViews addObject: postView];
			}];
		}
	}];

	[Follow_BackendManager numberUsersFollowingChannel:channel withCompletionBlock:^(NSNumber *numFollowers) {
		self.numFollowers = numFollowers;
		[self changeNumFollowersLabel];
	}];

	//Since this is in explore we know the channel is not followed by user
	[self updateFollowIcon];
	[self.mainView addSubview:self.followButton];
	[self.mainView addSubview:self.userNameLabel];
	[self.mainView addSubview:self.channelNameLabel];
	[self.mainView addSubview:self.numFollowersLabel];
}

-(void) clearViews {
	[self offScreen];

	self.channelBeingPresented = nil;
	self.indexOnScreen = 0;
	self.isFollowed = NO;
	self.numFollowers = 0;

	[self.userNameLabel removeFromSuperview];
	[self.followButton removeFromSuperview];
	[self.channelNameLabel removeFromSuperview];
	self.userNameLabel = nil;
	self.followButton = nil;
	self.channelNameLabel = nil;

	for (PostView *postView in self.postViews) {
		[postView removeFromSuperview];
	}
	self.postViews = nil;
}

-(void) followButtonPressed {
	self.isFollowed = !self.isFollowed;
	if (self.isFollowed) {
		self.numFollowers = [NSNumber numberWithInteger:[self.numFollowers integerValue]+1];
		[Follow_BackendManager currentUserFollowChannel: self.channelBeingPresented];
	} else {
		self.numFollowers = [NSNumber numberWithInteger:[self.numFollowers integerValue]-1];
		[Follow_BackendManager user:[PFUser currentUser] stopFollowingChannel: self.channelBeingPresented];
	}
	[self updateFollowIcon];
	[self changeNumFollowersLabel];
}

-(void) updateFollowIcon {
	UIImage * newbuttonImage = self.isFollowed ? [UIImage imageNamed:FOLLOWING_ICON_LIGHT] : [UIImage imageNamed:FOLLOW_ICON_LIGHT];
	[self.followButton setImage:newbuttonImage forState:UIControlStateNormal];
}

-(void) changeNumFollowersLabel {
	[self.numFollowersLabel setText:[self.numFollowers stringValue]];
}

-(void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if (!decelerate) {
		[self setPostsOnScreen];
	}
}

-(void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	[self setPostsOnScreen];
}

-(void) setPostsOnScreen {
	CGFloat originX = self.horizontalScrollView.contentOffset.x;
	//Round down/truncate
	NSInteger postIndex = originX / (POST_VIEW_WIDTH + POST_VIEW_OFFSET);

	//Three posts can be visible
	for (NSInteger i = postIndex; i < postIndex+3; i++) {
		// Set previous on screen posts off screen
		NSInteger previousPostIndex = self.indexOnScreen+(i-postIndex);
		if (previousPostIndex < self.postViews.count &&
			(previousPostIndex < postIndex || previousPostIndex > postIndex+2)) {
			[(PostView*)self.postViews[previousPostIndex] postOffScreen];
		}
		// set posts on screen
		if (i < self.postViews.count) {
			[(PostView*)self.postViews[i] postOnScreen];
		}
	}
	// Prepare next view
	if (postIndex + 3 < self.postViews.count) {
		[(PostView*)self.postViews[postIndex+3] postAlmostOnScreen];
	}
}

-(void) setAllPostsOffScreen {
	for (PostView* postView in self.postViews) {
		[postView postOffScreen];
	}
}

-(void) offScreen {
	[self setAllPostsOffScreen];
}

-(void) onScreen {
	[self setPostsOnScreen];
}

-(void) almostOnScreen {
	for (PostView* postView in self.postViews) {
		[postView postAlmostOnScreen];
	}
}

-(void) pauseAllVideos {

}

#pragma mark - Lazy Instantiation -

-(UIView *) mainView {
	if (!_mainView) {
		_mainView = [[UIView alloc] init];
		_mainView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.2f];
		_mainView.layer.borderColor = [UIColor whiteColor].CGColor;
		_mainView.layer.borderWidth = 1.f;
		_mainView.layer.cornerRadius = 5.f;
	}
	return _mainView;
}

-(UIScrollView *) horizontalScrollView {
	if (!_horizontalScrollView) {
		_horizontalScrollView = [[UIScrollView alloc] init];
		_horizontalScrollView.backgroundColor = [UIColor clearColor];
		_horizontalScrollView.delegate = self;
		_horizontalScrollView.showsVerticalScrollIndicator = NO;
		_horizontalScrollView.showsHorizontalScrollIndicator = YES;
	}
	return _horizontalScrollView;
}

-(NSMutableArray *) postViews {
	if (!_postViews) {
		_postViews = [[NSMutableArray alloc] init];
	}
	return _postViews;
}

-(UILabel *) userNameLabel {
	if (!_userNameLabel) {
		_userNameLabel = [[UILabel alloc] init];
		[_userNameLabel setAdjustsFontSizeToFitWidth:YES];
		[_userNameLabel setFont:[UIFont fontWithName:REGULAR_FONT size:DISCOVER_USER_NAME_FONT_SIZE]];
		[_userNameLabel setTextColor:VERBATM_GOLD_COLOR];
		[_userNameLabel setTextAlignment:NSTextAlignmentRight];
	}
	return _userNameLabel;
}

-(UIButton *) followButton {
	if (!_followButton) {
		_followButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_followButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
		[_followButton addTarget:self action:@selector(followButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	}
	return _followButton;
}

-(UILabel *) numFollowersLabel {
	if (!_numFollowersLabel) {
		_numFollowersLabel = [[UILabel alloc] init];
		[_numFollowersLabel setAdjustsFontSizeToFitWidth:YES];
		[_numFollowersLabel setTextAlignment:NSTextAlignmentLeft];
		[_numFollowersLabel setFont:[UIFont fontWithName:REGULAR_FONT size:DISCOVER_USER_NAME_FONT_SIZE]];
		[_numFollowersLabel setTextColor:[UIColor whiteColor]];
	}
	return _numFollowersLabel;
}

-(UILabel *) channelNameLabel {
	if (!_channelNameLabel) {
		_channelNameLabel = [[UILabel alloc] init];
		[_channelNameLabel setAdjustsFontSizeToFitWidth:YES];
		[_channelNameLabel setTextAlignment:NSTextAlignmentCenter];
		[_channelNameLabel setFont:[UIFont fontWithName:INFO_LIST_HEADER_FONT size:DISCOVER_CHANNEL_NAME_FONT_SIZE]];
		[_channelNameLabel setTextColor:[UIColor whiteColor]];
	}
	return _channelNameLabel;
}

-(void) dealloc {

}

@end
