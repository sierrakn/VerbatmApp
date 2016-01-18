//
//  verbatmCustomImageScrollView.m
//  Verbatm
//
//  Created by Lucio Dery Jnr Mwinmaarong on 12/20/14.
//  Copyright (c) 2014 Verbatm. All rights reserved.
//

#import "ContentDevPullBar.h"
#import "ContentDevVC.h"
#import "CollectionPinchView.h"
#import "Durations.h"
#import "EditMediaContentView.h"
#import "Icons.h"
#import "ImagePinchView.h"
#import "Notifications.h"

#import "SizesAndPositions.h"
#import "SingleMediaAndTextPinchView.h"
#import "StringsAndAppConstants.h"
#import "Styles.h"

#import "TextOverMediaView.h"

#import "VerbatmKeyboardToolBar.h"
#import "VerbatmImageScrollView.h"

#import "UIImage+ImageEffectsAndTransforms.h"
#import "UITextView+Utilities.h"

@interface EditMediaContentView () <KeyboardToolBarDelegate, UITextViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) TextOverMediaView * textAndImageView;

#pragma mark FilteredPhotos
@property (nonatomic, strong) NSMutableArray * filteredImages;
@property (nonatomic) NSInteger imageIndex;
@property (nonatomic, strong) UIButton * textCreationButton;

@property (nonatomic) CGPoint  panStartLocation;

@property (nonatomic) CGPoint  textViewPanStartLocation;

@property (nonatomic) CGFloat horizontalPanDistance;
@property (nonatomic) BOOL isHorizontalPan;

@property (nonatomic) BOOL filterSwitched;//per pan gesture we check if we have switched the filter yet

@property (nonatomic) BOOL gestureInAction; //lets us know if we're tracking the same gesture from beginning to end
@property (nonatomic) BOOL gestureActionJustStarted; //lets us know if we're tracking the same gesture from beginning to end

@property (nonatomic) NSInteger keyboardHeight;

@property (nonatomic) CGRect userSetFrame;//keeps the frame the user set from panning so can revert after keyboard goes away

@property (nonatomic) BOOL hasBeenSetUp;


#define HORIZONTAL_PAN_FILTER_SWITCH_DISTANCE 11
#define TOUCH_BUFFER 20
#define DIAGONAL_THRESHOLD 600

@property (nonatomic) NSMutableArray * videoAssets;

@end


@implementation EditMediaContentView

-(instancetype) initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if(self) {
		self.backgroundColor = [UIColor AVE_BACKGROUND_COLOR];
		[self registerForKeyboardNotifications];
	}
	return self;
}


-(void)registerForKeyboardNotifications{
    //Tune in to get notifications of keyboard behavior
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];


    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyBoardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
}

#pragma mark - Text View -

-(void)createTextCreationButton {
    [self.textCreationButton setImage:[UIImage imageNamed:CREATE_TEXT_ICON] forState:UIControlStateNormal];
    self.textCreationButton.imageView.contentMode = UIViewContentModeScaleAspectFit;

    [self.textCreationButton addTarget:self action:@selector(editText) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.textCreationButton];
    [self bringSubviewToFront:self.textCreationButton];
	[self addLongPress];
}

// long press does the same thing as text button
-(void) addLongPress {
	UILongPressGestureRecognizer * longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(editText)];
	longPressRecognizer.minimumPressDuration = 0.1;
	[self addGestureRecognizer:longPressRecognizer];
}

-(void) editText {
	if(![self.textAndImageView textShowing]) {
		[self setText:@"" andTextViewYPosition: TEXT_VIEW_OVER_MEDIA_Y_OFFSET];
	}
	[self.textAndImageView.textView becomeFirstResponder];
}

-(void) setText: (NSString*) text andTextViewYPosition: (CGFloat) yPosition {
	self.textAndImageView.textView.editable = YES;
    [self.textAndImageView setText:text];
	[self.textAndImageView.textView setFrame: CGRectMake(self.textAndImageView.textView.frame.origin.x, yPosition,
														 self.textAndImageView.textView.frame.size.width,
														  self.textAndImageView.textView.frame.size.height)];
	[self.textAndImageView showText:YES];
	[self.textAndImageView.textView setDelegate:self];
	[self.textAndImageView resizeTextView];
	[self addToolBarToView];
}

#pragma mark - Keyboard ToolBar -

//creates a toolbar to add onto the keyboard
-(void)addToolBarToView {
	CGRect toolBarFrame = CGRectMake(0, self.frame.size.height - TEXT_TOOLBAR_HEIGHT, self.frame.size.width, TEXT_TOOLBAR_HEIGHT);
	VerbatmKeyboardToolBar* toolBar = [[VerbatmKeyboardToolBar alloc] initWithFrame:toolBarFrame];
	[toolBar setDelegate:self];
	self.textAndImageView.textView.inputAccessoryView = toolBar;
}

#pragma mark - Return text and text y position -

-(NSString*) getText {
	return [self.textAndImageView.textView text];
}

-(NSNumber*) getTextYPosition {
	return [NSNumber numberWithFloat: self.textAndImageView.textView.frame.origin.y];
}

#pragma mark Text view content changed

//User has edited the text view somehow so we adjust its size
- (void)textViewDidChange:(UITextView *)textView {
	[self.textAndImageView resizeTextView];
}

- (void)textViewDidBeginEditing:(UITextView *)textView{
	
    [self.delegate textIsEditing];
    
    self.userSetFrame = textView.frame;
    if((textView.frame.origin.y + textView.frame.size.height) > (self.frame.size.height - self.keyboardHeight - TEXT_TOOLBAR_HEIGHT)){
        [UIView animateWithDuration:SNAP_ANIMATION_DURATION  animations:^{
            self.textAndImageView.textView.frame = CGRectMake(0,TEXT_VIEW_OVER_MEDIA_Y_OFFSET,
											 self.textAndImageView.textView.frame.size.width,
                                             self.textAndImageView.textView.frame.size.height);
        }];
    }
}

-(void)textViewDidEndEditing:(UITextView *)textView{
//	if(self.textAndImageView.textView.frame.origin.y != self.userSetFrame.origin.y){
//		[UIView animateWithDuration:SNAP_ANIMATION_DURATION  animations:^{
//			self.textAndImageView.textView.frame = self.userSetFrame;
//		}];
//	}
}

// enforce word limit
- (BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	NSString* newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
	NSString *trimmedText = [newText stringByReplacingOccurrencesOfString:@" " withString:@""];

	if (newText.length - trimmedText.length > TEXT_WORD_LIMIT) {
		return NO;
	} else {
		return YES;
	}
}

#pragma mark Keyboard Notifications

//When keyboard appears get its height. This is only neccessary when the keyboard first appears
-(void)keyboardWillShow:(NSNotification *) notification {
    // Get the size of the keyboard.
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    //store the keyboard height for further use
    self.keyboardHeight = keyboardSize.height;
}

-(void)keyBoardWillChangeFrame: (NSNotification *) notification {
    // Get the size of the keyboard.
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    //store the keyboard height for further use
    self.keyboardHeight = keyboardSize.height;
}

#pragma mark - Image or Video View -

-(void) displayVideo: (NSMutableArray *) videoAssetArray {
	
    if(self.videoView)[self.videoView stopVideo];
    
    self.videoView = [[VideoPlayerView alloc]init];
	self.videoView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
	[self addSubview:self.videoView];
	[self bringSubviewToFront:self.videoView];
	self.videoView.repeatsVideo = YES;
	//[self addTapGestureToMainView];
    
    self.videoAssets = videoAssetArray;
}

-(void)displayImages: (NSMutableArray*) filteredImages atIndex:(NSInteger)index {
	self.imageIndex = index;
	
    self.textAndImageView = [[TextOverMediaView alloc] initWithFrame:self.bounds
                                                            andImage:filteredImages[index]
															andText:@"" andTextYPosition:TEXT_VIEW_OVER_MEDIA_Y_OFFSET];
	self.filteredImages = filteredImages;
    [self addSubview: self.textAndImageView];
	//[self addTapGestureToMainView];
	[self addPanGesture];
    [self createTextCreationButton];
    
}

#pragma mark Filters

-(void)changeFilteredImageLeft{
    if (self.imageIndex >= ([self.filteredImages count]-1)) {
		self.imageIndex = -1;
	}
	self.imageIndex = self.imageIndex+1;
	[self.textAndImageView changeImageTo:self.filteredImages[self.imageIndex]];
    
    [self updatePinchView];

}

-(void)changeFilteredImageRight{
	if (self.imageIndex <= 0) {
		self.imageIndex = [self.filteredImages count];
	}
	self.imageIndex = self.imageIndex-1;
	[self.textAndImageView changeImageTo:self.filteredImages[self.imageIndex]];
    [self updatePinchView];

}

-(NSInteger) getFilteredImageIndex {
	return self.imageIndex;
}

#pragma mark - Exit view

-(void) addTapGestureToMainView {
	UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeKeyboard)];
	[self addGestureRecognizer:tap];
}

-(void) doneButtonPressed {
    if([self.textAndImageView.textView.text isEqualToString:@""]){
        //remove text view from screen
        [self.textAndImageView showText:NO];
    }
	[self removeKeyboard];
}

-(void) removeKeyboard {
    //if the keyboard is up then remove it
    if(self.textAndImageView.textView.isFirstResponder){
        [self.textAndImageView.textView resignFirstResponder];
    }
    [self.delegate textDoneEditing];
}
//called before removing the view
//clears up video content
//saves pinchview content as well
-(void)exitingECV{
    [self updatePinchView];
    if(self.videoView)[self.videoView stopVideo];
    
    if([self.pinchView isKindOfClass:[SingleMediaAndTextPinchView class]]){
        ((SingleMediaAndTextPinchView *)self.pinchView).text = self.textAndImageView.textView.text;
        NSNumber * yoffset = [NSNumber numberWithFloat:self.textAndImageView.textView.frame.origin.y];
        ((SingleMediaAndTextPinchView *)self.pinchView).textYPosition = yoffset;
    }
    
}

//updates the content in the pinchview after things are changed
-(void)updatePinchView{
    //save pinchview content
    if([self.pinchView isKindOfClass:[ImagePinchView class]]){
        [((ImagePinchView *)self.pinchView) changeImageToFilterIndex:self.imageIndex];
    }
}

#pragma maro -Adjust textview position-

-(void) addPanGesture {
    UIPanGestureRecognizer * panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
	panGesture.minimumNumberOfTouches = 1;
	panGesture.maximumNumberOfTouches = 1;
    [self addGestureRecognizer:panGesture];
    [self.povViewMasterScrollView.panGestureRecognizer requireGestureRecognizerToFail:panGesture];
    self.povViewMasterScrollView.panGestureRecognizer.delegate = self;
    panGesture.delegate = self;
    
    UIPanGestureRecognizer * textViewpanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanTextView:)];
    textViewpanGesture.minimumNumberOfTouches = 1;
    textViewpanGesture.maximumNumberOfTouches = 1;
    [self.textAndImageView.textView addGestureRecognizer:textViewpanGesture];
}

-(void) didPan:(UIGestureRecognizer *) sender{
        switch (sender.state) {
            case UIGestureRecognizerStateBegan:
				if (sender.numberOfTouches < 1) return;
                self.panStartLocation = [sender locationOfTouch:0 inView:self];
//                if(self.textAndImageView.textView.isFirstResponder) {
//					[self removeKeyboard];
//				}
                self.gestureActionJustStarted = YES;
                break;
            case UIGestureRecognizerStateChanged:{
				if (sender.numberOfTouches < 1) return;
				CGPoint location = [sender locationOfTouch:0 inView:self];
                if(self.gestureActionJustStarted){
                    [self checkGestureDirection: location];
                    self.gestureActionJustStarted = NO;
                }
                
                if(self.isHorizontalPan && !self.filterSwitched ) {
					float horizontalDiff = location.x - self.panStartLocation.x;
					self.horizontalPanDistance += horizontalDiff;
                    //checks if the horizontal pan gone long enough for a "swipe" to change filter
                    if((fabs(self.horizontalPanDistance) >= HORIZONTAL_PAN_FILTER_SWITCH_DISTANCE)){
                        if(self.horizontalPanDistance < 0){
                            [self changeFilteredImageLeft];
                        }else{
                            [self changeFilteredImageRight];
                        }
                        self.filterSwitched = YES;
                    }
                    
                }
                
                self.panStartLocation = location;
                break;
            }
            case UIGestureRecognizerStateCancelled:
            case UIGestureRecognizerStateEnded: {
				self.horizontalPanDistance = 0.f;
                self.isHorizontalPan = NO;
                self.filterSwitched = NO;
                break;
			}
            default:
                break;
        }
}



-(void) didPanTextView:(UIGestureRecognizer *) sender{
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            
            if (sender.numberOfTouches < 1) return;
            self.textViewPanStartLocation = [sender locationOfTouch:0 inView:self.textAndImageView];
            self.gestureActionJustStarted = YES;
            
            break;
            
        case UIGestureRecognizerStateChanged:{
            CGPoint location = [sender locationOfTouch:0 inView:self.textAndImageView];
            CGFloat verticalDiff = location.y - self.textViewPanStartLocation.y;
            
            if([self textViewTranslationInBounds:verticalDiff]){
                
                
                CGRect newTVFrame = CGRectOffset(self.textAndImageView.textView.frame, 0, verticalDiff);

                if((newTVFrame.origin.y + newTVFrame.size.height) <
                   (self.textAndImageView.frame.size.height - ((CIRCLE_RADIUS)*2))){
                    self.textAndImageView.textView.frame = newTVFrame;
                }

            }
            self.textViewPanStartLocation = location;
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            break;
        }
        default:
            break;
    }
}





#pragma mark - Gesture Recognizer Delegate methods -

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return !self.isHorizontalPan;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    if (gestureRecognizer == self.povViewMasterScrollView.panGestureRecognizer){
        return YES;
    }
    return NO;
}


// set if gesture is horizontal or not (vertical)
-(void) checkGestureDirection: (CGPoint) location {
	self.isHorizontalPan = ((fabs(location.y - self.panStartLocation.y) < fabs(location.x - self.panStartLocation.x))
							&& fabs(location.y - self.panStartLocation.y) <= DIAGONAL_THRESHOLD); //prevent diagonal swipes
}

// check if the text view move is legal (within bounds)
-(BOOL)textViewTranslationInBounds:(CGFloat) diff{
    return ((self.textAndImageView.textView.frame.origin.y + diff) > 0.f) &&
            ((self.textAndImageView.textView.frame.origin.y + self.textAndImageView.textView.frame.size.height + diff) <
            self.frame.size.height);
}

// check if the touch is on the text view
-(BOOL) touchInTextViewBounds:(CGPoint) touch {
        return (touch.y > self.textAndImageView.textView.frame.origin.y - TOUCH_BUFFER &&
                touch.y < self.textAndImageView.textView.frame.origin.y +
				self.textAndImageView.textView.frame.size.height + TOUCH_BUFFER);
}



-(void)offScreen{
    [self.videoView stopVideo];
    self.hasBeenSetUp = NO;
}

-(void)onScreen {
    if(!self.hasBeenSetUp){
        [self.videoView prepareVideoFromArray:self.videoAssets];
        [self.videoView playVideo];
    }else{
        [self.videoView playVideo];
        self.hasBeenSetUp = YES;
    }
}

-(void)almostOnScreen{
    if(self.videoAssets){
        [self.videoView stopVideo];
        [self.videoView prepareVideoFromArray:self.videoAssets];
    }
    self.hasBeenSetUp = YES;
}


#pragma mark - Lazy Instantiation -


-(UIButton *)textCreationButton{
    if(!_textCreationButton){
        _textCreationButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width -  EXIT_CV_BUTTON_WALL_OFFSET -
                                                                         EXIT_CV_BUTTON_WIDTH,
                                                                         self.frame.size.height - EXIT_CV_BUTTON_WIDTH -
                                                                         EXIT_CV_BUTTON_WALL_OFFSET,
                                                                         EXIT_CV_BUTTON_WIDTH,
                                                                         EXIT_CV_BUTTON_WIDTH)];
    }
    return _textCreationButton;
}

@end
