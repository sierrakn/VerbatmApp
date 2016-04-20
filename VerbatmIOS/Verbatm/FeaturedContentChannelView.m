//
//  FeaturedContentChannelView.m
//  Verbatm
//
//  Created by Sierra Kaplan-Nelson on 4/15/16.
//  Copyright © 2016 Verbatm. All rights reserved.
//

#import "Channel.h"
#import "Icons.h"
#import "FeaturedContentChannelView.h"
#import "Follow_BackendManager.h"
#import "ParseBackendKeys.h"
#import "Page_BackendObject.h"
#import "PostView.h"
#import "Post_BackendObject.h"
#import "SizesAndPositions.h"
#import "Styles.h"

#import <Parse/PFObject.h>
#import <Parse/PFUser.h>

@interface FeaturedContentChannelView() <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UILabel *channelNameLabel;
// shows latest post in channel
@property (nonatomic, strong) Channel *channel;
@property (nonatomic, strong) PostView *postView;
@property (nonatomic, strong) PFObject *post;
@property (nonatomic, strong) NSArray *pages;
@property (nonatomic) BOOL isFollowed;

#define POST_VIEW_Y_OFFSET 60.f
#define OFFSET 5.f
#define CHANNEL_NAME_FONT_SIZE 20.f

@end

@implementation FeaturedContentChannelView

-(instancetype) initWithFrame:(CGRect)frame andChannel:(Channel*)channel
				andPostObject: (PFObject *)post andPages: (NSArray *) pages {
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor darkGrayColor];
		self.channel = channel;

		if (self.channel.channelCreator != [PFUser currentUser]) {
			[Follow_BackendManager currentUserFollowsChannel:self.channel withCompletionBlock:^(bool isFollowed) {
				self.isFollowed = isFollowed;
				dispatch_async(dispatch_get_main_queue(), ^{
					[self updateFollowIcon];
					[self addSubview:self.followButton];
				});
			}];
		}

		[channel getChannelOwnerNameWithCompletionBlock:^(NSString *name) {
			[self.userNameLabel setText: name];
		}];
		[self addSubview:self.userNameLabel];
		[self.channelNameLabel setText: channel.name];
		[self addSubview: self.channelNameLabel];
		self.post = post;
		self.pages = pages;
		[self loadPostView];

		UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTapped:)];
		tap.delegate = self;
		[self addGestureRecognizer:tap];

	}
	return self;
}

-(void) cellTapped:(UITapGestureRecognizer*)gesture {
	[self.delegate channelSelected:self.channel];
}

-(void) loadPostView {
	CGRect postViewFrame = CGRectMake(OFFSET, POST_VIEW_Y_OFFSET, self.bounds.size.width - (OFFSET * 2),
									  self.bounds.size.height - (OFFSET + POST_VIEW_Y_OFFSET));
	self.postView = [[PostView alloc] initWithFrame:postViewFrame andPostChannelActivityObject: self.post small:YES];
	[self.postView renderPostFromPageObjects: self.pages];
	[self.postView postOffScreen];
	[self.postView muteAllVideos:YES];
	[self addSubview: self.postView];
}

-(void) followButtonPressed {
	self.isFollowed = !self.isFollowed;
	if (self.isFollowed) {
		[Follow_BackendManager currentUserFollowChannel: self.channel];
	} else {
		[Follow_BackendManager user:[PFUser currentUser] stopFollowingChannel: self.channel];
	}
	[self updateFollowIcon];
}

-(void) updateFollowIcon {
	UIImage * newbuttonImage = self.isFollowed ? [UIImage imageNamed:FOLLOWING_ICON_LIGHT] : [UIImage imageNamed:FOLLOW_ICON_LIGHT];
	[self.followButton setImage:newbuttonImage forState:UIControlStateNormal];
}

-(void) onScreen {
	[self.postView postOnScreen];
}

-(void) offScreen {
	[self.postView postOffScreen];
}

-(void) almostOnScreen {
	[self.postView preparepostToBePresented];
}

#pragma mark - Lazy Instantiation -

//todo: make numbers constants

-(UILabel *) userNameLabel {
	if (!_userNameLabel) {
		CGRect labelFrame = CGRectMake(OFFSET, OFFSET, 130.f, 20.f); //todo: make constants
		_userNameLabel = [[UILabel alloc] initWithFrame:labelFrame];
		[_userNameLabel setAdjustsFontSizeToFitWidth:YES];
		[_userNameLabel setFont:[UIFont fontWithName:DEFAULT_FONT size:20.f]];
		[_userNameLabel setTextColor:VERBATM_GOLD_COLOR];
	}
	return _userNameLabel;
}

-(UIButton *) followButton {
	if (!_followButton) {
		CGRect followFrame = CGRectMake(self.frame.size.width - FOLLOW_BUTTON_WIDTH - OFFSET, OFFSET,
										FOLLOW_BUTTON_WIDTH, FOLLOW_BUTTON_HEIGHT - 5.f);
		_followButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_followButton.frame = followFrame;
		_followButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
		[_followButton addTarget:self action:@selector(followButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	}
	return _followButton;
}

-(UILabel *) channelNameLabel {
	if (!_channelNameLabel) {
		CGRect channelNameFrame = CGRectMake(OFFSET, self.followButton.frame.size.height + self.followButton.frame.origin.y,
											 self.frame.size.width - (OFFSET *2), 40.f); //todo: make constnats
		_channelNameLabel = [[UILabel alloc] initWithFrame:channelNameFrame];
		[_channelNameLabel setAdjustsFontSizeToFitWidth:YES];
		[_channelNameLabel setTextAlignment:NSTextAlignmentCenter];
		[_channelNameLabel setFont:[UIFont fontWithName:INFO_LIST_HEADER_FONT size:CHANNEL_NAME_FONT_SIZE]];
		[_channelNameLabel setTextColor:[UIColor whiteColor]];
	}
	return _channelNameLabel;
}

@end
