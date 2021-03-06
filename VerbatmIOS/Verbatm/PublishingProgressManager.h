//
//  PublishingProgressManager.h
//  Verbatm
//
//  Created by Iain Usiri on 2/17/16.
//  Copyright © 2016 Verbatm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Channel.h"
#import "ExternalShare.h"

/*
 Manages the publishing of content (by starting the parse domino effect)
 but is mainly used to track progress and to notify relevant ui. Because you can
 only publish one post at a time and because we only have one publishing UI bar
 we simply rely on a delegate to communite progress completion.
 You track the NSProgress Accountant to see how far we're progressing with media saving.
 */

@class Channel_BackendObject;

@interface PublishingProgressManager : NSObject

#define INITIAL_PROGRESS_UNITS 3
#define IMAGE_PROGRESS_UNITS 3
#define VIDEO_PROGRESS_UNITS 20

@property (nonatomic, readonly) NSProgress * progressAccountant;
@property (nonatomic, readonly) BOOL currentlyPublishing;
@property (nonatomic, readonly) Channel* currentPublishingChannel;

+(instancetype)sharedInstance;

// Blocks is publishing something else, no network
-(void)publishPostToChannel:(Channel *)channel andFacebook:(BOOL)externalShare withCaption:(NSString *)caption withPinchViews:(NSArray *)pinchViews withCompletionBlock:(void(^)(BOOL, BOOL))block;

-(void)mediaSavingProgressed:(NSInteger) newProgress;

-(void)savingMediaFailedWithError:(NSError*)error;

-(void)storeLocationToShare:(SelectedPlatformsToShareLink)locationToShare withCaption:(NSString *) caption;

//stores a screenshot of the first page to be used during the progress report
-(void)storeProgressBackgroundImage:(UIImage *) image;

-(UIImage *) getProgressBackgroundImage;


@end








