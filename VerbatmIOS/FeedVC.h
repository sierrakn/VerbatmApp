//
//  feedDisplayTVC.h
//  Verbatm
//
//  Created by Iain Usiri on 8/28/15.
//  Copyright (c) 2015 Verbatm. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol FeedVCDelegate <NSObject>

// passing nav bar events up the chain
-(void) profileButtonPressed;
-(void) adkButtonPressed;
-(void) homeButtonPressed;

-(void) displayPOVWithIndex:(NSInteger)index fromLoadManager:(POVLoadManager *)loadManager;
-(void) refreshingFeedsFailed;

@end

@interface FeedVC : UIViewController

@property(strong, nonatomic) id<FeedVCDelegate> delegate;

// animates the fact that a recent POV is publishing
-(void) showPOVPublishingWithUserName: (NSString*)userName andTitle: (NSString*) title andCoverPic: (UIImage*) coverPic
					andProgressObject:(NSProgress *)publishingProgress;

//Makes sure selected cell is deselected (resets formatting for it)
-(void) deSelectCell;

// Tells feed to notify both recent and trending feeds that a povInfo has been liked by the current user
-(void) userHasLikedPOV: (BOOL) liked withPovInfo: (PovInfo*) povInfo;

@end
