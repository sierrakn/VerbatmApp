//
//  ChannelOrUsernameCV.m
//  Verbatm
//
//  Created by Iain Usiri on 1/17/16.
//  Copyright © 2016 Verbatm. All rights reserved.
//

#import "ChannelOrUsernameCV.h"
#import "Follow_BackendManager.h"

#import "Notifications.h"

#import "SizesAndPositions.h"
#import "Styles.h"
#import <Parse/PFObject.h>
#import "ParseBackendKeys.h"
#import <Parse/PFUser.h>

#import "UserInfoCache.h"

@import UIKit;

@interface ChannelOrUsernameCV ()<UIScrollViewDelegate>
@property (nonatomic) Channel *channel;
@property (nonatomic) Comment  *commentObject;

@property (nonatomic) BOOL isAChannel;
@property (nonatomic) BOOL isAChannelIFollow;

@property (nonatomic, strong) UILabel *usernameLabel;

@property (nonatomic,strong) UILabel *commentLabel;
@property (nonatomic, strong) UILabel *commentUserNameLabel;

@property (nonatomic) NSString *userName;

@property (strong, nonatomic) NSDictionary* userNameLabelAttributes;
@property (strong, nonatomic) NSDictionary* userNameCommentLabelAttributes;
@property (strong, nonatomic) NSDictionary* commentStringLabelAttributes;


@property (nonatomic) UIView *separatorView;

@property (nonatomic) UILabel *headerTitle;//makes the cell a header for the table view
@property (nonatomic) BOOL isHeaderTile;
@property (nonatomic) UIButton *followButton;
@property (nonatomic) BOOL currentUserFollowingChannelUser;

@property(nonatomic) UIView * labelHolder;//needed for sliding effect - holds the name labels
@property (nonatomic) UIScrollView * deleteButtonScrollView;
@property (nonatomic) UIButton * deleteCommentButton;


#define DELETE_BUTTON_WIDTH 100.f

#define MAX_WIDTH (self.followButton.frame.origin.x - (TAB_BUTTON_PADDING_X * 2))
@end

@implementation ChannelOrUsernameCV

- (void)awakeFromNib {
	// Initialization code
}

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier isChannel:(BOOL) isChannel {
	self = [super initWithStyle: style reuseIdentifier: reuseIdentifier] ;

	if (self) {
		self.backgroundColor = [UIColor whiteColor];
		self.isAChannel = isChannel;
		self.clipsToBounds = YES;
		[self registerForFollowNotification];
		[self createSelectedTextAttributes];
	}

	return self;
}

-(void)registerForFollowNotification{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(userFollowStatusChanged:)
												 name:NOTIFICATION_NOW_FOLLOWING_USER
											   object:nil];
}

-(void)userFollowStatusChanged:(NSNotification *) notification {
	NSDictionary * userInfo = [notification userInfo];
	if(userInfo){
		NSString * userId = userInfo[USER_FOLLOWING_NOTIFICATION_USERINFO_KEY];
		NSNumber * isFollowingAction = userInfo[USER_FOLLOWING_NOTIFICATION_ISFOLLOWING_KEY];
		//only update the follow icon if this is the correct user and also if the action was
		//no registered on this view

		if([userId isEqualToString:[self.channel.channelCreator objectId]]&&
		   ([isFollowingAction boolValue] != self.currentUserFollowingChannelUser)){

			self.currentUserFollowingChannelUser = [isFollowingAction boolValue];
			if(self.followButton)[self updateUserFollowingChannel];
		}
	}
}

+(CGFloat)getHeightForCellFromCommentObject:(Comment *) commentObject{

	CGFloat maxWidth = [[UIScreen mainScreen] bounds].size.width - (TAB_BUTTON_PADDING_X * 2);

	UILabel * heightFinder = [ChannelOrUsernameCV getTextView:[commentObject commentString] withOrigin:CGPointMake(0.f, 0.f)
												andAttributes:[ChannelOrUsernameCV getAttrForCommentString] withMaxWidth:maxWidth];

	return heightFinder.frame.size.height + (CHANNEL_USER_LIST_CELL_HEIGHT/2.f );
}

+(NSDictionary *) getAttrForCommentString{
	NSMutableParagraphStyle *usernameAlignment = NSMutableParagraphStyle.new;
	usernameAlignment.alignment  = NSTextAlignmentLeft;
	return @{NSForegroundColorAttributeName:[UIColor blackColor],NSFontAttributeName:[UIFont fontWithName:CHANNEL_TAB_BAR_FOLLOWERS_FONT size:CHANNEL_USER_LIST_USER_NAME_FONT_SIZE],NSParagraphStyleAttributeName:usernameAlignment};
}

#pragma mark - Edit Cell formatting -

-(void)presentComment:(Comment *) commentObject{
    self.commentObject = commentObject;
	[commentObject getCommentCreatorWithCompletionBlock:^(NSString * creatorName) {
		[self setLabelsForComment:[commentObject commentString] andUserName:creatorName];
        [self prepareDeleteIcon:commentObject];
	}];
}


-(void)prepareDeleteIcon:(Comment *) comment{
    PFUser * creator = [comment.parseCommentObject valueForKey:COMMENT_USER_KEY];
    if(creator && [[creator objectId] isEqualToString:[[PFUser currentUser] objectId]]){
        self.deleteCommentButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - DELETE_BUTTON_WIDTH, 0.f, DELETE_BUTTON_WIDTH, self.frame.size.height)];
        self.deleteCommentButton.backgroundColor = [UIColor redColor];
        [self.deleteCommentButton setTitle:@"Delete" forState:UIControlStateNormal];
        [self.deleteCommentButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.deleteCommentButton addTarget:self action:@selector(deleteCommentButtonSelected) forControlEvents:UIControlEventTouchDown];
        [self addSubview:self.deleteCommentButton];
        [self bringSubviewToFront:self.deleteButtonScrollView];
        self.deleteButtonScrollView.contentSize = CGSizeMake(self.frame.size.width + DELETE_BUTTON_WIDTH, 0.f);
        self.deleteButtonScrollView.pagingEnabled = YES;
        self.deleteButtonScrollView.bounces = NO;
        self.deleteButtonScrollView.showsHorizontalScrollIndicator = NO;
        self.deleteButtonScrollView.delegate = self;
        [self bringSubviewToFront:self.separatorView];
    }
}

-(void)deleteCommentButtonSelected{
    if(self.delegate){
        [self.delegate deleteCommentSelected:self.commentObject];
        self.commentObject = nil;
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self sendSubviewToBack:self.deleteCommentButton];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if(scrollView.contentOffset.x > 0){
        [self bringSubviewToFront:self.deleteCommentButton];
        [self bringSubviewToFront:self.separatorView];
    }
}

-(void)setHeaderTitle{
	self.isHeaderTile = YES;
}

-(void)presentChannel:(Channel *) channel {
	self.channel = channel;
	PFUser *creator = [channel.parseChannelObject valueForKey:CHANNEL_CREATOR_KEY];

	if(!(self.channel.usersFollowingChannel && self.channel.usersFollowingChannel.count)){
		if(![[creator objectId] isEqualToString:[[PFUser currentUser] objectId]]){
			self.currentUserFollowingChannelUser = [[UserInfoCache sharedInstance] checkUserFollowsChannel: self.channel];
			if(self.followButton)[self updateUserFollowingChannel];
		}

	}else {
		self.currentUserFollowingChannelUser = [self.channel.usersFollowingChannel containsObject:[PFUser currentUser]];
		if(self.followButton)[self updateUserFollowingChannel];
	}


	[creator fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
		if(object) {
			NSString *userName = [creator valueForKey:VERBATM_USER_NAME_KEY];
			dispatch_async(dispatch_get_main_queue(), ^{
				self.userName = userName;

				if(![[creator objectId] isEqualToString:[[PFUser currentUser] objectId]])[self createFollowButton];

				[self setLabelsForChannel];
				[self updateUserFollowingChannel];
			});
		}
	}];

}

-(void) createFollowButton {

	if(self.followButton){
		[self.followButton removeFromSuperview];
		self.followButton = nil;
	}

	CGFloat frame_x = self.frame.size.width - 5.f - LARGE_FOLLOW_BUTTON_WIDTH;
	CGRect followButtonFrame = CGRectMake(frame_x, TAB_BUTTON_PADDING_Y, LARGE_FOLLOW_BUTTON_WIDTH, LARGE_FOLLOW_BUTTON_HEIGHT);
	self.followButton = [[UIButton alloc] initWithFrame: followButtonFrame];
	self.followButton.center = CGPointMake(self.followButton.center.x, self.center.y - self.frame.origin.y);
	self.followButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
	self.followButton.clipsToBounds = YES;
	self.followButton.layer.borderColor = [UIColor blackColor].CGColor;
	self.followButton.layer.borderWidth = 2.f;
	self.followButton.layer.cornerRadius = 10.f;
	[self.followButton addTarget:self action:@selector(followButtonSelected) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview: self.followButton];
}

-(void) followButtonSelected {
	self.currentUserFollowingChannelUser = !self.currentUserFollowingChannelUser;
	if (self.currentUserFollowingChannelUser) {
		[Follow_BackendManager currentUserFollowChannel: self.channel];
	} else {
		[Follow_BackendManager currentUserStopFollowingChannel: self.channel];
	}
	[self.channel currentUserFollowChannel: self.currentUserFollowingChannelUser];
	[self updateUserFollowingChannel];
}

-(void) updateUserFollowingChannel {
	if(self.followButton){
		if (self.currentUserFollowingChannelUser) {
			[self changeFollowButtonTitle:@"\u2713 Following" toColor:[UIColor whiteColor]];
			self.followButton.backgroundColor = [UIColor blackColor];
		} else {
			[self changeFollowButtonTitle:@"+ Follow" toColor:[UIColor blackColor]];
			self.followButton.backgroundColor = [UIColor whiteColor];
		}
	}
}

-(void) changeFollowButtonTitle:(NSString*)title toColor:(UIColor*) color{
	NSDictionary *titleAttributes = @{NSForegroundColorAttributeName: color,
									  NSFontAttributeName: [UIFont fontWithName:REGULAR_FONT size:FOLLOW_TEXT_FONT_SIZE]};
	NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:titleAttributes];
	[self.followButton setAttributedTitle:attributedTitle forState:UIControlStateNormal];
}

-(void)layoutSubviews {
	//do formatting here
	if(self.isHeaderTile){
		//it's in the tab bar list and it should have a title
		self.headerTitle = [self getHeaderTitleForViewWithText:@"Discover"];
		[self addSubview:self.headerTitle];
	} else {
		if(self.headerTitle)[self.headerTitle removeFromSuperview];
		self.headerTitle = nil;
	}
	[self addCellSeperator];
}

-(void)addCellSeperator{
	if(!self.separatorView){
		self.separatorView = [[UIView alloc] initWithFrame:CGRectMake(0.f, self.frame.size.height - CHANNEL_LIST_CELL_SEPERATOR_HEIGHT, self.frame.size.width,CHANNEL_LIST_CELL_SEPERATOR_HEIGHT)];
		self.separatorView.backgroundColor = [UIColor lightGrayColor];
		[self addSubview:self.separatorView];
	}
}

-(void)clearView{
	if(self.usernameLabel){
		[self.usernameLabel removeFromSuperview];
		self.usernameLabel = nil;
	}
	if(self.commentLabel){
		[self.commentLabel removeFromSuperview];

		self.commentLabel = nil;
	}

	if(self.commentUserNameLabel){
		[self.commentUserNameLabel removeFromSuperview];
		self.commentUserNameLabel = nil;
	}
    
    if(self.deleteButtonScrollView){
        [self.deleteButtonScrollView removeFromSuperview];
        self.deleteButtonScrollView = nil;
    }
    
    if(self.deleteCommentButton){
        [self.deleteCommentButton removeFromSuperview];
        self.deleteCommentButton = nil;
    }
}

-(void) setLabelsForChannel {

	[self clearView];

	CGPoint nameLabelOrigin = CGPointMake(TAB_BUTTON_PADDING_X, TAB_BUTTON_PADDING_Y);

	self.usernameLabel = [self getLabel:self.userName withOrigin:nameLabelOrigin
						  andAttributes:self.userNameLabelAttributes withMaxWidth:MAX_WIDTH];
	self.usernameLabel.center = CGPointMake(self.usernameLabel.center.x, self.center.y - self.frame.origin.y);

	[self addSubview: self.usernameLabel];
}

-(void)setLabelsForComment:(NSString *) comment andUserName:(NSString *) userName{
	[self clearView];

	CGFloat maxWidth = [[UIScreen mainScreen] bounds].size.width - (TAB_BUTTON_PADDING_X * 2);
	CGPoint userNameLabelOrigin = CGPointMake(TAB_BUTTON_PADDING_X, TAB_BUTTON_PADDING_Y);

	self.commentUserNameLabel = [self getLabel:userName withOrigin:userNameLabelOrigin
								 andAttributes:self.userNameCommentLabelAttributes withMaxWidth:maxWidth];

	CGPoint commentStringLabelOrigin = CGPointMake(TAB_BUTTON_PADDING_X,
													self.commentUserNameLabel.frame.origin.y + self.commentUserNameLabel.frame.size.height);

	self.commentLabel = [ChannelOrUsernameCV getTextView:comment withOrigin:commentStringLabelOrigin
										   andAttributes:self.commentStringLabelAttributes withMaxWidth:maxWidth];
    
   
    self.labelHolder = [[UIView alloc] initWithFrame:self.bounds];
    self.labelHolder.backgroundColor = self.backgroundColor;
    
    self.deleteButtonScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.deleteButtonScrollView.backgroundColor = [UIColor clearColor];
    
    [self addSubview:self.deleteButtonScrollView];
    
    [self.deleteButtonScrollView addSubview:self.labelHolder];
    
	[self.labelHolder addSubview: self.commentLabel];
	[self.labelHolder addSubview: self.commentUserNameLabel];
    [self bringSubviewToFront:self.separatorView];
}

-(UILabel *) getLabel:(NSString *) title withOrigin:(CGPoint) origin
		andAttributes:(NSDictionary *) nameLabelAttribute withMaxWidth:(CGFloat) maxWidth {
	UILabel * nameLabel = [[UILabel alloc] init];

	NSAttributedString* tabAttributedTitle = [[NSAttributedString alloc] initWithString:title attributes:nameLabelAttribute];
	CGRect textSize = [title boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:nameLabelAttribute context:nil];

	CGFloat height;
	if(self.channel) {
		height= (textSize.size.height <= (self.frame.size.height/2.f) - 2.f) ?
		textSize.size.height : self.frame.size.height/2.f;
	} else {
		height = textSize.size.height;
	}

	//todo: make code cleaner

	CGFloat width = (maxWidth > 0 && textSize.size.width > maxWidth) ? maxWidth : textSize.size.width;

	CGRect labelFrame = CGRectMake(origin.x, origin.y, width, height +7.f);

	nameLabel.frame = labelFrame;
	nameLabel.adjustsFontSizeToFitWidth = YES;
	nameLabel.numberOfLines = 1.f;
	nameLabel.backgroundColor = [UIColor clearColor];
	[nameLabel setAttributedText:tabAttributedTitle];
	return nameLabel;
}


+(UILabel *) getTextView:(NSString *) title withOrigin:(CGPoint) origin
		   andAttributes:(NSDictionary *) nameLabelAttribute withMaxWidth:(CGFloat) maxWidth {
	UILabel * textLabel = [[UILabel alloc] init];

	NSAttributedString* tabAttributedTitle = [[NSAttributedString alloc] initWithString:title attributes:nameLabelAttribute];
	CGRect textSize = [title boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:nameLabelAttribute context:nil];

	CGFloat height;

	CGFloat extraHeight = textSize.size.width - maxWidth;

	height = textSize.size.height + ((extraHeight > 0.f) ? extraHeight : 0.f);
	CGFloat width = ((maxWidth > 0) && (textSize.size.width > maxWidth)) ? maxWidth : textSize.size.width;

	CGRect labelFrame = CGRectMake(origin.x, origin.y, width, height);

	textLabel.frame = labelFrame;
	textLabel.backgroundColor = [UIColor clearColor];
	textLabel.lineBreakMode = NSLineBreakByWordWrapping;
	textLabel.numberOfLines = 0.f;
	[textLabel setAttributedText:tabAttributedTitle];
	return textLabel;
}

-(void)createSelectedTextAttributes{
	NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
	paragraphStyle.alignment                = NSTextAlignmentCenter;
	//create "followers" text
	self.userNameLabelAttributes =@{NSForegroundColorAttributeName: [UIColor blackColor],
									NSFontAttributeName: [UIFont fontWithName:CHANNEL_TAB_BAR_FOLLOWING_INFO_FONT
																		 size:CHANNEL_USER_LIST_CHANNEL_NAME_FONT_SIZE],
									NSParagraphStyleAttributeName:paragraphStyle};

	NSMutableParagraphStyle *usernameAlignment = NSMutableParagraphStyle.new;
	usernameAlignment.alignment  = NSTextAlignmentLeft;

	self.userNameCommentLabelAttributes = @{NSForegroundColorAttributeName: [UIColor blackColor],
											NSFontAttributeName: [UIFont fontWithName:CHANNEL_TAB_BAR_FOLLOWING_INFO_FONT size: CHANNEL_USER_LIST_USER_NAME_FONT_SIZE],
											NSParagraphStyleAttributeName:usernameAlignment};


	self.commentStringLabelAttributes = @{NSForegroundColorAttributeName: [UIColor blackColor],
										  NSFontAttributeName: [UIFont fontWithName:CHANNEL_TAB_BAR_FOLLOWERS_FONT size:CHANNEL_USER_LIST_USER_NAME_FONT_SIZE], NSParagraphStyleAttributeName:usernameAlignment};
}



-(UILabel *) getHeaderTitleForViewWithText:(NSString *) text{

	CGRect labelFrame = CGRectMake(0.f, 0.f, self.frame.size.width + 10, self.frame.size.height - 12.f);
	UILabel * titleLabel = [[UILabel alloc] initWithFrame:labelFrame];
	titleLabel.backgroundColor = [UIColor whiteColor];

	NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
	paragraphStyle.alignment = NSTextAlignmentCenter;

	NSDictionary * informationAttribute = @{NSForegroundColorAttributeName:
												[UIColor clearColor],
											NSFontAttributeName:
												[UIFont fontWithName:INFO_LIST_HEADER_FONT size:INFO_LIST_HEADER_FONT_SIZE],
											NSParagraphStyleAttributeName:paragraphStyle};

	NSAttributedString * titleAttributed = [[NSAttributedString alloc] initWithString:text attributes:informationAttribute];

	[titleLabel setAttributedText:titleAttributed];

	return titleLabel;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];
	
	// Configure the view for the selected state
}

@end
