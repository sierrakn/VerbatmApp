//
//  profileVC.m
//  Verbatm
//
//  Created by Iain Usiri on 8/29/15.
//  Copyright (c) 2015 Verbatm. All rights reserved.
//
#import "ArticleDisplayVC.h"

#import "Channel.h"
#import "CreateNewChannelView.h"

#import "Durations.h"

#import "GTLVerbatmAppVerbatmUser.h"

#import "LocalPOVs.h"

#import "POVScrollView.h"
#import "ProfileVC.h"
#import "ProfileNavBar.h"
#import "POVLoadManager.h"
#import "PostListVC.h"

#import "SharePOVView.h"
#import "SegueIDs.h"
#import "SizesAndPositions.h"
#import "SettingsVC.h"

#import "UIView+Effects.h"
#import "UserManager.h"

@interface ProfileVC() <ArticleDisplayVCDelegate, ProfileNavBarDelegate,UIScrollViewDelegate,CreateNewChannelViewProtocol, POVScrollViewDelegate, SharePOVViewDelegate>

@property (strong, nonatomic) PostListVC * postListVC;
@property (weak, nonatomic) IBOutlet UIView *postListContainer;

@property (nonatomic, strong) ProfileNavBar* profileNavBar;
@property (nonatomic) CGRect profileNavBarFrameOnScreen;
@property (nonatomic) CGRect profileNavBarFrameOffScreen;
@property (nonatomic) BOOL contentCoveringScreen;
@property (weak, nonatomic) GTLVerbatmAppVerbatmUser* currentUser;
@property (strong, nonatomic) ArticleDisplayVC * postDisplayVC;
@property (nonatomic, strong) NSString * currentThreadInView;

@property (strong, nonatomic) NSArray* channels;


@property (strong, nonatomic) CreateNewChannelView * createNewChannelView;
@property (nonatomic) UIView * darkScreenCover;
@property (nonatomic) SharePOVView * sharePOVView;

@end

@implementation ProfileVC

-(void) viewDidLoad {
	[super viewDidLoad];
	self.contentCoveringScreen = YES;
    
    //this is where you'd fetch the threads
    [self getChannelsWithCompletionBlock:^{
        [self createAndAddListVC];
        [self createNavigationBar];
        [self addClearScreenGesture];
    }];
    
}

//this is where downloading of channels should happen
-(void) getChannelsWithCompletionBlock:(void(^)())block{
    
    //simulates downloading threads
    Channel * enterpreneurship = [[Channel alloc] initWithChannelName:@"Entrepreneurship" numberOfFollowers:@(50) andUserName:@"Iain Usiri"];
    
    Channel * socialJustice = [[Channel alloc] initWithChannelName:@"Social Justice" numberOfFollowers:@(500) andUserName:@"Iain Usiri"];
    
    Channel * music = [[Channel alloc] initWithChannelName:@"Music" numberOfFollowers:@(10000) andUserName:@"Iain Usiri"];
    
    
    self.channels = @[enterpreneurship, socialJustice, music];
    block();//after downloading threads we call this block to build the profile
}



-(void) viewWillAppear:(BOOL)animated{
    NSString * channel = ((Channel *)self.channels[0]).name;
    //send information 

}

-(void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}


-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

-(void) createAndAddListVC{
    UICollectionViewFlowLayout * flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    [flowLayout setMinimumInteritemSpacing:0.3];
    [flowLayout setMinimumLineSpacing:0.0f];
    [flowLayout setItemSize:self.view.frame.size];
    self.postListVC = [[PostListVC alloc] initWithCollectionViewLayout:flowLayout];
    
    [self.postListContainer setFrame:self.view.bounds];
    [self.postListContainer addSubview:self.postListVC.view];
    [self.view addSubview:self.postListContainer];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{

}

-(void) createContentListViewWithStartThread:(NSString *)startThread{
    self.postDisplayVC = [self.storyboard instantiateViewControllerWithIdentifier:ARTICLE_DISPLAY_VC_ID];
    self.postDisplayVC.view.frame = self.view.bounds;
    self.postDisplayVC.view.backgroundColor = [UIColor blackColor];
    [self.postDisplayVC presentContentWithPOVType:POVTypeUser andChannel:startThread];
    
    self.currentThreadInView = startThread;
    
    [self addChildViewController:self.postDisplayVC];
    [self.view addSubview:self.postDisplayVC.view];
    [self.postDisplayVC didMoveToParentViewController:self];
    self.postDisplayVC.delegate = self;
}

-(void) createNavigationBar {
    //frame when on screen
    self.profileNavBarFrameOnScreen = CGRectMake(0.f, 0.f, self.view.frame.size.width, PROFILE_NAV_BAR_HEIGHT + ARROW_EXTENSION_BAR_HEIGHT);
    //frame when off screen
	self.profileNavBarFrameOffScreen = CGRectMake(0.f, - (PROFILE_NAV_BAR_HEIGHT+ ARROW_EXTENSION_BAR_HEIGHT), self.view.frame.size.width, PROFILE_NAV_BAR_HEIGHT + ARROW_EXTENSION_BAR_HEIGHT);
    [self updateUserInfo];
    self.profileNavBar = [[ProfileNavBar alloc] initWithFrame:self.profileNavBarFrameOnScreen
												   andChannels:self.channels andUserName:self.currentUser.name isCurrentLoggedInUser:self.isCurrentUserProfile];
    self.profileNavBar.delegate = self;
    [self.view addSubview:self.profileNavBar];
} 

-(void) updateUserInfo {
    self.currentUser = [[UserManager sharedInstance] getCurrentUser];
}

-(void)addClearScreenGesture{
    UITapGestureRecognizer * singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clearScreen:)];
    singleTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:singleTap];
}



#pragma mark -POV ScrollView custom delegate -

-(void) povLikeButtonLiked: (BOOL)liked onPOV: (PovInfo*) povInfo{
    //sierra TODO
    //code to register a like/dislike from the user
}

-(void) povshareButtonSelectedForPOVInfo:(PovInfo *) povInfo{
    [self presentShareSelectionViewStartOnChannels:NO];
    
}


#pragma mark - Profile Nav Bar Delegate Methods -

//current user selected to follow a channel
-(void) followOptionSelected{
    [self presentShareSelectionViewStartOnChannels:YES];
}


-(void)presentShareSelectionViewStartOnChannels:(BOOL) startOnChannels{
    if(self.sharePOVView){
        [self.sharePOVView removeFromSuperview];
        self.sharePOVView = nil;
    }
    
    
    //temp
    //simulates getting threads
    Channel * enterpreneurship = [[Channel alloc] initWithChannelName:@"Entrepreneurship" numberOfFollowers:@(50) andUserName:@"Iain Usiri"];
    
    Channel * socialJustice = [[Channel alloc] initWithChannelName:@"Social Justice" numberOfFollowers:@(500) andUserName:@"Iain Usiri"];
    
    Channel * music = [[Channel alloc] initWithChannelName:@"Music" numberOfFollowers:@(10000) andUserName:@"Iain Usiri"];
    
    
    CGRect onScreenFrame = CGRectMake(0.f, self.view.frame.size.height/2.f, self.view.frame.size.width, self.view.frame.size.height/2.f);
    CGRect offScreenFrame = CGRectMake(0.f, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height/2.f);
    self.sharePOVView = [[SharePOVView alloc] initWithFrame:offScreenFrame andChannels:@[enterpreneurship, socialJustice, music] shouldStartOnChannels:startOnChannels];
    self.sharePOVView.delegate = self;
    [self.view addSubview:self.sharePOVView];
    [self.view bringSubviewToFront:self.sharePOVView];
    [UIView animateWithDuration:TAB_BAR_TRANSITION_TIME animations:^{
        self.sharePOVView.frame = onScreenFrame;
    }];
}

-(void)removeSharePOVView{
    if(self.sharePOVView){
        CGRect offScreenFrame = CGRectMake(0.f, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height/2.f);
        
        [UIView animateWithDuration:TAB_BAR_TRANSITION_TIME animations:^{
            self.sharePOVView.frame = offScreenFrame;
        }completion:^(BOOL finished) {
            if(finished){
                [self.sharePOVView removeFromSuperview];
                self.sharePOVView = nil;
            }
        }];
    }
}

//current user wants to see their own followers
-(void) followersOptionSelected{
    [self.delegate presentFollowersListMyID:nil];//to-do
}

//current user wants to see who they follow
-(void) followingOptionSelected {
    [self.delegate presentWhoIFollowMyID:nil];//to-do
}

-(void) settingsButtonClicked {
    [self performSegueWithIdentifier:SETTINGS_PAGE_MODAL_SEGUE sender:self];
    
}

//ProfileNavBarDelegate protocol
-(void) createNewChannel{
    if(!self.createNewChannelView){
        [self darkenScreen];
        CGFloat viewHeight = self.view.frame.size.height/2.f -
        (CHANNEL_CREATION_VIEW_WALLOFFSET_X *7);
        
        CGRect newChannelViewFrame = CGRectMake(CHANNEL_CREATION_VIEW_WALLOFFSET_X, CHANNEL_CREATION_VIEW_Y_OFFSET, self.view.frame.size.width - (CHANNEL_CREATION_VIEW_WALLOFFSET_X *2),viewHeight);
        self.createNewChannelView = [[CreateNewChannelView alloc] initWithFrame:newChannelViewFrame];
        self.createNewChannelView.delegate = self;
        [self.view addSubview:self.createNewChannelView];
        [self.view bringSubviewToFront:self.createNewChannelView];
    }

}

-(void)darkenScreen{
    if(!self.darkScreenCover){
        self.darkScreenCover = [[UIView alloc] initWithFrame:self.view.bounds];
        self.darkScreenCover.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.5];
        [self.view addSubview:self.darkScreenCover];
    }
}
-(void)removeScreenDarkener{
    if(self.darkScreenCover){
        [self.darkScreenCover removeFromSuperview];
        self.darkScreenCover = nil;
    }
}
-(void) cancelCreation {
    [self clearChannelCreationView];
}
-(void) createChannelWithName:(NSString *) channelName {
    //save the channel name and create it in the backend
    //upate the scrollview to present a new channel
    
    [self clearChannelCreationView];
}

-(void)clearChannelCreationView{
    if(self.createNewChannelView){
        [self removeScreenDarkener];
        [self.createNewChannelView removeFromSuperview];
        self.createNewChannelView = nil;
    }
}


#pragma mark -Share Seletion View Protocol -
-(void)cancelButtonSelected{
    [self removeSharePOVView];
}

-(void)sharePostWithComment:(NSString *) comment{
    //todo--sierra
    //code to share post to facebook etc
    
    [self removeSharePOVView];
    
}



#pragma mark -Navigate profile-
//the current user has selected the back button
-(void)exitCurrentProfile {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
    }];
}


-(void)newChannelSelectedWithName:(NSString *) channelName{
    if(![channelName isEqualToString:self.currentThreadInView]){
        //TODO -- get content from new channel and present it
        //sierra
    }
}



-(void) switchStoryListToThread:(NSString *) newChannel{
    [self.postDisplayVC cleanUp];
    [self.postDisplayVC presentContentWithPOVType:POVTypeUser andChannel:newChannel];
}

-(void)clearScreen:(UIGestureRecognizer *) tapGesture {
	if(self.contentCoveringScreen) {
		[UIView animateWithDuration:TAB_BAR_TRANSITION_TIME animations:^{
            [self.profileNavBar setFrame:[self getProfileNavBarFrameOffScreen:YES]];
		}];
		[self.delegate showTabBar:NO];
		self.contentCoveringScreen = NO;
        //[self.povScrollView headerShowing:NO];
	} else {
		[UIView animateWithDuration:TAB_BAR_TRANSITION_TIME animations:^{
			[self.profileNavBar setFrame:[self getProfileNavBarFrameOffScreen:NO]];
		}];
		[self.delegate showTabBar:YES];
		self.contentCoveringScreen = YES;
        //[self.povScrollView headerShowing:YES];

	}
}


-(CGRect)getProfileNavBarFrameOffScreen:(BOOL) getOffScreenFrame{
    
    if(getOffScreenFrame){
        return CGRectMake(0, -1 * self.profileNavBar.frame.size.height,
                          self.profileNavBar.frame.size.width,
                          self.profileNavBar.frame.size.height);
    }else{
        return CGRectMake(0, 0,
                          self.profileNavBar.frame.size.width,
                          self.profileNavBar.frame.size.height);
    }
}

-(void) offScreen{
    [self.postDisplayVC offScreen];
}
-(void)onScreen{
    [self.postDisplayVC onScreen];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:SETTINGS_PAGE_MODAL_SEGUE]){
        // Get reference to the destination view controller
        SettingsVC * vc = [segue destinationViewController];
        
        //set the username of the currently logged in user
        vc.userName  = @"Aishwarya Vardhana";
    }
}




#pragma mark - Article Display Delegate methods -

-(void) userLiked:(BOOL)liked POV:(PovInfo *)povInfo {
	// do nothing
}

@end
