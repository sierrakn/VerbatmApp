//
//  ProfileHeaderView.h
//  Verbatm
//
//  Created by Sierra Kaplan-Nelson on 8/29/16.
//  Copyright © 2016 Verbatm. All rights reserved.
//
//	This shows the header on the profile - username and cover photo.

#import <UIKit/UIKit.h>

@protocol ProfileHeaderViewDelegate <NSObject>

-(void) moreInfoButtonTapped;

@end

@interface ProfileHeaderView : UIView

@property (nonatomic, weak) id<ProfileHeaderViewDelegate> delegate;

-(instancetype) initWithFrame:(CGRect)frame andChannel: (Channel*) channel;

@end
