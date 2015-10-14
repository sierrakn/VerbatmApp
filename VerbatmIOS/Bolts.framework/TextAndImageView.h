//
//  photoVideoWrapperViewForText.h
//  Verbatm
//
//  Created by Iain Usiri on 10/7/15.
//  Copyright © 2015 Verbatm. All rights reserved.
//

/*
 This frame takes care of photos or videos in AVEs. They are added as subviews to the frame.
 The function of this frame is to manage the textviews that are placed on top - and to know when to present them and not present them.
 */


#import <UIKit/UIKit.h>
@interface TextAndImageView : UIView

@property (nonatomic, strong) UIImageView* imageView;
//NOT IN USE @property (nonatomic, strong) UIImageView* blurPhotoView;
@property (nonatomic, strong) UITextView * textView;
@property (nonatomic, readonly) BOOL textShowing;

-(instancetype) initWithFrame:(CGRect)frame andImage: (UIImage*) image andText: (NSString*) text andTextYPosition: (CGFloat) textYPosition;

-(void) resizeTextView;

-(void) showText: (BOOL) show;

@end
