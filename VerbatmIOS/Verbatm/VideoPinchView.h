//
//  VideoPinchView.h
//  Verbatm
//
//  Created by Sierra Kaplan-Nelson on 7/26/15.
//  Copyright (c) 2015 Verbatm. All rights reserved.
//

#import "PinchView.h"
#import "SingleMediaAndTextPinchView.h"

@class AnyPromise;

@interface VideoPinchView : SingleMediaAndTextPinchView

@property (strong, nonatomic) AVURLAsset* video;
@property (strong, nonatomic) NSString* phAssetLocalIdentifier;

-(instancetype)initWithRadius:(CGFloat)radius withCenter:(CGPoint)center andVideo: (AVURLAsset*)video
	andPHAssetLocalIdentifier: (NSString*) localIdentifier;

// sets up the pinch view with a video
-(void) initWithVideo: (AVURLAsset*) video;

// call after being decoded with nscoding
// Resolves to avurlasset
-(AnyPromise*) loadAVURLAssetFromPHAsset;

@end
