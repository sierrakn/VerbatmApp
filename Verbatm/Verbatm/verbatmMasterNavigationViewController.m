//
//  verbatmMasterNavigationViewController.m
//  Verbatm
//
//  Created by Iain Usiri on 5/20/15.
//  Copyright (c) 2015 Verbatm. All rights reserved.
//

#import "verbatmMasterNavigationViewController.h"
#import "articleDispalyViewController.h"
#import "VerbatmUser.h"


@interface verbatmMasterNavigationViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *masterSV;
@property (weak, nonatomic) IBOutlet UIView *adk_contatiner;
@property (weak, nonatomic) IBOutlet UIView *articleList_container;
@property (nonatomic) NSInteger last_View_Index;//stores the index of the view that brings up the article display in order to aid our return
@property (nonatomic, strong) NSMutableArray * Display_pages;
@property (nonatomic, strong) NSMutableArray * Display_pinchObjects;
@property (nonatomic) CGPoint prev_Gesture_Point;

#define ANIMATION_DURATION 0.5
#define NUMBER_OF_CHILD_VCS 3
#define LEFT_FRAME self.view.bounds
#define RIGHT_FRAME CGRectMake(self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height)


#define NOTIFICATION_PAUSE_VIDEOS @"pauseContentPageVideosNotification"
#define NOTIFICATION_PLAY_VIDEOS @"playContentPageVideosNotification"
#define NOTIFICATION_SHOW_ADK @"notification_showADK"
#define NOTIFICATION_EXIT_ARTICLE_DISPLAY @"Notification_exitArticleDisplay"
#define SINGUP_SUCCEEDED_NOTIFICATION @"userSignedIn"
#define NOTIFICATION_CLEAR_CONTENTPAGE @"Notification_ClearContentPage"
#define NOTIFICATION_EXIT_CONTENTPAGE @"Notification_exitContentPage"

@end

@implementation verbatmMasterNavigationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self formatVCS];
    [self registerForNavNotifications];
    [self setUpGestureRecognizers];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self Login];
}

-(void)registerForNavNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showADK:) name:NOTIFICATION_SHOW_ADK object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(leaveArticleDisplay:) name:NOTIFICATION_EXIT_ARTICLE_DISPLAY object: nil];
    //signup for a notification that tells you the user has signed in
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(signUpSuccesful:) name:SINGUP_SUCCEEDED_NOTIFICATION object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showArticleList:) name:NOTIFICATION_EXIT_CONTENTPAGE object: nil];
}


-(void) showADK: (NSNotification *) notification
{
   [UIView animateWithDuration:ANIMATION_DURATION animations:^{
       self.masterSV.contentOffset = CGPointMake(self.view.frame.size.width, 0);
   }completion:^(BOOL finished) {
       if(finished)
       {
           [self play_CP_Vidoes];
       }
   }];
}

-(void)showArticleList:(NSNotification *)notification
{
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        self.masterSV.contentOffset = CGPointMake(0, 0);
    }completion:^(BOOL finished) {
        if(finished)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CLEAR_CONTENTPAGE
 object:nil userInfo:nil];
        }
    }];
}


//no longer being done
-(void)leaveArticleDisplay: (NSNotification *) notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

-(void)setUpGestureRecognizers
{
        UIScreenEdgePanGestureRecognizer* edgePanR = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(enter_adk:)];
        edgePanR.edges =  UIRectEdgeRight;
    UIScreenEdgePanGestureRecognizer* edgePanL = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(exit_adk:)];
    edgePanL.edges =  UIRectEdgeLeft;
    [self.view addGestureRecognizer: edgePanR];
    [self.view addGestureRecognizer: edgePanL];
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

//swipping left from right
-(void)enter_adk:(UIScreenEdgePanGestureRecognizer *)sender
{
    if([sender numberOfTouches] >1) return;//we want only one finger doing anything when exiting
    if(self.masterSV.contentOffset.x == self.view.frame.size.width) return;
    
    if(sender.state ==UIGestureRecognizerStateBegan)
    {
        self.prev_Gesture_Point  = [sender locationOfTouch:0 inView:self.view];
    }
    
    if(sender.state == UIGestureRecognizerStateChanged)
    {
        
        CGPoint current_point= [sender locationOfTouch:0 inView:self.view];;
        
        int diff = current_point.x - self.prev_Gesture_Point.x;
        self.prev_Gesture_Point = current_point;
        self.masterSV.contentOffset = CGPointMake(self.masterSV.contentOffset.x + (-1 *diff), 0);
    }
    
    if(sender.state == UIGestureRecognizerStateEnded)
    {
        [self adjustSV];
    }

}

//swipping right from left
- (void)exit_adk:(UIScreenEdgePanGestureRecognizer *)sender
{
    
        //this is here because this sense the left edge pan gesture- so we need to catch it and send it upstream
        if(super.articleCurrentlyViewing)
        {
            //we send the signal back up to it's superview to be handled
            [super exitDisplay:sender];
            return;
        }
         if(self.masterSV.contentOffset.x == 0) return;
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
            self.masterSV.contentOffset = CGPointMake(self.masterSV.contentOffset.x + (-1 *diff), 0);
        }
        
        if(sender.state == UIGestureRecognizerStateEnded)
        {
            [self adjustSV];
        }
}


-(void)adjustSV
{
    if(self.masterSV.contentOffset.x > (self.view.frame.size.width/2))
    {
            //bring ADK into View
            [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                self.masterSV.contentOffset = CGPointMake(self.view.frame.size.width, 0);
            }completion:^(BOOL finished) {
                if(finished)
                {
                    [self play_CP_Vidoes];
                }
            }];
    }else
    {
        //bring List into View
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            self.masterSV.contentOffset = CGPointMake(0, 0);
        }completion:^(BOOL finished) {
            if(finished)
            {
                [self pause_CP_Vidoes];
            }
        }];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

    if ([segue.identifier isEqualToString:@"display_articles_segue"])
    {
        articleDispalyViewController *vc = (articleDispalyViewController *)segue.destinationViewController;
        vc.Objects = (self.Display_pinchObjects) ? self.Display_pinchObjects : self.Display_pages;
    }
}



-(void)formatVCS
{
    self.masterSV.frame = self.view.bounds;
    self.masterSV.contentSize = CGSizeMake(self.view.frame.size.width*2, 0);//enable horizontal scroll
    self.masterSV.contentOffset = CGPointMake(0, 0);//start at the left
    self.articleList_container.frame = LEFT_FRAME ;
    self.adk_contatiner.frame = RIGHT_FRAME;
}

//for ios8- To hide the status bar
-(BOOL)prefersStatusBarHidden
{
    return YES;
}

-(void) removeStatusBar
{
    //remove the status bar
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        // iOS 7
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    } else {
        // iOS 6
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    }
}
#pragma mark - Handle Login -

//not that the signup was succesful - post a notiication
-(void) signUpSuccesful: (NSNotification *) notification
{
    NSLog(@"Signup Succeeded");
    //Removes the login page
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)Login
{
    if(![VerbatmUser currentUser])[self bringUpSignUp];
}

//brings up the login page if there is no user logged in
-(void)bringUpSignUp
{
    [self performSegueWithIdentifier:@"bringUpSign" sender:self];
}


#pragma mark Orientation
- (NSUInteger)supportedInterfaceOrientations
{
    //return supported orientation masks
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)done:(UIStoryboardSegue *)segue
{
    //MyModalVC *vc = (MyModalVC *)segue.sourceViewController; // get results out of vc, which I presented
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end