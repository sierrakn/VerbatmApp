//
//  verbatmArticleDisplayCV.m
//  Verbatm
//
//  Created by Iain Usiri on 6/17/15.
//  Copyright (c) 2015 Verbatm. All rights reserved.
//

#import "ArticleDisplayVC.h"
#import "TextAVE.h"
#import "VideoAVE.h"
#import "PhotoVideoAVE.h"
#import "MultiplePhotoVideoAVE.h"
#import "Analyzer.h"
#import "Page.h"
#import "Article.h"
#import "PhotoVideoTextAVE.h"

@interface ArticleDisplayVC () <UIScrollViewDelegate>
@property (nonatomic, strong) NSMutableArray * Objects;//either pinchObjects or Pages
@property (strong, nonatomic) NSMutableArray* poppedOffPages;
@property (strong, nonatomic) UIView* animatingView;
@property (strong, nonatomic) UIScrollView* scrollView;
@property (nonatomic) CGPoint lastPoint;
@property (atomic, strong) UIActivityIndicatorView *activityIndicator;
//The first object in the list will be the last to be shown in the Article
@property (strong, nonatomic) NSMutableArray* pinchedObjects;
@property (weak, nonatomic) IBOutlet UIButton *exitArticle_Button;
@property (strong, nonatomic) UIButton* publishButton;
@property (nonatomic) CGPoint prev_Gesture_Point;//saves the prev point for the exit (pan) gesture
#define BEST_ALPHA_FOR_TEXT 0.8
#define ANIMATION_DURATION 0.4
#define NOTIFICATION_EXIT_ARTICLE_DISPLAY @"Notification_exitArticleDisplay"
#define EXIT_EPSILON 60 //the amount of space that must be pulled to exit
#define SV_RESTING_FRAME CGRectMake(self.view.frame.size.width, 0,  self.view.frame.size.width, self.view.frame.size.height);
#define NOTIFICATION_SHOW_ARTICLE @"notification_showArticle"
#define ANIMATION_NOTIFICATION_DURATION 0.4

#define NOTIFICATION_PAUSE_VIDEOS @"pauseContentPageVideosNotification"
#define NOTIFICATION_PLAY_VIDEOS @"playContentPageVideosNotification"

#define PUBLISH_BUTTON_IMAGE @"publish_button"
#define PUBLISH_BUTTON_XOFFSET 20.f
#define PUBLISH_BUTTON_YOFFSET 20.f
#define PUBLISH_BUTTON_WIDTH 50.f
#define PUBLISH_BUTTON_HEIGHT 50.f

@end


@implementation ArticleDisplayVC
@synthesize poppedOffPages = _poppedOffPages;
@synthesize animatingView = _animatingView;
@synthesize lastPoint = _latestPoint;



- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showArticle:) name:NOTIFICATION_SHOW_ARTICLE object: nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


//tells the content page to pause its videos when it's out of view
-(void)pause_CP_Vidoes
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_PAUSE_VIDEOS
                                                        object:nil
                                                      userInfo:nil];
}

//tells the content page to play it's videos when it's in view
-(void)play_CP_Vidoes
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_PLAY_VIDEOS
                                                        object:nil
                                                      userInfo:nil];
}

-(void)startActivityIndicator
{
    //add animation indicator here
    //Create and add the Activity Indicator to splashView
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.alpha = 1.0;
    self.activityIndicator.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    self.activityIndicator.hidesWhenStopped = YES;
    [self.scrollView addSubview:self.activityIndicator];
    [self.activityIndicator startAnimating];
}

-(void)stopActivityIndicator
{
    [self.activityIndicator stopAnimating];
}

//called when we want to present an article. article should be set with our content
-(void)showArticle:(NSNotification *) notification
{
    Article* article = [[notification userInfo] objectForKey:@"article"];
    NSMutableArray* pinchObjects = [[notification userInfo] objectForKey:@"pinchObjects"];
    if(article)
    {
		[self showArticleFromParse: article];
    }else{
		[self showArticlePreview: pinchObjects];
    }
}

-(void) showArticleFromParse:(Article *) article {
	[self setUpScrollView];
	[self show_remove_ScrollView:YES];
	[self startActivityIndicator];


	dispatch_queue_t articleDownload_queue = dispatch_queue_create("articleDisplay", NULL);
	dispatch_async(articleDownload_queue, ^{
		NSArray * pages = [article getAllPages];
		if(!pages.count)//if we have nothing in our article then return to the list view- we shouldn't need this because all downloaded articles should have legit pages
		{
			NSLog(@"No pages in article");
			[self show_remove_ScrollView:NO];
			return;
		}

		//we sort the pages by their page numbers to make sure everything is in the right order
		//O(nlogn) so should be fine in the long-run ;D
		pages = [pages sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			Page * page1 = obj1;
			Page * page2 = obj2;
			if(page1.pagePosition < page2.pagePosition)return -1;
			if(page2.pagePosition > page1.pagePosition) return 1;
			return 0;
		}];
		[self pause_CP_Vidoes];//make sure content page videos are paused so there is no video conflict
		dispatch_async(dispatch_get_main_queue(), ^{
			NSMutableArray * pinchObjectsArray = [[NSMutableArray alloc]init];
			//get pinch views for our array
			for (Page * page in pages)
			{
				//here the radius and the center dont matter because this is just a way to wrap our data for the analyser
				PinchView * pv = [page getPinchObjectWithRadius:0 andCenter:CGPointMake(0, 0)];
				[pinchObjectsArray addObject:pv];
			}
			Analyzer * analyser = [[Analyzer alloc]init];
			self.pinchedObjects = [analyser processPinchedObjectsFromArray:pinchObjectsArray withFrame:self.view.frame];

			if(!self.pinchedObjects.count)return;//for now
												 //stop animation indicator
			[self stopActivityIndicator];
			[self renderPinchPages];
			self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, [self.pinchedObjects count]*self.view.frame.size.height); //adjust contentsize to fit
			_latestPoint = CGPointZero;
			_animatingView = nil;
		});
	});
}

// When preview button clicked
-(void) showArticlePreview:  (NSMutableArray*) pinchObjects {
	[self pause_CP_Vidoes];//make sure content page videos are paused so there is no video conflict
	Analyzer * analyser = [[Analyzer alloc]init];
	self.pinchedObjects = [analyser processPinchedObjectsFromArray:pinchObjects withFrame:self.view.frame];
	self.view.backgroundColor = [UIColor clearColor];
	[self setUpScrollView];
	[self renderPinchPages];
	[self show_remove_ScrollView:YES];
	[self addPublishButton];
	_latestPoint = CGPointZero;
	_animatingView = nil;
}

-(void) addPublishButton {
	self.publishButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.publishButton setImage:[UIImage imageNamed:PUBLISH_BUTTON_IMAGE] forState:UIControlStateNormal];
	[self.publishButton setFrame:CGRectMake(self.view.frame.size.width - PUBLISH_BUTTON_XOFFSET - PUBLISH_BUTTON_WIDTH, PUBLISH_BUTTON_YOFFSET, PUBLISH_BUTTON_WIDTH, PUBLISH_BUTTON_HEIGHT)];
	[self.publishButton addTarget:self action:@selector(publishArticle:) forControlEvents:UIControlEventTouchUpInside];

	[self.view addSubview:self.publishButton];
}

-(void) publishArticle: (id)sender {

}

-(void) clearArticle
{
    //We clear these so that the media is released
    
    for(UIView *view in self.scrollView.subviews)
    {
        [view removeFromSuperview];
    }
    self.scrollView = NULL;
    self.animatingView = NULL;
    self.poppedOffPages = NULL;
    self.pinchedObjects = Nil;//sanitize array so memory is cleared
}


-(void)setUpScrollView
{
    if(self.scrollView)
    {
        //this means that we have already used this scrollview to present another article
        //so we want to clear it and then exit
        for(UIView * page in self.scrollView.subviews) [page removeFromSuperview];
    }else{
        self.scrollView = [[UIScrollView alloc] init];
        self.scrollView.frame = SV_RESTING_FRAME;
        [self.view addSubview: self.scrollView];
        self.scrollView.pagingEnabled  = YES;
        [self.scrollView setShowsVerticalScrollIndicator:NO];
        [self.scrollView setShowsHorizontalScrollIndicator:NO];
        self.scrollView.bounces = NO;
        self.scrollView.backgroundColor = [UIColor whiteColor];
        [self addShadowToView:self.scrollView];
    }
    
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, [self.pinchedObjects count]*self.view.frame.size.height);
    self.scrollView.delegate = self;
}

-(void)show_remove_ScrollView: (BOOL) show
{
    if(show)//present the scrollview
    {
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            [self pause_CP_Vidoes];
             self.articleCurrentlyViewing= YES;
             self.scrollView.frame = self.view.bounds;
        }];
    }else//send the scrollview back to the right
    {
		[self.publishButton removeFromSuperview];
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            [self play_CP_Vidoes];
            self.scrollView.frame = SV_RESTING_FRAME;
        }completion:^(BOOL finished) {
            if(finished)
            {
                self.articleCurrentlyViewing = NO;
                [self clearArticle];
            }
        }];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - setting the array of pinch objects
-(void)setPinchedObjects:(NSMutableArray *)pinchedObjects
{
    _pinchedObjects = pinchedObjects;
}


#pragma mark - render pinchPages -
//takes AVE pages and displays them on our scrollview
-(void)renderPinchPages
{
    CGRect viewFrame = self.view.bounds;
    
    for(UIView* view in self.pinchedObjects){
        if([view isKindOfClass:[TextAVE class]]){
            view.frame = viewFrame;
            [self.scrollView addSubview: view];
            viewFrame = CGRectOffset(viewFrame, 0, self.view.frame.size.height);
            continue;
        }
        [self.scrollView insertSubview:view atIndex:0];
        view.frame = viewFrame;
        viewFrame = CGRectOffset(viewFrame, 0, self.view.frame.size.height);
    }
    
    
    //This makes sure that if the first object is a video it is playing the sound
    [self everythingOffScreen];
    [self handlePlayBack];
    [self setUpGestureRecognizers];
}


#pragma mark - sorting out the ui for pinch object -


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    //We clear these so that the media is released
//    self.scrollView = NULL;
//    self.animatingView = NULL;
//    self.poppedOffPages = NULL;
//}



#pragma mark - Gesture recognizers -
//
////Sets up the gesture recognizer for dragging from the edges.
-(void)setUpGestureRecognizers
{
    UIScreenEdgePanGestureRecognizer* edgePanL = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(exitDisplay:)];
    edgePanL.edges =  UIRectEdgeLeft;
    [self.scrollView addGestureRecognizer: edgePanL];
}



//to be called when an aritcle is first rendered to unsure all videos are off
-(void)everythingOffScreen
{    
    for (int i=0; i< self.pinchedObjects.count; i++)
    {
        if(self.pinchedObjects[i] == self.animatingView)continue;
        
        if([self.pinchedObjects[i] isKindOfClass:[VideoAVE class]]){
            [((VideoAVE*)self.pinchedObjects[i]) offScreen];
        }else if([self.pinchedObjects[i] isKindOfClass:[PhotoVideoAVE class]]){
            [((PhotoVideoAVE *)self.pinchedObjects[i]) offScreen];
        }else if([self.pinchedObjects[i] isKindOfClass:[MultiplePhotoVideoAVE class]]){
            [((MultiplePhotoVideoAVE*)self.pinchedObjects[i]) offScreen];
        }else if([self.pinchedObjects[i] isKindOfClass:[PhotoVideoTextAVE class]]){
            [((PhotoVideoTextAVE *)self.animatingView) offScreen];
        }
    }
}


-(void)handlePlayBack//plays sound if first video is
{
    if(_animatingView)
    {
        [self stopPlayBack];
    }else {
        _animatingView = [self.pinchedObjects firstObject];
        
        [self stopPlayBack];
    }
    int index = (self.scrollView.contentOffset.y/self.view.frame.size.height);
    _animatingView = [self.pinchedObjects objectAtIndex:index];
    [self runPlayBack];
}

/*
 call this after changing the animating view to the current view
 */
-(void)runPlayBack
{
    if([self.animatingView isKindOfClass:[VideoAVE class]])
    {
        [((VideoAVE*)self.animatingView) onScreen];
    }else if([self.animatingView isKindOfClass:[PhotoVideoAVE class]])
    {
        [((PhotoVideoAVE *)self.animatingView) onScreen];
    }else if([self.animatingView isKindOfClass:[MultiplePhotoVideoAVE class]])
    {
        [((MultiplePhotoVideoAVE*)self.animatingView) onScreen];
    }else if([self.animatingView isKindOfClass:[PhotoVideoTextAVE class]])
    {
        [((PhotoVideoTextAVE *)self.animatingView) onScreen];
    }
}

/*call this before changing the nimating view so that we stop the previous thing
 */
-(void)stopPlayBack
{
    if([self.animatingView isKindOfClass:[VideoAVE class]]){
        [((VideoAVE*)self.animatingView) offScreen];
    }else if([self.animatingView isKindOfClass:[PhotoVideoAVE class]]){
        [((PhotoVideoAVE *)self.animatingView) offScreen];
    }else if([self.animatingView isKindOfClass:[MultiplePhotoVideoAVE class]]){
        [((MultiplePhotoVideoAVE*)self.animatingView) offScreen];
    }else if([self.animatingView isKindOfClass:[PhotoVideoTextAVE class]]){
        [((PhotoVideoTextAVE *)self.animatingView) offScreen];
    }
}

- (void)exitDisplay:(UIScreenEdgePanGestureRecognizer *)sender
{
    
    if([sender numberOfTouches] >1) return;//we want only one finger doing anything when exiting
    if(sender.state ==UIGestureRecognizerStateBegan)
    {
        self.prev_Gesture_Point  = [sender locationOfTouch:0 inView:self.view];
    }
    
    if(sender.state == UIGestureRecognizerStateChanged)
    {
        
        CGPoint current_point= [sender locationOfTouch:0 inView:self.view];;
        
        int diff = current_point.x - self.prev_Gesture_Point.x;
        self.prev_Gesture_Point = current_point;
        self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x +diff, self.scrollView.frame.origin.y,  self.scrollView.frame.size.width,  self.scrollView.frame.size.height);
    }
    
    if(sender.state == UIGestureRecognizerStateEnded)
    {
        if(self.scrollView.frame.origin.x > EXIT_EPSILON)
        {
            //exit article
            [self show_remove_ScrollView:NO];
        }else{
            //return view to original position
            [self show_remove_ScrollView:YES];
        }
    }
    
    
}

//Adds a shadow to whatever view is sent
//Iain
-(void) addShadowToView: (UIView *) view
{
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:view.bounds];
    view.layer.masksToBounds = NO;
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOffset = CGSizeMake(3.0f, 0.3f);
    view.layer.shadowOpacity = 0.8f;
    view.layer.shadowPath = shadowPath.CGPath;
}


#pragma mark - scrolling -

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
}
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self handlePlayBack];
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
}

@end