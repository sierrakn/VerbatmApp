//
//  photoVideoWrapperViewForText.m
//  Verbatm
//
//  Created by Iain Usiri on 10/7/15.
//  Copyright © 2015 Verbatm. All rights reserved.
//

#import "Durations.h"
#import "Icons.h"
#import "SizesAndPositions.h"
#import "Styles.h"
#import "StringsAndAppConstants.h"
#import "TextOverMediaView.h"
#import "UITextView+Utilities.h"
#import "UIImage+ImageEffectsAndTransforms.h"
#import "UtilityFunctions.h"

@interface TextOverMediaView ()

@property (nonatomic, readwrite) BOOL textShowing;

#pragma mark Text properties

@property (nonatomic, readwrite) CGFloat textYPosition;
@property (nonatomic, readwrite) CGFloat textSize;
@property (nonatomic, readwrite) NSTextAlignment textAlignment;
@property (nonatomic, readwrite) BOOL blackTextColor;

#define DEFAULT_TEXT_VIEW_FRAME CGRectMake(TEXT_VIEW_X_OFFSET, self.textYPosition, self.frame.size.width - TEXT_VIEW_X_OFFSET*2, TEXT_VIEW_OVER_MEDIA_MIN_HEIGHT)

@end

@implementation TextOverMediaView

-(instancetype) initWithFrame:(CGRect)frame andImageURL:(NSURL*)imageUrl
			   withSmallImage: (UIImage*)smallImage asSmall:(BOOL) small {
	self = [self initWithFrame:frame];
	if (self) {
		UIImage *croppedImage = smallImage;
		if (small) {
			croppedImage = [smallImage imageByScalingAndCroppingForSize: CGSizeMake(self.bounds.size.width, self.bounds.size.height)];
		}
		[self addSubview: self.textView];
		[self.imageView setImage: croppedImage];

		// Load large image cropped
		if (!small) {
			NSString *imageURI = [UtilityFunctions addSuffixToPhotoUrl:imageUrl.absoluteString forSize: LARGE_IMAGE_SIZE];
			imageUrl = [NSURL URLWithString: imageURI];
            __weak TextOverMediaView *weakSelf = self;
			[[UtilityFunctions sharedInstance] loadCachedPhotoDataFromURL:imageUrl].then(^(NSData* largeImageData) {
				// Only display larger data if less than 1000 KB
				if (largeImageData.length / 1024.f < 1000) {
					UIImage *image = [UIImage imageWithData:largeImageData];
					[weakSelf.imageView setImage: image];
				} else {
					NSLog(@"Image too big");
				}
			});
		}
	}
	return self;
}

-(instancetype) initWithFrame:(CGRect)frame andImage: (UIImage *)image {
	self = [self initWithFrame: frame];
	if (self) {
		[self addSubview: self.textView];
		[self.imageView setImage: image];
	}
	return self;
}

-(instancetype) initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self revertToDefaultTextSettings];
        [self setBackgroundColor:[UIColor PAGE_BACKGROUND_COLOR]];
	}
	return self;
}

/* Returns image view with image centered */
-(UIImageView*) getImageViewForImage:(UIImage*) image {
	UIImageView* photoView = [[UIImageView alloc] initWithImage:image];
	photoView.frame = self.bounds;
	photoView.clipsToBounds = YES;
	photoView.contentMode = UIViewContentModeScaleAspectFit;
	return photoView;
}

-(void)changeImageTo:(UIImage *) image {
	[self.imageView setImage:image];
}

#pragma mark - Text View functionality -

-(void) setText:(NSString *)text
andTextYPosition:(CGFloat) textYPosition
andTextColorBlack:(BOOL) textColorBlack
andTextAlignment:(NSTextAlignment) textAlignment
    andTextSize:(CGFloat) textSize andFontName:(NSString *) fontName{
    UIColor *textColor = textColorBlack ? [UIColor blackColor] : [UIColor whiteColor];
    [self changeTextColor:textColor];
    if(!text.length) return;

	self.textYPosition = textYPosition;
	self.textView.frame = DEFAULT_TEXT_VIEW_FRAME;
    [self changeTextAlignment: textAlignment];

	self.textSize = textSize;
    
    [self.textView setFont:[UIFont fontWithName:fontName size:self.textSize]];
    
	[self changeText: text];
   
}

-(void) revertToDefaultTextSettings {
	[self changeText:@""];

	self.textYPosition = TEXT_VIEW_OVER_MEDIA_Y_OFFSET;
	self.textView.frame = DEFAULT_TEXT_VIEW_FRAME;

    [self.textView setBackgroundColor:[UIColor clearColor]];

	self.textSize = TEXT_PAGE_VIEW_DEFAULT_FONT_SIZE;
	[self.textView setFont:[UIFont fontWithName:TEXT_PAGE_VIEW_DEFAULT_FONT size:self.textSize]];

	[self changeTextAlignment: NSTextAlignmentLeft];
	[self changeTextColor:[UIColor TEXT_PAGE_VIEW_DEFAULT_COLOR]];
}

-(void)changeText:(NSString *) text{
	[self.textView setText:text];
	[self resizeTextView];
	[self bringSubviewToFront:self.textView];
}

-(NSString *) getText {
	return self.textView.text;
}

- (void) changeTextViewYPosByDiff: (CGFloat) yDiff {
	CGRect newFrame = CGRectOffset(self.textView.frame, 0.f, yDiff);
	[self changeTextViewYPos: newFrame.origin.y];
}

-(void) changeTextViewYPos: (CGFloat) newYPos {
	CGFloat contentHeight = [self.textView measureContentHeight];
	if ((newYPos + contentHeight) > (self.frame.size.height - TEXT_TOOLBAR_HEIGHT)) {
		newYPos = self.frame.size.height - TEXT_TOOLBAR_HEIGHT - contentHeight;
	}
	if (newYPos < 0.f) {
		newYPos = 0.f;
	}
	CGRect newFrame = self.textView.frame;
	newFrame.origin.y = newYPos;
	self.textView.frame = newFrame;
	self.textYPosition = newYPos;
}

-(void) animateTextViewToYPos: (CGFloat) yPos {
	self.textYPosition = yPos;
	CGRect tempFrame = CGRectMake(self.textView.frame.origin.x, yPos,
								  self.textView.frame.size.width, self.textView.frame.size.height);
    __weak TextOverMediaView * weakSelf = self;
	[UIView animateWithDuration:SNAP_ANIMATION_DURATION  animations:^{
		if(weakSelf)weakSelf.textView.frame = tempFrame;
	}];
}

-(void) changeTextColor:(UIColor *)textColor {
	self.textView.textColor = textColor;
	self.textView.tintColor = textColor;
	if([self.textView isFirstResponder]) {
		[self.textView resignFirstResponder];
		[self.textView becomeFirstResponder];
	}
}

-(void) changeTextAlignment:(NSTextAlignment)textAlignment {
	self.textAlignment = textAlignment;
	[self.textView setTextAlignment:textAlignment];
}

-(void) increaseTextSize {
	self.textSize += 2;
	if (self.textSize > TEXT_PAGE_VIEW_MAX_FONT_SIZE) self.textSize = TEXT_PAGE_VIEW_MAX_FONT_SIZE;
	[self.textView setFont:[UIFont fontWithName:self.textView.font.fontName size:self.textSize]];
}

-(void) decreaseTextSize {
	self.textSize -= 2;
	if (self.textSize < TEXT_PAGE_VIEW_MIN_FONT_SIZE) self.textSize = TEXT_PAGE_VIEW_MIN_FONT_SIZE;
	[self.textView setFont:[UIFont fontWithName:self.textView.font.fontName size:self.textSize]];
}

-(void) addTextViewGestureRecognizer: (UIGestureRecognizer*)gestureRecognizer {
	[self.textView addGestureRecognizer:gestureRecognizer];
}

/* Adds or removes text view */
-(void)showText: (BOOL) show {
	if (show) {
		[self.textView setHidden: NO];
		[self bringSubviewToFront:self.textView];
	} else {
		if (!self.textShowing) return;
		[self.textView setHidden:YES];
	}
	self.textShowing = !self.textShowing;
}

-(BOOL) pointInTextView: (CGPoint)point withBuffer: (CGFloat)buffer {
	return point.y > self.textView.frame.origin.y - buffer
	&& point.y < self.textView.frame.origin.y + self.textView.frame.size.height + buffer;
}

#pragma mark - Change text properties -

-(void) setTextViewEditable:(BOOL)editable {
	self.textView.editable = editable;
}

-(void) setTextViewDelegate:(id<UITextViewDelegate>)textViewDelegate {
	self.textView.delegate = textViewDelegate;
}

-(void) setTextViewKeyboardToolbar:(UIView*)toolbar {
	self.textView.inputAccessoryView = toolbar;
}

-(void) setTextViewFirstResponder:(BOOL)firstResponder {
	if (firstResponder) {
		[self.textView.inputAccessoryView removeFromSuperview];
		[self.textView becomeFirstResponder];
	} else if (self.textView.isFirstResponder) {
		[self.textView resignFirstResponder];
	}
}

/* Resizes text view based on content height. Only resizes to a height larger than the default. */
-(void) resizeTextView {
	CGFloat contentHeight = [self.textView measureContentHeight];
	float height = (TEXT_VIEW_OVER_MEDIA_MIN_HEIGHT < contentHeight) ? contentHeight : TEXT_VIEW_OVER_MEDIA_MIN_HEIGHT;
    
    
    
	self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y,
									 self.textView.frame.size.width, height);
}

#pragma mark - Lazy Instantiation -

-(UIImageView*) imageView {
	if (!_imageView) {
		UIImageView *imageView = [[UIImageView alloc] initWithFrame: self.bounds];
		[self insertSubview:imageView belowSubview:self.textView];
		_imageView = imageView;
		_imageView.clipsToBounds = YES;
		_imageView.contentMode = UIViewContentModeScaleAspectFill;
	}
	return _imageView;
}

-(UITextView*) textView {
	if (!_textView) {
		_textView = [[UITextView alloc] initWithFrame: DEFAULT_TEXT_VIEW_FRAME];
		_textView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
		_textView.keyboardAppearance = UIKeyboardAppearanceLight;
		_textView.scrollEnabled = YES;
		_textView.editable = NO;
		_textView.selectable = NO;
		[_textView setTintAdjustmentMode:UIViewTintAdjustmentModeNormal];
	}
	return _textView;
}

-(void)dealloc{
    _imageView.image = nil;
    _imageView = nil;
}

@end

