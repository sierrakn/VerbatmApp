//
//  ProfileVC.h
//  Verbatm
//
//  Created by Iain Usiri on 8/29/15.
//  Copyright (c) 2015 Verbatm. All rights reserved.
//
//	View controller for the profile - responsible for laying out the channels, the post list
// 	showing posts for whichever channel is currently selected, and the profile navigation bar,
//	as well as the settings screen.

#import <UIKit/UIKit.h>
#import <Parse/PFUser.h>
#import "Channel.h"

@class VerbatmNavigationController;
@class MasterNavigationVC;

@protocol ProfileVCDelegate <NSObject>

@optional
//
//-(void) showTabBar:(BOOL)show;
//-(void) showNavBar:(BOOL)show;
//-(void) pushViewController: (UIViewController*)viewController;
-(void) userCreateFirstPost;

@end

@interface ProfileVC : UIViewController

@property (nonatomic) BOOL profileInFeed;

@property (weak, nonatomic) id<ProfileVCDelegate> delegate;

// Only used in feed list
@property (nonatomic) VerbatmNavigationController *verbatmNavigationController;
@property (nonatomic) MasterNavigationVC *verbatmTabBarController;

@property (weak, nonatomic) PFUser* ownerOfProfile;
@property (nonatomic) Channel* channel; 

//todo: get rid of these properties
//let us know if this is the profile of the logged in user
@property (nonatomic) BOOL isCurrentUserProfile;

// This is the profile tab
@property (nonatomic) BOOL isProfileTab;

@property (nonatomic) id userIdToPresent;

-(void) clearOurViews;

//instructs the Profile to begin loading postlist content
-(void) loadContentToPostList;

//to be used sparingly
-(void) refreshProfile;
//notifies the profile that it's on the screen for the feed
//and that it should update the cursor
-(void)updateDateOfLastPostSeen;

@end
