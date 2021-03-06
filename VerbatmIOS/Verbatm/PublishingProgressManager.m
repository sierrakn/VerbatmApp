//
//  PublishingProgressManager.m
//  Verbatm
//
//  Created by Iain Usiri on 2/17/16.
//  Copyright © 2016 Verbatm. All rights reserved.
//

#import "CollectionPinchView.h"
#import "Channel_BackendObject.h"

#import "ExternalShare.h"

#import "ImagePinchView.h"

#import "Notifications.h"


#import "PinchView.h"
#import "PublishingProgressManager.h"
#import "ParseBackendKeys.h"
#import "Post_Channel_RelationshipManager.h"
#import "PostInProgress.h"
#import "Page_BackendObject.h"
#import "Photo_BackendObject.h"
#import "PageTypeAnalyzer.h"
#import "PublishingProgressView.h"
#import "PreviewDisplayView.h"

#import "UIView+Effects.h"

#import "Video_BackendObject.h"
#import <PromiseKit/PromiseKit.h>


@interface PublishingProgressManager()

@property (nonatomic, readwrite) BOOL currentlyPublishing;
//the first "domino" of parse saving
//should be made nil when saving is done or when it fails
@property (nonatomic) Channel_BackendObject * channelManager;

@property (nonatomic, readwrite) Channel* currentPublishingChannel;

@property (nonatomic, readwrite) NSProgress * progressAccountant;

@property (nonatomic) PFObject * currentParsePostObject;

@property (nonatomic) ExternalShare* externalShareObject;

@property (nonatomic) BOOL shareToFB;

@property (nonatomic,strong) UIImage * publishingProgressBackgroundImage;

@property (nonatomic) NSString * captionToShare;

@property (nonatomic) SelectedPlatformsToShareLink locationToShare;

@property (nonatomic) UIBackgroundTaskIdentifier publishingTask;

@end

@implementation PublishingProgressManager


+(instancetype)sharedInstance{
	static PublishingProgressManager *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[PublishingProgressManager alloc] init];
	});
	return sharedInstance;
}

-(instancetype) init {
	self = [super init];
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(userHasSignedOut)
													 name:NOTIFICATION_USER_SIGNED_OUT
												   object:nil];
	}
	return self;
}

-(void) userHasSignedOut {
	[[UIApplication sharedApplication] endBackgroundTask: self.publishingTask];
	self.publishingTask = UIBackgroundTaskInvalid;
	self.channelManager = nil;
	self.currentPublishingChannel = nil;
	self.progressAccountant = nil;
	self.currentParsePostObject = nil;
	self.externalShareObject = nil;
	self.shareToFB = NO;
	self.publishingProgressBackgroundImage = nil;
	self.captionToShare = nil;
}

-(void)storeLocationToShare:(SelectedPlatformsToShareLink)locationToShare withCaption:(NSString *) caption {
    self.locationToShare = locationToShare;
    self.captionToShare = caption;
}

-(void)storeProgressBackgroundImage:(UIImage *) image{
	self.publishingProgressBackgroundImage = image;
}

-(UIImage *) getProgressBackgroundImage{
    return self.publishingProgressBackgroundImage;
}

// Blocks is publishing something else, no network
-(void)publishPostToChannel:(Channel *)channel andFacebook:(BOOL)externalShare withCaption:(NSString *)caption withPinchViews:(NSArray *)pinchViews
		withCompletionBlock:(void(^)(BOOL, BOOL))publishHasStartedSuccessfully {
    
    self.externalShareObject = [[ExternalShare alloc] initWithCaption:caption];
	self.shareToFB = externalShare;

	if (self.currentlyPublishing) {
		publishHasStartedSuccessfully (YES, NO);
		return;
	} else {
		self.currentlyPublishing = YES;
	}

	self.channelManager = [[Channel_BackendObject alloc] init];
    [self countMediaContentFromPinchViews:pinchViews];

	// Load all screenshots first so that you can close app while publishing
	NSMutableArray *loadScreenshotsPromises = [[NSMutableArray alloc] init];
	for (PinchView *pinchView in pinchViews) {
		pinchView.beingPublished = YES;
		if ([pinchView isKindOfClass:[ImagePinchView class]]) {
			ImagePinchView* imagePinchView = (ImagePinchView*)pinchView;
			imagePinchView.beingPublished = YES;
			[loadScreenshotsPromises addObject: [imagePinchView getImageDataWithHalfSize: NO]];
		} else if ([pinchView isKindOfClass:[CollectionPinchView class]]) {
			BOOL half = ((CollectionPinchView*)pinchView).containsImage && ((CollectionPinchView*)pinchView).containsVideo;
			for (ImagePinchView *subImagePinchView in [(CollectionPinchView*)pinchView imagePinchViews]) {
				subImagePinchView.beingPublished = YES;
				[loadScreenshotsPromises addObject: [subImagePinchView getImageDataWithHalfSize: half]];
			}
		}
	}
	self.publishingTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"PublishingTask" expirationHandler:^{
		// Clean up any unfinished task business by marking where you
		// stopped or ending the task outright.
		[[UIApplication sharedApplication] endBackgroundTask: self.publishingTask];
		self.publishingTask = UIBackgroundTaskInvalid;
	}];

	PMKWhen(loadScreenshotsPromises).then(^(NSArray* data) {
		[self.channelManager createPostFromPinchViews:pinchViews
											toChannel:channel
								  withCompletionBlock:^(PFObject *parsePostObject) {
									  if (!parsePostObject) {
										  publishHasStartedSuccessfully (NO, YES);
										  return;
									  }
									  self.currentParsePostObject = parsePostObject;
									  self.currentPublishingChannel = channel;
									  [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_POST_CURRENTLY_PUBLISHING object:nil];
									  publishHasStartedSuccessfully(NO, NO);
								  }];
	});
}

-(void)countMediaContentFromPinchViews:(NSArray *)pinchViews {

	// There's an extra unit for the final upload to parse of the video or image
	NSInteger imageUnits = (IMAGE_PROGRESS_UNITS + 1);
	// Video + screenshot
	NSInteger videoUnits = (VIDEO_PROGRESS_UNITS + IMAGE_PROGRESS_UNITS + 1);

	NSInteger totalProgressUnits = INITIAL_PROGRESS_UNITS;
	for(PinchView * pinchView in pinchViews) {
		if([pinchView isKindOfClass:[CollectionPinchView class]]){
            
            CGFloat numImagePinchViews = [(CollectionPinchView *)pinchView imagePinchViews].count;
            CGFloat numVideoPinchViews = [(CollectionPinchView *)pinchView videoPinchViews].count;

			// One for final publishing of each image
			totalProgressUnits +=  numImagePinchViews * imageUnits;
			totalProgressUnits +=  numVideoPinchViews > 0 ? videoUnits : 0;

		} else {//only one piece of media
			//Saves thumbnail for every video too so include the progress for that.
            if([pinchView isKindOfClass:[VideoPinchView class]]){
                totalProgressUnits += videoUnits;
            }else{
				totalProgressUnits += imageUnits;
            }
		}
	}
	self.progressAccountant = [NSProgress progressWithTotalUnitCount: totalProgressUnits];
	self.progressAccountant.completedUnitCount = INITIAL_PROGRESS_UNITS;
}

-(void)savingMediaFailedWithError:(NSError*)error {
	self.progressAccountant.completedUnitCount = 0;
	self.currentPublishingChannel = NULL;
	self.currentlyPublishing = NO;
    self.publishingProgressBackgroundImage = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_POST_FAILED_TO_PUBLISH object:error];

	//todo: alert user that publishing failed when they come back to app
	[[UIApplication sharedApplication] endBackgroundTask: self.publishingTask];
	self.publishingTask = UIBackgroundTaskInvalid;
}

-(void)mediaSavingProgressed:(NSInteger) newProgress {
	self.progressAccountant.completedUnitCount += newProgress;
	NSLog(@"Media saving progressed %ld new units to completed %lld units of total %lld units", (long)newProgress,
		  self.progressAccountant.completedUnitCount, self.progressAccountant.totalUnitCount);
	if (self.progressAccountant.completedUnitCount >= self.progressAccountant.totalUnitCount
		&& self.currentlyPublishing && self.currentParsePostObject) {
		[self postPublishedSuccessfully];
	}
}

-(void)postPublishedSuccessfully {
	[self.currentParsePostObject setObject:[NSNumber numberWithBool:YES] forKey:POST_COMPLETED_SAVING];
	[self.currentParsePostObject saveInBackground];
	//register the relationship
	[Post_Channel_RelationshipManager savePost:self.currentParsePostObject toChannels:[NSMutableArray arrayWithObject:self.currentPublishingChannel] withCompletionBlock:^{
		self.progressAccountant.completedUnitCount = 0;
		self.progressAccountant.totalUnitCount = 0;
		self.currentlyPublishing = NO;
		NSNotification *notification = [[NSNotification alloc]initWithName:NOTIFICATION_POST_PUBLISHED object:nil userInfo:nil];
		[[NSNotificationCenter defaultCenter] postNotification: notification];
        [self.externalShareObject storeShareLinkToPost:self.currentParsePostObject withCaption:self.captionToShare withCompletionBlock:^(bool savedSuccessfully, PFObject * postObject) {
            if(savedSuccessfully){
                [self.externalShareObject sharePostLink:[postObject objectForKey:POST_SHARE_LINK] toPlatform:self.locationToShare];
            } else {
                NSLog(@"Failed to get and save link to post :/");
            }
			[[PostInProgress sharedInstance] clearPostInProgress];
			self.currentParsePostObject = nil;
			self.currentPublishingChannel = nil;
			self.publishingProgressBackgroundImage = nil;
			[[UIApplication sharedApplication] endBackgroundTask: self.publishingTask];
			self.publishingTask = UIBackgroundTaskInvalid;
        }];

	}];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end






