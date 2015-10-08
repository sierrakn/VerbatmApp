//
//  EditContentVC.m
//  Verbatm
//
//  Created by Iain Usiri on 9/12/15.
//  Copyright (c) 2015 Verbatm. All rights reserved.
//

#import "EditContentVC.h"
#import "ImagePinchView.h"
#import "SizesAndPositions.h"
#import "UserSetupParameters.h"
#import "VideoPinchView.h"
#import "SegueIDs.h"

@interface EditContentVC()<EditContentViewDelegate>
@property (strong, nonatomic) PinchView * openPinchView;
@property (strong, nonatomic) UIButton * exitButton;

#define DONE_IMAGE @"DoneIcon"
@end
@implementation EditContentVC

-(void)viewDidLoad {
    [self createEditContentViewFromPinchView:self.pinchView];
    [self createExitButton];
}

// This should never be called on a collection pinch view, only on text, image, or video
-(void) createEditContentViewFromPinchView: (PinchView *) pinchView {
    self.openEditContentView = [[EditContentView alloc] initCustomViewWithFrame:self.view.bounds];
    self.openEditContentView.delegate = self;
    //adding text
    if(pinchView == nil) {
        [self.openEditContentView editText:@""];
    } else {
        if(pinchView.containsImage) {
            ImagePinchView* imagePinchView = (ImagePinchView*)pinchView;
            [self.openEditContentView displayImages:[imagePinchView filteredImages] atIndex:[imagePinchView filterImageIndex]];
            if(imagePinchView.textView)self.openEditContentView.textView = imagePinchView.textView;
        } else if(pinchView.containsVideo) {
            [self.openEditContentView displayVideo:[(VideoPinchView*)pinchView video]];
        } else {
            return;
        }
        self.openPinchView = pinchView;
    }
    [self.view addSubview:self.openEditContentView];
    if(![UserSetupParameters filter_InstructionShown] && [pinchView isKindOfClass:[ImagePinchView class]])[self alertAddFilter];
}

-(void)createExitButton{
    self.exitButton = [[UIButton alloc] initWithFrame:
                       CGRectMake(EXIT_CV_BUTTON_WALL_OFFSET, EXIT_CV_BUTTON_WALL_OFFSET,
                                  EXIT_CV_BUTTON_WIDTH, EXIT_CV_BUTTON_HEIGHT)];
    [self.exitButton setImage:[UIImage imageNamed:DONE_IMAGE] forState:UIControlStateNormal];
    [self.exitButton addTarget:self action:@selector(exitButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.exitButton];
    [self.view bringSubviewToFront:self.exitButton];
}

-(void)alertAddFilter {
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Swipe left to add a filter!" message:@"" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
    [UserSetupParameters set_filter_InstructionAsShown];
}

-(void)exitButtonClicked:(UIButton*) sender{
    [self exitViewController];
}

-(void)exitViewController{
    if (!self.openEditContentView) {
        return;
    }
    if(self.openPinchView.containsImage) {
        self.filterImageIndex =  [self.openEditContentView getFilteredImageIndex];
        //if there is a text view and it has text then we should save it. otherwise we get rid of any reference
        if(self.openEditContentView.textView && ![self.openEditContentView.textView.text isEqualToString:@""]){
            ((ImagePinchView *)self.openPinchView).textView = self.openEditContentView.textView;
        }else{
            ((ImagePinchView *)self.openPinchView).textView =  nil;
        }
    }
    
    [self performSegueWithIdentifier:UNWIND_SEGUE_EDIT_CONTENT_VIEW sender:self];
}


#pragma mark - Delegate Methods -
//Delegate method for EditContentView
-(void) exitEditContentView {

    [self exitViewController];
}

@end
