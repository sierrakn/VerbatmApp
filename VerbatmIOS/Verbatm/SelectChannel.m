
//
//  SelectChannel.m
//  Verbatm
//
//  Created by Iain Usiri on 1/3/16.
//  Copyright © 2016 Verbatm. All rights reserved.
//


#import "Channel.h"

#import "SelectChannel.h"
#import "SelectOptionButton.h"
#import "SelectionView.h"


#define CHANNEL_LABEL_HEIGHT 70
#define WALL_OFFSET_X 30.f
#define WALL_OFFSET_Y 20.f

#define IMAGE_TEXT_SPACING 20.f
#define SELECTION_BUTTON_WIDTH 20.f

#define SCROLL_BUFFER 10.f //small buffer added to content size so there's room at the bottom

@interface SelectChannel ()

@property (nonatomic) NSMutableArray * selectedChannels;

@property (nonatomic) SelectOptionButton * selectedButton;
@property (nonatomic) BOOL canSelectMultipleChannels;


@end

@implementation SelectChannel
-(instancetype) initWithFrame:(CGRect)frame andChannels:(NSArray *) channels canSelectMultiple:(BOOL) selectMultiple{
    
    self = [super initWithFrame:frame];
    
    if(self){
        self.canSelectMultipleChannels = selectMultiple;
        [self createChannelLabels:channels];
    }
    
    return self;
}


-(void)formatView{
    self.scrollEnabled = YES;
    self.backgroundColor = [UIColor clearColor];
}


- (void) createChannelLabels:(NSArray *) channels {
    CGFloat startingYCord = 0.f;
    for(Channel * channel in channels){
        
        CGRect labelFrame = CGRectMake(0.f, startingYCord, self.frame.size.width, CHANNEL_LABEL_HEIGHT);
        UIView  * channelLabel = [self getChannelLabelWithFrame:labelFrame andChannel:channel];
        [self addSubview:channelLabel];
        startingYCord += CHANNEL_LABEL_HEIGHT;
    }
    
    CGSize newContentSize = CGSizeMake(0, startingYCord + CHANNEL_LABEL_HEIGHT + SCROLL_BUFFER);
    self.contentSize = newContentSize;
}


-(UIView *) getChannelLabelWithFrame:(CGRect) frame andChannel:(Channel *) channel{
    
    SelectionView * selectionBar = [[SelectionView alloc] initWithFrame:frame];
    
    CGFloat xCord = frame.size.width - WALL_OFFSET_X - SELECTION_BUTTON_WIDTH;
    CGFloat yCord =(frame.size.height/2.f) - (SELECTION_BUTTON_WIDTH/2.f);
    
    CGRect buttonFrame = CGRectMake( xCord, yCord,
                                    SELECTION_BUTTON_WIDTH, SELECTION_BUTTON_WIDTH);
    
    SelectOptionButton * selectOption = [[SelectOptionButton alloc] initWithFrame:buttonFrame];
    selectOption.associatedObject = channel;
    [selectOption addTarget:self action:@selector(channelButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    NSString * channelName = channel.name;
    CGRect labelFrame = CGRectMake(WALL_OFFSET_X, 0.f, xCord , frame.size.height);
    UILabel * newLabel = [[UILabel alloc] initWithFrame:labelFrame];
    [newLabel setText:channelName];
    [newLabel setTextColor:[UIColor whiteColor]];
    
    selectionBar.shareOptionButton = selectOption;

    [selectionBar addSubview:selectOption];
    [selectionBar addSubview:newLabel];
    
    [self addTapGestureToView:selectionBar];
    
    return selectionBar;
}

-(void)unselectAllOptions{
     [self.selectedButton setButtonSelected:NO];
}

-(void)addTapGestureToView:(UIView *) tapView{
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(optionSelectionMade:)];
    [tapView addGestureRecognizer:tap];
}


-(void)optionSelectionMade:(UITapGestureRecognizer *) gesture {
    SelectionView * selectedView = (SelectionView *) gesture.view;
    [self channelButtonSelected:selectedView.shareOptionButton];
}

-(void)channelButtonSelected:(UIButton *) button {
    SelectOptionButton * selectionButton = (SelectOptionButton *)button;
    if(self.canSelectMultipleChannels) {
        if([selectionButton buttonSelected]){//if it's already selected then remove it
            [selectionButton setButtonSelected:NO];
            [self.selectedChannels removeObject:selectionButton];
        }else{
            
            [self.selectedChannels addObject:selectionButton];
            [selectionButton setButtonSelected:YES];
            if([selectionButton.associatedObject isKindOfClass:[Channel class]]) {
                [self.delegate channelsSelected:self.selectedChannels];
            }
        }
    }else {
        if([selectionButton buttonSelected]){//if it's already selected then remove it
            [selectionButton setButtonSelected:NO];
        }else{
            if(self.selectedButton){//only one button can be selected at once
                [self.selectedButton setButtonSelected:NO];
            }
            self.selectedButton = selectionButton;
            [selectionButton setButtonSelected:YES];
            
            if([selectionButton.associatedObject isKindOfClass:[Channel class]]){
              [self.delegate channelsSelected:self.selectedChannels];
            }
        }
    }
}



-(NSMutableArray *) selectedChannels{
    if(!_selectedChannels){
        _selectedChannels = [[NSMutableArray alloc] init];
    }
    return _selectedChannels;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
