//
//  feedDisplayTVC.m
//  Verbatm
//
//  Created by Iain Usiri on 8/28/15.
//  Copyright (c) 2015 Verbatm. All rights reserved.
//

#import "ArticleDisplayVC.h"
#import "ArticleListVC.h"
#import "HomeNavPullBar.h"
#import "Icons.h"
#import "FeedVC.h"
#import "POVLoadManager.h"
#import "SwitchCategoryPullView.h"
#import "SizesAndPositions.h"
#import "Styles.h"
#import "TopicsFeedVC.h"
#import "Durations.h"

@interface FeedVC ()<SwitchCategoryDelegate, HomeNavPullBarDelegate, ArticleListVCDelegate>

@property (strong, nonatomic) SwitchCategoryPullView *categorySwitch;
@property (strong, nonatomic) HomeNavPullBar* navPullBar;

#pragma mark - Child View Controllers -

// There are two article list views faded between by the category switcher at the top
@property (weak, nonatomic) IBOutlet UIView *topListContainer;
@property (weak, nonatomic) IBOutlet UIView *bottomListContainer;

// VC that displays articles in scroll view when clicked
@property (weak, nonatomic) IBOutlet UIView *articleDisplayContainer;
// article display list slides in from right and can be pulled off when a screen edge pan
@property (nonatomic) CGRect articleDisplayContainerFrameOffScreen;

@property (strong,nonatomic) ArticleListVC* trendingVC;
@property (strong,nonatomic) ArticleListVC* mostRecentVC;
// NOT IN USE NOW
//@property (strong,nonatomic) TopicsFeedVC* topicsVC;
@property (strong, nonatomic) ArticleDisplayVC* articleDisplayVC;

#define ID_FOR_TOPICS_VC @"topics_feed_vc"
#define ID_FOR_RECENT_VC @"most_recent_vc"
#define ID_FOR_TRENDING_VC @"trending_vc"

#define ID_FOR_DISPLAY_VC @"article_display_vc"

@end


@implementation FeedVC

-(void)viewDidLoad {
	[super viewDidLoad];
	[self.view setBackgroundColor:[UIColor colorWithRed:FEED_BACKGROUND_COLOR green:FEED_BACKGROUND_COLOR blue:FEED_BACKGROUND_COLOR alpha:1.f]];

	[self positionContainerViews];
	[self getAndFormatVCs];

	[self setUpNavPullBar];
	[self setUpCategorySwitcher];
}

-(void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

-(void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

#pragma mark - Getting and formatting child view controllers -


//position the container views in appropriate places and set frames
-(void) positionContainerViews {
	float listContainerY = CATEGORY_SWITCH_HEIGHT + CATEGORY_SWITCH_OFFSET*2;
	self.topListContainer.frame = CGRectMake(0, listContainerY,
											 self.view.frame.size.width,
											 self.view.frame.size.height - listContainerY);
	self.bottomListContainer.frame = self.topListContainer.frame;
	self.bottomListContainer.alpha = 0;

	self.articleDisplayContainerFrameOffScreen = CGRectMake(self.view.frame.size.width, 0,
															self.view.frame.size.width,
															self.view.frame.size.height);
	self.articleDisplayContainer.frame = self.articleDisplayContainerFrameOffScreen;
}

//lays out all the containers in the right position and also sets the appropriate
//offset for the master SV
-(void) getAndFormatVCs {
	self.trendingVC = [self.storyboard instantiateViewControllerWithIdentifier:ID_FOR_TRENDING_VC];
	[self.trendingVC setPovLoadManager: [[POVLoadManager alloc] initWithType: POVTypeTrending]];
	self.trendingVC.delegate = self;

	self.mostRecentVC = [self.storyboard instantiateViewControllerWithIdentifier:ID_FOR_RECENT_VC];
	[self.mostRecentVC setPovLoadManager: [[POVLoadManager alloc] initWithType: POVTypeRecent]];
	self.mostRecentVC.delegate = self;

	// NOT IN USE RIGHT NOW
//	self.topicsVC = [self.storyboard instantiateViewControllerWithIdentifier:ID_FOR_TOPICS_VC];

	[self.topListContainer addSubview: self.trendingVC.view];
	[self.bottomListContainer addSubview: self.mostRecentVC.view];

	self.articleDisplayVC = [self.storyboard instantiateViewControllerWithIdentifier:ID_FOR_DISPLAY_VC];
	[self.articleDisplayContainer addSubview: self.articleDisplayVC.view];
	self.articleDisplayContainer.alpha = 0;
}

#pragma mark - Formatting sub views -

-(void) setUpNavPullBar {

	CGRect navPullBarFrame = CGRectMake(self.view.frame.origin.x,
										self.view.frame.size.height - NAV_BAR_HEIGHT,
										self.view.frame.size.width, NAV_BAR_HEIGHT);
	self.navPullBar = [[HomeNavPullBar alloc] initWithFrame:navPullBarFrame];
	self.navPullBar.delegate = self;
	[self.view addSubview: self.navPullBar];
}

-(void) setUpCategorySwitcher {

	float categorySwitchWidth = self.view.frame.size.width;
	CGRect categorySwitchFrame = CGRectMake((self.view.frame.size.width - categorySwitchWidth)/2.f,
											CATEGORY_SWITCH_OFFSET, categorySwitchWidth, CATEGORY_SWITCH_HEIGHT);
	self.categorySwitch = [[SwitchCategoryPullView alloc] initWithFrame:categorySwitchFrame andBackgroundColor: self.view.backgroundColor];
	self.categorySwitch.categorySwitchDelegate = self;
	[self.view addSubview:self.categorySwitch];
}

-(void) profileButtonPressed {
	[self.delegate profileButtonPressed];
}

-(void) adkButtonPressed {
	[self.delegate adkButtonPressed];
}


#pragma mark - Switch Category Pull View delegate methods -

// pull circle was panned ratio of the total distance
-(void) pullCircleDidPan: (CGFloat)ratio {
    self.topListContainer.alpha = ratio;
    self.bottomListContainer.alpha = 1 - ratio;
}

// pull circle was released and snapped to one edge or the other
-(void) snapped: (BOOL)snappedLeft {

	[UIView animateWithDuration:SNAP_ANIMATION_DURATION animations: ^ {
		if (snappedLeft) {
			self.topListContainer.alpha = 0;
			self.bottomListContainer.alpha = 1;
		} else {
			self.topListContainer.alpha = 1;
			self.bottomListContainer.alpha = 0;
		}
	}];
}

#pragma mark - Show recently published POV -

-(void) showPOVPublishingWithTitle: (NSString*) title andCoverPic: (UIImage*) coverPic {
	[self.categorySwitch snapToEdgeLeft:YES];
	[self.mostRecentVC showPOVPublishingWithTitle: (NSString*) title andCoverPic: (UIImage*) coverPic];
}

#pragma mark - Article List VC Delegate Methods (display articles) -

-(void) displayPOVWithIndex:(NSInteger)index fromLoadManager:(POVLoadManager *)loadManager {
	[self.articleDisplayVC loadStory:index fromLoadManager:loadManager];
	[self.articleDisplayContainer setFrame:self.view.bounds];
	[self.articleDisplayContainer setBackgroundColor:[UIColor whiteColor]];
	self.articleDisplayContainer.alpha = 1;
	[self.view bringSubviewToFront: self.articleDisplayContainer];
}


@end
