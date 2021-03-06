//
//  SharingLinkActionView.m
//  Verbatm
//
//  Created by Iain Usiri on 6/17/16.
//  Copyright © 2016 Verbatm. All rights reserved.
//

#import "Durations.h"

#import "Icons.h"

#import "PublishingProgressManager.h"

#import "SharingLinkActionView.h"
#import "Styles.h"
#import "SizesAndPositions.h"

#import "VerbatmButton.h"
#import "UIImage+ImageEffectsAndTransforms.h"
@interface SharingLinkActionView ()<UITextViewDelegate>

@property (nonatomic) CGFloat ourOriginalHeight;

@property (nonatomic) UILabel * instructionsView;
@property (nonatomic) UILabel * subtextView;

@property (nonatomic) NSMutableArray * buttonList;
@property (nonatomic) NSMutableArray * selectedButtonImageList;
@property (nonatomic) NSMutableArray * unselectedButtonImageList;

@property (nonatomic) VerbatmButton * facebookButton;
@property (nonatomic) VerbatmButton * twitterButton;

@property (nonatomic) UIButton * continueButton;
@property (nonatomic) UIButton * cancelButton;

@property (nonatomic) UITextView * captionTextView;

@property (nonatomic) CGFloat numberOfSelectedButtons;

@property (nonatomic) UILabel * captionPrompt;


#define PUBLISH_WITHOUT_SHARING_MESSAGE @"Publish without sharing"
#define PUBLISH_AND_SHARE_MESSAGE @"Publish and share"
#define LABEL_TEXT @"Share"
#define SHARE_SUBTEXT_TEXT @"(you can share your post to Twitter)"
#define WALL_OFFSET_X 20.f
#define WALL_OFFSET_Y 5.f

#define CONTINUE_BUTTON_FLOOR_OFFSET (WALL_OFFSET_Y *2.f)

#define TEXT_LABEL_HEIGHT 30.f

#define CONTINUE_BUTTON_HEIGHT 40.f

#define SHARE_BUTTON_GAP 10.f

#define NUM_SHARE_BUTTONS 4.f

#define TEXT_VIEW_HEIGHT 125.f
@end


@implementation SharingLinkActionView


-(instancetype) initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    
    if(self){
        [self formatView];
        [self presentCommandText];
        [self setButtons];
        [self layoutButtonsToSelect];
    }
    
    return self;
}



-(void)handleCaptionEntryPresent:(BOOL)shouldPresent {
    [self shiftViewDown:shouldPresent];
//    if(shouldPresent){
//        [self.captionTextView becomeFirstResponder];
//    }else{
//        [self.captionTextView resignFirstResponder];
//    }
}


-(void) shiftViewDown:(BOOL) down{
    
    CGFloat newHeight = (down) ? TEXT_VIEW_HEIGHT : (-1 * TEXT_VIEW_HEIGHT);
    NSString * publishButtonTitle = (down) ?  PUBLISH_AND_SHARE_MESSAGE : PUBLISH_WITHOUT_SHARING_MESSAGE;
    [UIView animateWithDuration:SNAP_ANIMATION_DURATION animations:^{
        
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height + newHeight);
        
        self.captionTextView.frame = CGRectMake(self.captionTextView.frame.origin.x, self.captionTextView.frame.origin.y, self.captionTextView.frame.size.width, self.captionTextView.frame.size.height + newHeight);
        
        self.continueButton.frame = CGRectMake(self.continueButton.frame.origin.x, self.continueButton.frame.origin.y + newHeight, self.continueButton.frame.size.width, self.continueButton.frame.size.height);
        
        [self.continueButton  setAttributedTitle:[self getAttributeStringWithText:publishButtonTitle  andColor:[UIColor grayColor]] forState:UIControlStateNormal];
        
    }completion:^(BOOL finished) {
        if(finished){
            if([self.captionTextView.text isEqualToString:@""] && down) {
                [self addCaptionInstruction];
            }else{
                [self removeCaptionInstruction];
            }
        }
    }];
}

-(void)addCaptionInstruction{
    self.captionPrompt = [[UILabel alloc] init];
    CGRect frame = CGRectMake(self.captionTextView.frame.origin.x + WALL_OFFSET_Y, self.captionTextView.frame.origin.y + WALL_OFFSET_Y, self.captionTextView.frame.size.width, 20.f);
    [self.captionPrompt setFrame:frame];
    [self.captionPrompt setAttributedText:[[NSAttributedString alloc] initWithString:@"Add caption..." attributes:@{NSForegroundColorAttributeName:SPLV_LABEL_TEXT_COLOR,NSFontAttributeName: [UIFont fontWithName:LIGHT_ITALIC_FONT size:REPOST_BUTTON_TEXT_FONT_SIZE]}]];
    [self addSubview:self.captionPrompt];
    [self bringSubviewToFront:self.captionTextView];
}

-(void)removeCaptionInstruction{
    if(self.captionPrompt){
        [self.captionPrompt removeFromSuperview];
        self.captionPrompt = nil;
    }
}

- (void)textViewDidChange:(UITextView *)textView{
    if(![textView.text isEqualToString:@""]){
       [self removeCaptionInstruction];
    }else{
        if(!self.captionPrompt)[self addCaptionInstruction];
    }
}

-(void)formatView{
    self.layer.cornerRadius = STANDARD_VIEW_CORNER_RADIUS;
    [self setBackgroundColor:SPLV_BACKGROUND_COLOR];
}

-(void)setButtons{
    
    
    CGRect cancelButtonFrame = CGRectMake(WALL_OFFSET_X -5.f, WALL_OFFSET_Y, STATUS_BAR_HEIGHT - 5.f, STATUS_BAR_HEIGHT + 5.f);
    self.cancelButton = [[UIButton alloc] initWithFrame:cancelButtonFrame];
    [self.cancelButton setImage:[UIImage imageNamed:BACK_BUTTON_ICON] forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancelButtonSelected) forControlEvents:UIControlEventTouchDown];
    [self addSubview:self.cancelButton];
    [self bringSubviewToFront:self.cancelButton];
    
    CGRect continueButtonFrame = CGRectMake(WALL_OFFSET_X, self.frame.size.height - (CONTINUE_BUTTON_HEIGHT  + CONTINUE_BUTTON_FLOOR_OFFSET), self.frame.size.width - (WALL_OFFSET_X *2), CONTINUE_BUTTON_HEIGHT);
    
    self.continueButton = [self getButtonWithFrame:continueButtonFrame andTitleText:PUBLISH_WITHOUT_SHARING_MESSAGE];
    
    self.continueButton = [self getButtonWithFrame:continueButtonFrame andTitleText:@"Publish without Sharing"];
    [self addSubview:self.continueButton];
    [self bringSubviewToFront:self.continueButton];
    [self.continueButton addTarget:self action:@selector(continueButtonSelected) forControlEvents:UIControlEventTouchUpInside];
    

}

-(UIButton *)getButtonWithFrame:(CGRect) newFrame andTitleText:(NSString *) title{
    //create share button
    
    UIButton * button =  [[UIButton alloc] initWithFrame:newFrame];
    [button setAttributedTitle:[self getAttributeStringWithText:title  andColor:[UIColor grayColor]] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage makeImageWithColorAndSize:[UIColor clearColor] andSize:newFrame.size]
                                   forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage makeImageWithColorAndSize:[UIColor whiteColor] andSize:newFrame.size]
                                   forState:UIControlStateHighlighted];
    
    button.layer.cornerRadius = 4.f;
    button.clipsToBounds = YES;
    button.layer.borderWidth = 1.f;
    button.layer.borderColor = [UIColor blackColor].CGColor;
    
    return button;
}

-(void)presentCommandText{
    
    CGRect instructionFrame = CGRectMake(WALL_OFFSET_X, WALL_OFFSET_Y, self.frame.size.width - (WALL_OFFSET_X*2), TEXT_LABEL_HEIGHT);
    
    self.instructionsView = [[UILabel alloc] initWithFrame:instructionFrame];
    self.instructionsView.textAlignment = NSTextAlignmentCenter;
    [self.instructionsView setUserInteractionEnabled:NO];
    [self.instructionsView setAttributedText:[self getTitleAttributeStringWithText:LABEL_TEXT andColor:[UIColor blackColor]]];
    [self addSubview:self.instructionsView];
    
    CGRect subtextFrame = CGRectMake(WALL_OFFSET_X, instructionFrame.origin.y + instructionFrame.size.height, self.frame.size.width - (WALL_OFFSET_X*2), TEXT_LABEL_HEIGHT);
    self.subtextView = [[UILabel alloc] initWithFrame:subtextFrame];
	self.subtextView.adjustsFontSizeToFitWidth = YES;
    self.subtextView.textAlignment = NSTextAlignmentCenter;
    [self.subtextView setAttributedText:[self getAttributeStringWithText:SHARE_SUBTEXT_TEXT andColor:SPLV_LABEL_TEXT_COLOR]];
    [self addSubview:self.subtextView];
}

-(NSAttributedString *)getTitleAttributeStringWithText:(NSString *)text andColor:(UIColor *)color{
    return [[NSAttributedString alloc] initWithString:text attributes:@{NSForegroundColorAttributeName:color,NSFontAttributeName: [UIFont fontWithName:BOLD_FONT size:INFO_LIST_HEADER_FONT_SIZE]}];
}

-(NSAttributedString *)getAttributeStringWithText:(NSString *)text andColor:(UIColor *)color{
    return [[NSAttributedString alloc] initWithString:text attributes:@{NSForegroundColorAttributeName:color,NSFontAttributeName: [UIFont fontWithName:BOLD_FONT size:REPOST_BUTTON_TEXT_FONT_SIZE]}];
}


-(void)layoutButtonsToSelect{
    
    
    CGFloat totalHeightToLayoutButton = self.continueButton.frame.origin.y - (self.subtextView.frame.origin.y + self.subtextView.frame.size.height);
    CGFloat buttonWidthHeight = (self.frame.size.width - (WALL_OFFSET_X*2) - ((NUM_SHARE_BUTTONS -1) * SHARE_BUTTON_GAP))/NUM_SHARE_BUTTONS;
    
    if(buttonWidthHeight > totalHeightToLayoutButton){
        buttonWidthHeight = totalHeightToLayoutButton - SHARE_BUTTON_GAP;
    }
    
    
   self.facebookButton = [[VerbatmButton alloc] initWithFrame:CGRectMake((self.frame.size.width/2) - (buttonWidthHeight + SHARE_BUTTON_GAP), (self.frame.size.height - buttonWidthHeight)/2 , buttonWidthHeight, buttonWidthHeight)];
    
    [self.facebookButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.facebookButton storeBackgroundImage:[UIImage imageNamed:@"Facebook_unselected"] forState:ButtonNotSelected];
    [self.facebookButton storeBackgroundImage:[UIImage imageNamed:@"Facebook_selected"] forState:ButtonSelected];
    
    //[self addSubview:self.facebookButton];
    
    self.twitterButton = [[VerbatmButton alloc] initWithFrame:CGRectMake((self.frame.size.width - buttonWidthHeight)/2 , (self.frame.size.height - buttonWidthHeight)/2, buttonWidthHeight, buttonWidthHeight)];
    
    [self.twitterButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.twitterButton storeBackgroundImage:[UIImage imageNamed:@"Twitter_unselected"] forState:ButtonNotSelected];
    [self.twitterButton storeBackgroundImage:[UIImage imageNamed:@"Twitter_selected"] forState:ButtonSelected];
    
    [self addSubview:self.twitterButton];
    
    
}

- (void)buttonClicked:(VerbatmButton *)sender{
    
    if(sender.buttonInSelectedState == ButtonSelected){
        self.numberOfSelectedButtons --;
        if(self.numberOfSelectedButtons == 0.f)
            [self handleCaptionEntryPresent:NO];
    }else{
        self.numberOfSelectedButtons ++;
        if(self.numberOfSelectedButtons == 1.f)
            [self handleCaptionEntryPresent:YES];
    }
    
    [sender switchState];
    
}

-(void)cancelButtonSelected{
    [self.delegate cancelPublishing];
}

-(void)continueButtonSelected{
    //save caption for later use -- probably in publish manager
    if(self.numberOfSelectedButtons > 0){
        SelectedPlatformsToShareLink whereToShare = shareToTwitter;
        if(self.numberOfSelectedButtons == 1.f){
            if(self.facebookButton.buttonInSelectedState == ButtonSelected){
                whereToShare = shareToFacebook;
            }else{
                 whereToShare = shareToTwitter;
            }
        }else if (self.numberOfSelectedButtons == 2.f){
            whereToShare = bothFacebookAndTwitter;
        }
        [[PublishingProgressManager sharedInstance] storeLocationToShare:whereToShare withCaption:self.captionTextView.text];
    }
    
    [self.delegate continueToPublish];
    
}

-(UITextView *) captionTextView{
    if(!_captionTextView){
        _captionTextView = [[UITextView alloc] initWithFrame:CGRectMake(WALL_OFFSET_X, self.facebookButton.frame.origin.y + self.facebookButton.frame.size.height + SHARE_BUTTON_GAP, self.frame.size.width - (2* WALL_OFFSET_X), 0)];
        [_captionTextView setBackgroundColor:[UIColor clearColor]];
        _captionTextView.layer.cornerRadius = 1.f;
        _captionTextView.clipsToBounds = YES;
        _captionTextView.layer.borderWidth = 1.f;
        _captionTextView.layer.borderColor = [UIColor grayColor].CGColor;
        _captionTextView.delegate = self;
        [self addSubview:_captionTextView];
    }
    return _captionTextView;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
