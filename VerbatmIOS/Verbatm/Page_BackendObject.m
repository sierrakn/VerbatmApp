//
//  Page_BackendObject.m
//  Verbatm
//
//  Created by Iain Usiri on 1/26/16.
//  Copyright © 2016 Verbatm. All rights reserved.
//

#import "CollectionPinchView.h"

#import "ImagePinchView.h"

#import "PageTypeAnalyzer.h"
#import <Parse/PFQuery.h>

#import "Page_BackendObject.h"
#import "ParseBackendKeys.h"
#import "Photo_BackendObject.h"
#import "Video_BackendObject.h"
#import "UtilityFunctions.h"

@interface Page_BackendObject ()

@property (strong) NSMutableArray * photoAndVideoSavers;

@end

@implementation Page_BackendObject

-(instancetype)init{
	self = [super init];
	if(self){
		self.photoAndVideoSavers = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void)savePageWithIndex:(NSInteger) pageIndex andPinchView:(PinchView *) pinchView andPost:(PFObject *) post{

	//create and save page object
	PFObject * newPageObject = [PFObject objectWithClassName:PAGE_PFCLASS_KEY];
	[newPageObject setObject:[NSNumber numberWithInteger:pageIndex] forKey:PAGE_INDEX_KEY];
	[newPageObject setObject:post forKey:PAGE_POST_KEY];

	if (pinchView.containsImage && pinchView.containsVideo) {
		[newPageObject setObject:[NSNumber numberWithInt:PageTypePhotoVideo] forKey:PAGE_VIEW_TYPE];

	} else if (pinchView.containsImage) {
		[newPageObject setObject:[NSNumber numberWithInt:PageTypePhoto] forKey:PAGE_VIEW_TYPE];
	} else {
		[newPageObject setObject:[NSNumber numberWithInt:PageTypeVideo] forKey:PAGE_VIEW_TYPE];
	}

	[newPageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
		if(succeeded){//now we save the media for the specific
			[self storeImagesFromPinchView:pinchView withPageReference:newPageObject];
			[self storeVideosFromPinchView:pinchView withPageReference:newPageObject];
		}
	}];
}


// when(stored every image)
// Each storeimage promise should resolve to the id of the GTL Image just stored
// So this promise should resolve to an array of gtl image id's
-(void) storeImagesFromPinchView: (PinchView*) pinchView withPageReference:(PFObject *) page {
	if (!pinchView.containsImage) return;

	NSArray* pinchViewPhotosWithText = [pinchView getPhotosWithText];
	NSMutableArray *imagePinchViews = [[NSMutableArray alloc] init];
	if ([pinchView isKindOfClass:[ImagePinchView class]]) {
		[imagePinchViews addObject:(ImagePinchView*) pinchView];
	} else if (pinchView.containsImage) {
		imagePinchViews = ((CollectionPinchView*)pinchView).imagePinchViews;
	}

	//Publishing images sequentially
	AnyPromise *getImageDataPromise = [imagePinchViews[0] getImageData];
	for (int i = 1; i < imagePinchViews.count; i++) {
		getImageDataPromise = getImageDataPromise.then(^(NSData *imageData) {
			NSArray* photoWithText = pinchViewPhotosWithText[i-1];
			[self storeImageFromImageData:imageData andPhotoWithTextArray:photoWithText
								  atIndex:i withPageObject:page];
			return [imagePinchViews[i] getImageData];
		});
	}
	getImageDataPromise.then(^(NSData *imageData) {
		NSInteger index = imagePinchViews.count - 1;
		NSArray* photoWithText = pinchViewPhotosWithText[index];
		[self storeImageFromImageData:imageData andPhotoWithTextArray:photoWithText
							  atIndex:index withPageObject:page];
	});
}

-(void) storeImageFromImageData: (NSData *) imageData andPhotoWithTextArray: (NSArray *)photoWithText
						atIndex: (NSInteger) index withPageObject: (PFObject *) page {
	NSString* text = photoWithText[1];
	NSNumber* textYPosition = photoWithText[2];
	UIColor *textColor = photoWithText[3];
	NSNumber *textAlignment = photoWithText[4];
	NSNumber *textSize = photoWithText[5];

	Photo_BackendObject * photoObj = [[Photo_BackendObject alloc] init];
	[self.photoAndVideoSavers addObject:photoObj];
	[photoObj saveImageData:imageData withText:text
	   andTextYPosition:textYPosition
		   andTextColor:textColor
	   andTextAlignment:textAlignment
			andTextSize:textSize
		   atPhotoIndex:index
		  andPageObject:page];
}

-(void) storeVideosFromPinchView: (PinchView*) pinchView withPageReference:(PFObject *) page{
	if (pinchView.containsVideo) {
		Video_BackendObject  *videoObj = [[Video_BackendObject alloc] init];
		[self.photoAndVideoSavers addObject:videoObj];

		AVAsset* videoAsset = [pinchView getVideo];
		if (![videoAsset isKindOfClass:[AVURLAsset class]]) {
			NSString *videoFileName = [UtilityFunctions randomStringWithLength:10];
			NSURL* exportURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@%@", NSTemporaryDirectory(), videoFileName, @".mp4"]];
			AVAssetExportSession* exporter = [[AVAssetExportSession alloc] initWithAsset:videoAsset
																			  presetName:AVAssetExportPresetPassthrough];

			[exporter setOutputURL:exportURL];
			[exporter setOutputFileType:AVFileTypeMPEG4];
			[exporter exportAsynchronouslyWithCompletionHandler:^(void){
				[videoObj saveVideo:exportURL andPageObject:page];
			}];
		} else {
			[videoObj saveVideo:((AVURLAsset *)videoAsset).URL andPageObject:page];
		}
	}
}

+(void)getPagesFromPost:(PFObject *) post andCompletionBlock:(void(^)(NSArray *))block {

	PFQuery * pagesQuery = [PFQuery queryWithClassName:PAGE_PFCLASS_KEY];
	[pagesQuery whereKey:PAGE_POST_KEY equalTo:post];
	[pagesQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects,
														 NSError * _Nullable error) {
		if(objects && !error){
			objects = [objects sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
				PFObject * pageA = obj1;
				PFObject * pageB = obj2;

				NSNumber * pageAnum = [pageA valueForKey:PAGE_INDEX_KEY];
				NSNumber * pageBnum = [pageB valueForKey:PAGE_INDEX_KEY];

				if([pageAnum integerValue] > [pageBnum integerValue]){
					return NSOrderedDescending;
				} else if ([pageAnum integerValue] < [pageBnum integerValue]){
					return NSOrderedAscending;
				}
				return NSOrderedSame;
			}];
			block(objects);
		}
	}];
}

+(void)deletePagesInPost:(PFObject *)post withCompletionBlock:(void(^)(BOOL))block {
	PFQuery * pagesQuery = [PFQuery queryWithClassName:PAGE_PFCLASS_KEY];
	[pagesQuery whereKey:PAGE_POST_KEY equalTo:post];
	[pagesQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects,
														 NSError * _Nullable error) {
		if(objects && !error){
			for (PFObject *obj in objects) {
				[Photo_BackendObject deletePhotosInPage:obj withCompeletionBlock:^(BOOL success) {
					block(success);
					[obj deleteInBackground];
				}];
			}
			return;
		}
		block(NO);
	}];
}


@end
