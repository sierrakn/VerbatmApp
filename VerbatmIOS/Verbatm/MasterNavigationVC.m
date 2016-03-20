//
//  verbatmMasterNavigationViewController.m
//  Verbatm
//
//  Created by Iain Usiri on 5/20/15.
//  Copyright (c) 2015 Verbatm. All rights reserved.
//

#import <AVFoundation/AVAudioSession.h>

#import "ArticleDisplayVC.h"
#import "Analytics.h"

#import "CustomTabBarController.h"
#import "ContentDevVC.h"
#import "Channel.h"
#import "ChannelOrUsernameCV.h"

#import "Durations.h"

#import "FeedVC.h"

#import "GTLVerbatmAppVerbatmUser.h"

#import "Icons.h"
#import "InternetConnectionMonitor.h"

#import "MasterNavigationVC.h"
#import "MediaSessionManager.h"

#import "Notifications.h"

#import "POVPublisher.h"
#import "PreviewDisplayView.h"
#import "ProfileVC.h"
#import "PublishingProgressManager.h"

#import "StoryboardVCIdentifiers.h"
#import "SharePOVView.h"
#import "SegueIDs.h"
#import "SizesAndPositions.h"
#import "Styles.h"

#import <Parse/Parse.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>

#import "UIImage+ImageEffectsAndTransforms.h"
#import "UserSetupParameters.h"
#import "UserManager.h"
#import "UserPovInProgress.h"
#import "UserAndChannelListsTVC.h"


#import "VerbatmCameraView.h"

#import <Crashlytics/Crashlytics.h>


@interface MasterNavigationVC () <UITabBarControllerDelegate, FeedVCDelegate, ProfileVCDelegate, SharePOVViewDelegate, UserAndChannelListsTVCDelegate>

#pragma mark - Tab Bar Controller -
@property (weak, nonatomic) IBOutlet UIView *tabBarControllerContainerView;
@property (strong, nonatomic) CustomTabBarController* tabBarController;
@property (nonatomic) CGRect tabBarFrameOnScreen;
@property (nonatomic) CGRect tabBarFrameOffScreen;




#pragma mark View Controllers in tab bar Controller

@property (strong,nonatomic) ProfileVC* profileVC;
@property (strong,nonatomic) FeedVC * feedVC;


@property (nonatomic) UserAndChannelListsTVC * channelListView;

#define ANIMATION_NOTIFICATION_DURATION 0.5
#define TIME_UNTIL_ANIMATION_CLEAR 1.5



#define DARK_GRAY 0.6f
#define ADK_BUTTON_SIZE 40.f
#define SELECTED_TAB_ICON_COLOR [UIColor colorWithRed:0.5 green:0.1 blue:0.1 alpha:1.f]


@end

@implementation MasterNavigationVC

- (void)viewDidLoad {
	[super viewDidLoad];
    [self registerForNotifications];
    if ([PFUser currentUser].isAuthenticated) {
        [self setUpStartEnvironment];
    }
}

-(void)setUpStartEnvironment{
    [self setUpTabBarController];
     self.view.backgroundColor = [UIColor blackColor];
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if (![PFUser currentUser].isAuthenticated) {
		[self bringUpLogin];
	}
}

-(void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

-(void) registerForNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(loginFailed:)
												 name:NOTIFICATION_USER_LOGIN_FAILED
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(loginSucceeded:)
												 name:NOTIFICATION_USER_LOGIN_SUCCEEDED
											   object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userHasSignedOutNotification:)
                                                 name:NOTIFICATION_USER_SIGNED_OUT
                                               object:nil];
    
    
}

#pragma mark - User Manager Delegate -

-(void) loginSucceeded:(NSNotification*) notification {
	PFUser * user = notification.object;
	[[Crashlytics sharedInstance] setUserEmail: user.email];
	[[Crashlytics sharedInstance] setUserName: [user username]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setUpStartEnvironment];
    });
}

-(void) loginFailed:(NSNotification *) notification {
	NSError* error = (NSError*) notification.object;
	NSLog(@"Error finding current user: %@", error.description);
	//TODO: only do this if have a connection, or only a certain number of times
}

#pragma mark - Tab bar controller -

-(void) setUpTabBarController {
    [self createTabBarViewController];
    [self createViewControllers];
    
    UIViewController * deadView = [[UIViewController alloc] init];
    
    UIImage * deadViewTabImage = [self imageWithImage:[[UIImage imageNamed:ADK_NAV_ICON]
                                                       imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                        scaledToSize:CGSizeMake(40.f, 40.f)];
    
    deadView.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"" image:deadViewTabImage selectedImage:deadViewTabImage];
    deadView.tabBarItem.imageInsets = UIEdgeInsetsMake(5.f, 0.f, -5.f, 0.f);

    self.tabBarController.viewControllers = @[self.profileVC, deadView, self.feedVC, self.channelListView];
    //add adk button to tab bar
	[self addTabBarCenterButtonOverDeadView];
    self.tabBarController.selectedViewController = self.feedVC;
	[self formatTabBar];
}


- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


-(void) formatTabBar {
	NSInteger numTabs = self.tabBarController.viewControllers.count;
	CGSize tabBarItemSize = CGSizeMake(self.tabBarController.tabBar.frame.size.width/numTabs,
									   self.tabBarController.tabBarHeight);
	//[self.tabBarController.tabBar setTintColor:SELECTED_TAB_ICON_COLOR];
	// Sets background of unselected UITabBarItem
	[self.tabBarController.tabBar setBackgroundImage: [self getUnselectedTabBarItemImageWithSize: tabBarItemSize]];
	// Sets the background color of the selected UITabBarItem
	[self.tabBarController.tabBar setSelectionIndicatorImage: [self getSelectedTabBarItemImageWithSize: tabBarItemSize]];

	//set two tab bar frames-- for when we want to remove the tab bar
	self.tabBarFrameOnScreen = self.tabBarController.tabBar.frame;
	self.tabBarFrameOffScreen = CGRectMake(self.tabBarController.tabBar.frame.origin.x,
										   self.view.frame.size.height + ADK_BUTTON_SIZE/2.f,
										   self.tabBarController.tabBar.frame.size.width,
										   self.tabBarController.tabBarHeight);
}

-(UIImage*) getUnselectedTabBarItemImageWithSize: (CGSize) size {
	return [UIImage makeImageWithColorAndSize:[UIColor colorWithWhite:0.0 alpha:TAB_BAR_ALPHA]
									  andSize: size];
}

-(UIImage*) getSelectedTabBarItemImageWithSize: (CGSize) size {
	return [UIImage makeImageWithColorAndSize:[UIColor colorWithWhite:DARK_GRAY alpha:TAB_BAR_ALPHA]
									  andSize: size];
}

//the view controllers that will be tabbed
-(void)createViewControllers {
    
    self.channelListView = [[UserAndChannelListsTVC alloc] init];
    self.channelListView.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                                    image:[UIImage imageNamed:SEARCH_TAB_BAR_ICON]
                                                            selectedImage:[UIImage imageNamed:SEARCH_TAB_BAR_ICON]];
    
    
    [self.channelListView presentAllVerbatmChannels];
    
    self.channelListView.listDelegate = self;

    self.profileVC = [self.storyboard instantiateViewControllerWithIdentifier:PROFILE_VC_ID];
    
    self.profileVC.delegate = self;
    self.profileVC.userOfProfile = [PFUser currentUser];
    self.profileVC.isCurrentUserProfile = YES;
    self.feedVC = [self.storyboard instantiateViewControllerWithIdentifier:FEED_VC_ID];
    self.feedVC.delegate = self;

	self.profileVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@""
															  image:[UIImage imageNamed:PROFILE_NAV_ICON]
																	
													  selectedImage:[UIImage imageNamed:PROFILE_NAV_ICON]];
	self.feedVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@""
															  image:[UIImage imageNamed:HOME_NAV_ICON]
													  selectedImage:[UIImage imageNamed:HOME_NAV_ICON]];
    
    
    // images need to be centered this way for some reason
	self.profileVC.tabBarItem.imageInsets = UIEdgeInsetsMake(5.f, 0.f, -5.f, 0.f);
    self.channelListView.tabBarItem.imageInsets = UIEdgeInsetsMake(10.f, 0.f, -5.f, 0.f);
	self.feedVC.tabBarItem.imageInsets = UIEdgeInsetsMake(5.f, 0.f, -5.f, 0.f);
}

-(void)createTabBarViewController{
    self.tabBarControllerContainerView.frame = self.view.bounds;
    self.tabBarController = [self.storyboard instantiateViewControllerWithIdentifier: TAB_BAR_CONTROLLER_ID];
	self.tabBarController.tabBarHeight = TAB_BAR_HEIGHT;
    [self.tabBarControllerContainerView addSubview:self.tabBarController.view];
    [self addChildViewController:self.tabBarController];
    self.tabBarController.delegate = self;
}

// Create a custom UIButton and add it over our adk icon
-(void) addTabBarCenterButtonOverDeadView{

	NSInteger numTabs = self.tabBarController.viewControllers.count;
	CGFloat tabWidth = self.tabBarController.tabBar.frame.size.width/numTabs;
	// covers up tab so that it won't go to blank view controller
	// Center tab out of 3
	UIView* tabView = [[UIView alloc] initWithFrame:CGRectMake(tabWidth, 0.f, tabWidth,
															self.tabBarController.tabBarHeight)];
	[tabView setBackgroundColor:[UIColor clearColor]];

	UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.frame = tabView.frame;
	[button setBackgroundColor:[UIColor clearColor]];
	[button addTarget:self action:@selector(revealADK) forControlEvents:UIControlEventTouchUpInside];

	//[self.tabBarController.tabBar addSubview:tabView];
	[self.tabBarController.tabBar addSubview:button];
}

-(void) revealADK {
	[[Analytics getSharedInstance] newADKSession];
    [self playContentOnSelectedViewController:NO];
	[self performSegueWithIdentifier:ADK_SEGUE sender:self];
}


-(void)userHasSignedOutNotification:(NSNotification *) notification{
    [self bringUpLogin];
}



#pragma mark - Handle Login -

//brings up the create account page if there is no user logged in
-(void) bringUpLogin {
	//TODO: check user defaults and do login if they have logged in before
	[self performSegueWithIdentifier:SIGN_IN_SEGUE sender:self];
}

//catches the unwind segue from login / create account or adk
- (IBAction) unwindToMasterNavVC: (UIStoryboardSegue *)segue {
	if ([segue.identifier  isEqualToString: UNWIND_SEGUE_FROM_LOGIN_TO_MASTER]) {
		// TODO: have variable set and go to profile or adk
	} else if ([segue.identifier isEqualToString: UNWIND_SEGUE_FROM_ADK_TO_MASTER]) {
		if ([[PublishingProgressManager sharedInstance] currentlyPublishing]) {
			[self.tabBarController setSelectedViewController:self.profileVC];
			[self.profileVC showPublishingProgress];
		}
        [self playContentOnSelectedViewController:YES];
		[[Analytics getSharedInstance] endOfADKSession];
	}
}


-(void) playContentOnSelectedViewController:(BOOL) shoulPlay{
    
    if(shoulPlay){
        UIViewController * currentViewController = self.tabBarController.viewControllers[self.tabBarController.selectedIndex];
        
        if(currentViewController == self.feedVC){
        }else if (currentViewController == self.profileVC){
        }
    }else{
        UIViewController * currentViewController = self.tabBarController.viewControllers[self.tabBarController.selectedIndex];
        
        if(currentViewController == self.feedVC){
        }else if (currentViewController == self.profileVC){
        }
    }
}

#pragma mark - Media Dev VC Delegate methods -

// TODO: make this a notification and change this to the profile vc
-(void) povPublishedWithUserName:(NSString *)userName andTitle:(NSString *)title andProgressObject:(NSProgress *)progress {
//	[self.tabBarController setSelectedViewController:self.feedVC];
}

#pragma mark - Feed VC Delegate -

-(void) showTabBar:(BOOL)show {
	if (show) {
		[UIView animateWithDuration:TAB_BAR_TRANSITION_TIME animations:^{
			self.tabBarController.tabBar.frame = self.tabBarFrameOnScreen;
		}];
	} else {
		[UIView animateWithDuration:TAB_BAR_TRANSITION_TIME animations:^{
			self.tabBarController.tabBar.frame = self.tabBarFrameOffScreen;
		}];
	}
}

//show the list of followers of the current user
-(void)presentFollowersListMyID:(id) userID {
    UserAndChannelListsTVC * newList = [[UserAndChannelListsTVC alloc] init];
    [newList presentChannelsForUser:userID shouldDisplayFollowers:YES];
    newList.listDelegate = self;
    
    [self presentViewController:newList animated:YES completion:^{
        
    }];
    
}
//show list of people the user follows
-(void)presentWhoIFollowMyID:(id) userID {
    
    UserAndChannelListsTVC * newList = [[UserAndChannelListsTVC alloc] init];
    [newList presentWhoIsFollowedBy:userID];
    newList.listDelegate = self;
    
    [self presentViewController:newList animated:YES completion:^{
        
    }];
    
    
    
}

//show the channels the current user can select to follow
-(void)presentChannelsToFollow{
    //[self presentShareSelectionViewStartOnChannels:YES];
}

-(void)profilePovShareButtonSeletedForPOV:(PovInfo *) pov{
    //[self presentShareSelectionViewStartOnChannels:NO];
}

-(void)profilePovLikeLiked:(BOOL) liked forPOV:(PovInfo *) pov{
    
}




-(void)feedPovLikeLiked:(BOOL) liked forPOV:(PovInfo *) pov {
    
    
    
}








#pragma mark - Delegate for channel list view -
-(void)openChannel:(Channel *) channel {
    
}

-(void)selectedUser:(id)userId {
  
    
}

//either you specify a start channel or you send in nil which goes to default
-(void)presentUserProfileWithChannel:(Channel *) specificChannel{
    
    if(specificChannel){
        
    }else{
        
    }
    
    
    
}

#pragma mark - Memory Warning -

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
