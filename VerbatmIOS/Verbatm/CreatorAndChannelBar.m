//
//  CreatorAndChannelBar.m
//  Verbatm
//
//  Created by Iain Usiri on 12/29/15.
//  Copyright © 2015 Verbatm. All rights reserved.
//

#import "CreatorAndChannelBar.h"
#import "ParseBackendKeys.h"
#import <Parse/PFObject.h>
#import "Styles.h"
#import "Follow_BackendManager.h"
#import "ProfileVC.h"
#import "Follow_BackendManager.h"
#import "Notifications.h"

/*
 Give a creator and channel name this creates labels for each.
 */

#define LABEL_WALL_OFFSET 8.f
#define TEXT_FONT_TYPE @"Quicksand-Bold"
#define CREATOR_NAME_FONT_SIZE 15.f
#define CREATOR_NAME_TEXT_COLOR whiteColor

#define CHANNEL_NAME_FONT_SIZE CREATOR_NAME_FONT_SIZE
#define LABEL_TEXT_PADDING 20.f  //Distance between the text and the white border

#define FOLLOW_IMAGE_ICON_SIZE 15.f

@interface CreatorAndChannelBar ()
@property (nonatomic) Channel * currentChannel;
@property (nonatomic) PFUser * channelOwner;
@property (nonatomic) UIImageView * followImage;
@property (nonatomic) UILabel * channelNameLabel;
@property (nonatomic) UIView * channelNameLabelHolder;
@property (nonatomic) BOOL isFollowingChannel;
@end


@implementation CreatorAndChannelBar

-(instancetype) initWithFrame:(CGRect)frame andChannel:(Channel *) channel{
    self = [super initWithFrame:frame];
    if(self){
        self.currentChannel = channel;
        self.channelOwner =(PFUser *)[channel.parseChannelObject valueForKey:CHANNEL_CREATOR_KEY];
        [self createBackground];
        [self registerForNotifications];
    }
    return self;
}

-(void) addCreatorName: (NSString*) creatorName andChannelName: (NSString*) channelName{
    
    [self addCreatorNameViewWithName:creatorName];
    [self createChannelNameView:channelName];
    [self createFollowIcon];
}

-(void)registerForNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userFollowStatusChanged:)
                                                 name:NOTIFICATION_NOW_FOLLOWING_USER
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userFollowStatusChanged:)
                                                 name:NOTIFICATION_STOPPED_FOLLOWING_USER
                                               object:nil];
}


-(void)userFollowStatusChanged:(NSNotification *) notification{
    [self createFollowIcon];
}


-(void)createChannelNameView:(NSString *)channelName{
    // find size of channel text
    UIFont * fontForChannelName = [UIFont fontWithName:TEXT_FONT_TYPE size:CREATOR_NAME_FONT_SIZE];
    
    CGSize channelNameSize = [channelName sizeWithAttributes:@{NSFontAttributeName : fontForChannelName}];
    
    CGFloat channelNameFrameWidth = LABEL_TEXT_PADDING +  ((channelNameSize.width < self.frame.size.width/2.f) ?
                                                           channelNameSize.width : self.frame.size.width/2.f);
    
    //create channel name view
    
    CGFloat labelHeights = FOLLOW_IMAGE_ICON_SIZE;
    
    
    CGFloat channelNameHolderFrameWidth = (channelNameFrameWidth + labelHeights + LABEL_WALL_OFFSET);
    
    CGRect channelNameHolderViewFrame = CGRectMake(self.frame.size.width -
                                                   (channelNameHolderFrameWidth + LABEL_WALL_OFFSET),                                         (LABEL_WALL_OFFSET*0.5),
                                                   channelNameHolderFrameWidth,
                                                   self.frame.size.height - LABEL_WALL_OFFSET);
    CGRect followImageFrame = CGRectMake(4.f,(channelNameHolderViewFrame.size.height/2.f) - (labelHeights/2.f),labelHeights,
                                         labelHeights);
    CGRect channelNameFrame = CGRectMake(followImageFrame.size.width,(channelNameHolderViewFrame.size.height/2.f) - (labelHeights/2.f), channelNameFrameWidth,labelHeights);
    
    
    //create and format channel name holder view
    UIView * channelNameHolderView = [[UIView alloc] initWithFrame:channelNameHolderViewFrame];
    [self addFollowChannelGestureToView: channelNameHolderView];
    channelNameHolderView.backgroundColor = [UIColor clearColor];
    channelNameHolderView.layer.borderColor = [UIColor whiteColor].CGColor;
    channelNameHolderView.layer.borderWidth = 1.f;
    channelNameHolderView.layer.cornerRadius = channelNameHolderView.frame.size.width/15.f;
    
    
    //create follow image
    self.followImage = [[UIImageView alloc] initWithFrame:followImageFrame];
    self.followImage.backgroundColor = [UIColor clearColor];
    
    
    self.channelNameLabel = [[UILabel alloc] initWithFrame:channelNameFrame];
    self.channelNameLabel.textAlignment = NSTextAlignmentCenter;
    self.channelNameLabel.text = channelName;
    
    self.channelNameLabel.font = fontForChannelName;
    self.channelNameLabel.textColor = [UIColor CREATOR_NAME_TEXT_COLOR];
    [self.channelNameLabel setBackgroundColor:[UIColor clearColor]];
    
    
    [channelNameHolderView addSubview:self.followImage];
    [channelNameHolderView addSubview:self.channelNameLabel];
    self.channelNameLabelHolder = channelNameHolderView;
    [self addSubview:channelNameHolderView];
}


-(void)changeChannelNameToSelectedView:(BOOL) selected{
    
    if(selected){
        self.channelNameLabel.textColor = [UIColor blackColor];
    }else{
        self.channelNameLabel.textColor = [UIColor whiteColor];
    }
    
}



-(void)addCreatorNameViewWithName:(NSString *) creatorName{
    //create username
    CGRect creatorNameFrame = CGRectMake(LABEL_WALL_OFFSET,
                                         LABEL_WALL_OFFSET, self.frame.size.width/2.f,
                                         self.frame.size.height - (2*LABEL_WALL_OFFSET));
    
    UILabel* creatorNameView = [[UILabel alloc] initWithFrame:creatorNameFrame];
    creatorNameView.textAlignment = NSTextAlignmentLeft;
    creatorNameView.text = creatorName;
    UIFont * fontForCreatorName = [UIFont fontWithName:TEXT_FONT_TYPE size:CREATOR_NAME_FONT_SIZE];
    creatorNameView.font = fontForCreatorName;
    creatorNameView.textColor = [UIColor CREATOR_NAME_TEXT_COLOR];
    [creatorNameView setBackgroundColor:[UIColor clearColor]];
    
    [self addPresentChannelGestureToView:creatorNameView];
    creatorNameView.userInteractionEnabled = YES;
    [self addSubview:creatorNameView];
}


-(void)setFollowImageIsFollowing:(BOOL) isFollowing{
    UIImage * image = [UIImage imageNamed:((isFollowing) ? DARKENED_FOLLOW_ICON_IMAGE_SELECTED :FOLLOW_ICON_IMAGE_UNSELECTED)];
    self.followImage.image = image;
}



-(void) createBackground {
    self.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.3];
}




-(void)createFollowIcon{
    [Follow_BackendManager currentUserFollowsChannel:self.currentChannel withCompletionBlock:^
        (bool isFollowing) {
         dispatch_async(dispatch_get_main_queue(), ^{
             self.isFollowingChannel = isFollowing;
             [self markFollowViewAsFollowing:isFollowing];
         });
     }];
}


-(void)addFollowChannelGestureToView:(UIView *) view{
    UITapGestureRecognizer * singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(followChannel)];
    singleTap.numberOfTapsRequired = 1;
    [view addGestureRecognizer:singleTap];
}

-(void) followChannel {
    if(self.isFollowingChannel){
        self.isFollowingChannel = NO;
        [self markFollowViewAsFollowing:NO];
        [Follow_BackendManager currentUserStopFollowingChannel:self.currentChannel];
    }else{
        self.isFollowingChannel = YES;
        [self markFollowViewAsFollowing:YES];
        [Follow_BackendManager currentUserFollowChannel:self.currentChannel];
    }
}

-(void)markFollowViewAsFollowing:(BOOL) isFollowing{
    if(isFollowing){
        [self setFollowImageIsFollowing:YES];
        self.channelNameLabelHolder.backgroundColor = [UIColor whiteColor];
        [self changeChannelNameToSelectedView:YES];
    }else{
        [self setFollowImageIsFollowing:NO];
        self.channelNameLabelHolder.backgroundColor = [UIColor clearColor];
        [self changeChannelNameToSelectedView:NO];
    }
    
    
}


-(void)addPresentChannelGestureToView:(UIView *) view{
    UITapGestureRecognizer * singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(presentChannel)];
    singleTap.numberOfTapsRequired = 1;
    [view addGestureRecognizer:singleTap];
}

-(void)presentChannel{
    [self.delegate channelSelected:self.currentChannel withOwner:self.channelOwner];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
