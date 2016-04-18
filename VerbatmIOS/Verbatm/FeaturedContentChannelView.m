//
//  FeaturedContentChannelView.m
//  Verbatm
//
//  Created by Sierra Kaplan-Nelson on 4/15/16.
//  Copyright © 2016 Verbatm. All rights reserved.
//

#import "Channel.h"
#import "FeaturedContentChannelView.h"
#import "ParseBackendKeys.h"
#import "Page_BackendObject.h"
#import "PostView.h"
#import "Post_BackendObject.h"
#import "Styles.h"

#import <Parse/PFObject.h>
#import <Parse/PFUser.h>

@interface FeaturedContentChannelView()

@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UILabel *channelNameLabel;
// shows latest post in channel
@property (nonatomic, strong) Channel *channel;
@property (nonatomic, strong) PostView *postView;
@property (nonatomic, strong) PFObject *post;
@property (nonatomic, strong) NSArray *pages;

#define POST_VIEW_Y_OFFSET 50.f
#define OFFSET 10.f

@end

@implementation FeaturedContentChannelView

-(instancetype) initWithFrame:(CGRect)frame andChannel:(Channel*)channel
				andPostObject: (PFObject *)post andPages: (NSArray *) pages {
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor darkGrayColor];
		self.channel = channel;
		[self addSubview:self.followButton];
		[self.userNameLabel setText: [channel.channelCreator valueForKey:VERBATM_USER_NAME_KEY]];
		[self addSubview:self.userNameLabel];
		[self.channelNameLabel setText: channel.name];
		[self addSubview: self.channelNameLabel];
		self.post = post;
		self.pages = pages;
		[self loadPostView];
	}
	return self;
}

-(void) loadPostView {
	CGRect postViewFrame = CGRectMake(OFFSET, POST_VIEW_Y_OFFSET, self.bounds.size.width - (OFFSET * 2),
									  self.bounds.size.height - (OFFSET + POST_VIEW_Y_OFFSET));
	self.postView = [[PostView alloc] initWithFrame:postViewFrame andPostChannelActivityObject: self.post];
	[self.postView renderPostFromPageObjects: self.pages];
	[self.postView postOffScreen];
	[self addSubview: self.postView];
}

-(void) followButtonPressed {
	//todo:
}

#pragma mark - Lazy Instantiation -

//todo: make numbers constants

-(UILabel *) userNameLabel {
	if (!_userNameLabel) {
		CGRect labelFrame = CGRectMake(0.f, 0.f, 100.f, 20.f);
		_userNameLabel = [[UILabel alloc] initWithFrame:labelFrame];
		[_userNameLabel setAdjustsFontSizeToFitWidth:YES];
		[_userNameLabel setFont:[UIFont fontWithName:DEFAULT_FONT size:20.f]];
		[_userNameLabel setTextColor:VERBATM_GOLD_COLOR];
	}
	return _userNameLabel;
}

-(UIButton *) followButton {
	if (!_followButton) {
		CGRect followFrame = CGRectMake(self.frame.size.width - 70.f, OFFSET, 70.f, 20.f); //todo
		_followButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_followButton.frame = followFrame;
		[_followButton setTitle:@"Follow" forState:UIControlStateNormal];
		[_followButton addTarget:self action:@selector(followButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	}
	return _followButton;
}

-(UILabel *) channelNameLabel {
	if (!_channelNameLabel) {
		CGRect channelNameFrame = CGRectMake(OFFSET, self.followButton.frame.origin.y + self.followButton.frame.size.height + OFFSET,
											 self.frame.size.width - (OFFSET *2), 50.f);
		_channelNameLabel.frame = channelNameFrame;
		[_channelNameLabel setAdjustsFontSizeToFitWidth:YES];
		[_channelNameLabel setFont:[UIFont fontWithName:DEFAULT_FONT size:20.f]]; //todo:
		[_channelNameLabel setTextColor:[UIColor blackColor]];
	}
	return _channelNameLabel;
}

@end