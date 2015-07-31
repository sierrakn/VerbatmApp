//
//  BlurView.h
//  Verbatm
//
//  Created by Sierra Kaplan-Nelson on 7/15/15.
//  Copyright © 2015 Verbatm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIEffects : NSObject

+ (UIVisualEffectView*) createBlurViewOnView: (UIView*)view withStyle:(UIBlurEffectStyle) blurStyle;

+ (UIImage *)blurredImageWithImage:(UIImage *)sourceImage andFilterLevel: (float) filterValue;

+(UIImage*) getGlowImageFromView:(UIView*)view andColor:(UIColor*)color;

+ (void) addShadowToView: (UIView *) view;

// adds dashed border to view using view.bounds as frame
+ (void) addDashedBorderToView: (UIView *) view;

+(void) addDashedBorderToView:(UIView *)view withFrame:(CGRect) frame;

+ (UIImage*) imageOverlayed:(UIImage*)image withColor:(UIColor*)color;

+ (UIImage *)image:(UIImage*) image byApplyingAlpha:(CGFloat) alpha;

+ (UIImage*)scaleImage:(UIImage*)image toSize:(CGSize)size;

+(CGSize) getSizeForImage:(UIImage*)image andBounds:(CGRect)bounds;

+ (UIImage *)fixOrientation:(UIImage*) image;

// Contains code for iOS 7+. contentSize no longer returns the correct value, so
// we have to calculate it.
+ (CGFloat)measureContentHeightOfUITextView:(UITextView *)textView;

+ (void) disableSpellCheckOnTextField: (UITextField*)textView;

//Returns list of photo filter names to use
+ (NSArray*) getPhotoFilters;

@end
