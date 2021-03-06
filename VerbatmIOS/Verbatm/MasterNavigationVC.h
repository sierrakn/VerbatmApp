//  Created by Iain Usiri on 5/20/15.
//  Copyright (c) 2015 Verbatm. All rights reserved.
/*
    Handles the entire navigation of the app. It has a scrollview upon which all our major views are laid using
 containers. The Masternav then manages their interaction as well as which view is visible on the screen at any one time.
 */

#import <UIKit/UIKit.h>

@interface MasterNavigationVC : UITabBarController

@property (nonatomic) CGFloat tabBarHeight;

-(void) showTabBar:(BOOL)show;

@end
