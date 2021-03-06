//
//  verbatmCustomPinchView.h
//  Verbatm
//
//  Created by Lucio Dery Jnr Mwinmaarong on 11/15/14.
//  Copyright (c) 2014 Verbatm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import "ContentDevVC.h"

@class CollectionPinchView;

@interface PinchView : UIView <NSCoding, ContentDevElementDelegate>

@property (nonatomic) BOOL beingPublished;


@property (nonatomic,readonly) float radius;
@property (nonatomic,readonly) CGPoint center;

@property(strong,nonatomic) UIView * background;

//tells you if the object is selected for panning
@property (nonatomic) BOOL selected;

@property (nonatomic) BOOL containsImage;
@property (nonatomic) BOOL containsVideo;

//This creates a new pinch object with a particular radius and a center
-(instancetype)initWithRadius:(CGFloat)radius withCenter:(CGPoint)center;

/*
 allows you to change the width and height of the object without changing it's center
 note that the object frame is a square so width == height
 */
-(void) changeWidthTo: (CGFloat) width;

/*
 *This sets the frame of the pinch object, updating
 its radius and center properties
*/
-(void)specifyFrame:(CGRect)frame;

//Updats the radius and center and resets the frame based on these
-(void) specifyRadius:(CGFloat)radius andCenter:(CGPoint)center;

-(void) addEditIcon;
//This reverts to the center and radius specified
//for the pinch view during initialization
-(void)revertToInitialFrame;

-(NSInteger) numTypesOfMedia;

//for intructing to render media
-(void)renderMedia;

//zeros out the border for the pinch view
-(void)removeBorder;

#pragma mark Should be overriden in subclasses
//returns 1 because each PinchView holds one piece of media
-(NSInteger) getTotalPiecesOfMedia;

//array of @[UIImage*, NSString*, NSNumber /* with float value */]
// image, text, and y position for the text
-(NSArray*) getPhotosWithText;

-(AVURLAsset*) getVideo;

-(void)onScreen;
-(void)offScreen;

-(void)publishingPinchView;
@end
