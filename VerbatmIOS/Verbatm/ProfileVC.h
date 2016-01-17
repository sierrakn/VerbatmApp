//
//  profileVC.h
//  Verbatm
//
//  Created by Iain Usiri on 8/29/15.
//  Copyright (c) 2015 Verbatm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PovInfo.h"
@protocol ProfileVCDelegate <NSObject>

-(void) showTabBar: (BOOL) show;
-(void) createNewChannel;//tells delegate to present "create new channel" view

-(void)profilePovShareButtonSeletedForPOV:(PovInfo *) pov;
-(void)profilePovLikeLiked:(BOOL) liked forPOV:(PovInfo *) pov;


-(void)presentFollowersList;//show the list of followers of the current user
-(void)presentChannelsToFollow;//show the channels the current user can select
@end

@interface ProfileVC : UIViewController

@property (strong, nonatomic) id<ProfileVCDelegate> delegate;

-(void) updateUserInfo;
-(void) offScreen;//told when it's off screen to stop videos
-(void)onScreen;
@end
