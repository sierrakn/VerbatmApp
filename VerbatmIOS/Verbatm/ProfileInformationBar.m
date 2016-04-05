//
//  profileInformationBar.m
//  Verbatm
//
//  Created by Iain Usiri on 12/23/15.
//  Copyright © 2015 Verbatm. All rights reserved.
//

#import "Icons.h"

#import "Follow_BackendManager.h"

#import "Notifications.h"

#import <Parse/PFUser.h>
#import "ParseBackendKeys.h"
#import "ProfileInformationBar.h"

#import "SizesAndPositions.h"
#import "Styles.h"


@interface ProfileInformationBar ()
@property (nonatomic) UILabel * userTitleName;
@property (nonatomic) UIButton * settingsButton;
@property (nonatomic) UIButton * followButton;
@property (nonatomic) BOOL isCurrentUser;
@property (nonatomic) BOOL hasBlockedUser;
@property (nonatomic) BOOL isFollowigProfileUser;//for cases when they are viewing another profile

@end

@implementation ProfileInformationBar

-(instancetype)initWithFrame:(CGRect)frame andUserName: (NSString *) userName isCurrentUser:(BOOL) isCurrentUser {
    
    self =  [super initWithFrame:frame];
    
    if(self){
        
        [self formatView];
        [self createProfileHeaderWithUserName:userName];
        self.isCurrentUser = isCurrentUser;
        if(isCurrentUser){
            [self createSettingsButton];
        }else{
            [self createBackButton];
            [self checkHasBlockedUser];
        }
        [self registerForNotifications];
    }
    return self;
}


-(void)registerForNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loginSucceeded:)
                                                 name:NOTIFICATION_USER_LOGIN_SUCCEEDED
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userNameChanged:)
                                                 name:NOTIFICATION_USERNAME_CHANGED_SUCCESFULLY
                                               object:nil];
}
-(void) userNameChanged: (NSNotification*) notification {
    [self updateUserName];
}
-(void) loginSucceeded: (NSNotification*) notification {
/*the user has logged in so we can update our username*/
    [self updateUserName];
}

-(void)updateUserName{
    [self.userTitleName removeFromSuperview];
    self.userTitleName = nil;
    [self createProfileHeaderWithUserName:[[PFUser currentUser] valueForKey:VERBATM_USER_NAME_KEY]];
}

-(void)formatView {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:1.f];
}

-(void) createProfileHeaderWithUserName: (NSString*) userName {
    CGFloat x_point = (CHANNEL_BUTTON_WALL_XOFFSET*2) + SETTINGS_BUTTON_SIZE;
    CGFloat width = self.frame.size.width - (CHANNEL_BUTTON_WALL_XOFFSET*2) - (SETTINGS_BUTTON_SIZE*2);
    CGFloat height = self.frame.size.height;
    CGFloat y_point = self.center.y - (height/2.f);
    
    self.userTitleName = [[UILabel alloc] initWithFrame:CGRectMake(x_point, y_point,
                                                                       width,height)];
    
    self.userTitleName.text = userName;
    self.userTitleName.textAlignment = NSTextAlignmentCenter;
    self.userTitleName.textColor = VERBATM_GOLD_COLOR;
    self.userTitleName.font = [UIFont fontWithName:HEADER_TEXT_FONT size:HEADER_TEXT_SIZE];
    [self addSubview: self.userTitleName ];
}

-(void)createSettingsButton {
    UIImage * settingsImage = [UIImage imageNamed:SETTINGS_BUTTON_ICON];

    CGFloat height = SETTINGS_BUTTON_SIZE;
    CGFloat width = height+ 20.f;
    CGFloat frame_x = self.frame.size.width - width - CHANNEL_BUTTON_WALL_XOFFSET;
    CGFloat frame_y = self.center.y - (height/2.f);
    
    CGRect iconFrame = CGRectMake(frame_x, frame_y, width, height );
    
    self.settingsButton =  [[UIButton alloc] initWithFrame:iconFrame];
    [self.settingsButton setImage:settingsImage forState:UIControlStateNormal];
    self.settingsButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.settingsButton addTarget:self action:@selector(settingsButtonSelected) forControlEvents:UIControlEventTouchDown];
    [self addSubview:self.settingsButton];
    self.settingsButton.clipsToBounds = YES;;

}


-(void)checkHasBlockedUser{
    
    /*
     Sierra TODO
        Querry database and check if the logged in user has blocked this users profile. 
        In completion block:
            Set --> self.checkHasBlockedUser == true or false
            then call --> [self createBlockingButton]; in main thread of course
     
     
     */
    
    
    [self createBlockingButton];
}


-(void)createBlockingButton {
    UIImage * settingsImage = [UIImage imageNamed:BLOCK_USER_ICON];
    
    CGFloat height = SETTINGS_BUTTON_SIZE;
    CGFloat width = height+ 20.f;
    CGFloat frame_x = self.frame.size.width - width - CHANNEL_BUTTON_WALL_XOFFSET;
    CGFloat frame_y = self.center.y - (height/2.f);
    
    CGRect iconFrame = CGRectMake(frame_x, frame_y, width, height );
    
    self.settingsButton =  [[UIButton alloc] initWithFrame:iconFrame];
    [self.settingsButton setImage:settingsImage forState:UIControlStateNormal];
    self.settingsButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.settingsButton addTarget:self action:@selector(blockButtonSelected) forControlEvents:UIControlEventTouchDown];
    [self addSubview:self.settingsButton];
    self.settingsButton.clipsToBounds = YES;;
    
}

-(void)blockButtonSelected {
    [self.delegate blockCurrentUserShouldBlock:!self.hasBlockedUser];
}

//If it's my profile it's follower(s) and if it's someone else's profile
//it's follow
-(void) createFollowButton_AreWeFollowingCurrChannel:(BOOL) areFollowing{
    if(self.followButton){
        [self.followButton removeFromSuperview];
        self.followButton = nil;
    }
    
    CGFloat height = SETTINGS_BUTTON_SIZE;
    CGFloat width = (height*436.f)/250.f;
    CGFloat frame_x = self.frame.size.width - width - CHANNEL_BUTTON_WALL_XOFFSET;
    CGFloat frame_y = self.center.y - (height/2.f);
    
    CGRect iconFrame = CGRectMake(frame_x, frame_y, width, height);
    
    UIImage * buttonImage = [UIImage imageNamed:((areFollowing) ? FOLLOWED_BY_ICON : FOLLOW_ICON_LIGHT)];
    self.isFollowigProfileUser = areFollowing;
    self.followButton = [[UIButton alloc] initWithFrame:iconFrame];
    [self.followButton setImage:buttonImage forState:UIControlStateNormal];
    [self.followButton addTarget:self action:@selector(followOrFollowersSelected) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.followButton];
}

-(void) createBackButton {
    
    UIImage * settingsImage = [UIImage imageNamed:BACK_BUTTON_ICON];
    CGFloat height = SETTINGS_BUTTON_SIZE;
    CGFloat width = height;
    CGFloat frame_x = CHANNEL_BUTTON_WALL_XOFFSET;
    CGFloat frame_y = self.center.y - (height/2.f);
    
    CGRect iconFrame = CGRectMake(frame_x, frame_y, width, height);
    
    self.settingsButton =  [[UIButton alloc] initWithFrame:iconFrame];
    [self.settingsButton setImage:settingsImage forState:UIControlStateNormal];
    self.settingsButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.settingsButton addTarget:self action:@selector(backButtonSelected) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.settingsButton];

}

-(void) backButtonSelected {
    [self.delegate backButtonSelected];
}

-(void) settingsButtonSelected {
    [self.delegate settingsButtonSelected];
}

-(void) followOrFollowersSelected {
    UIImage * newbuttonImage;
    if(self.isFollowigProfileUser){
        newbuttonImage  = [UIImage imageNamed:FOLLOW_ICON_LIGHT];
        self.isFollowigProfileUser = NO;
    } else {
        newbuttonImage = [UIImage imageNamed:FOLLOWED_BY_ICON];
        self.isFollowigProfileUser = YES;
    }
    [self.followButton setImage:newbuttonImage forState:UIControlStateNormal];
    [self.followButton setNeedsDisplay];
    [self.delegate followButtonSelectedShouldFollowUser: self.isFollowigProfileUser];
}

-(void)setFollowIconToFollowingCurrentChannel:(BOOL) isFollowingChannel{
    dispatch_async(dispatch_get_main_queue(), ^{
         if(!self.isCurrentUser)
             [self createFollowButton_AreWeFollowingCurrChannel:isFollowingChannel];
    });
}

@end
