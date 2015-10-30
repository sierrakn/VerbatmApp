//
//  userFeedCategorySwitch.m
//  Verbatm
//
//  Created by Iain Usiri on 8/28/15.
//  Copyright (c) 2015 Verbatm. All rights reserved.
//

#import "Durations.h"
#import "Icons.h"
#import "Styles.h"
#import "SwitchCategoryPullView.h"
#import "SizesAndPositions.h"

@interface SwitchCategoryPullView()

@property (strong, nonatomic) UILabel * trendingLabel;
@property (strong, nonatomic) UILabel * topicsLabel;
@property (nonatomic) CGFloat maxTrendingWidth;
@property (nonatomic) CGFloat leastPullCircleX;
@property (nonatomic) CGFloat maxPullCircleX;

//@property (nonatomic) CGRect topicsContainerInitialFrame;
//The circle icon that we move left/right to reveal the text
@property (strong, nonatomic) UIImageView * pullCircle;
@property (nonatomic) BOOL isRight;
@property (nonatomic) CGPoint lastPoint;//keeps the last recorded point of a touch on the pull circle

#define PULL_CIRCLE_SIZE (self.frame.size.height - CATEGORY_SWITCH_OFFSET*2)
#define TRENDING_LABEL_TEXT @"TRENDING"
#define TOPICS_LABEL_TEXT @"RECENT"
#define PULLCIRCLE_OFFSET 10

@end

@implementation SwitchCategoryPullView

- (id)initWithFrame:(CGRect)frame andBackgroundColor:(UIColor*)backgroundColor {
    
   self =  [super initWithFrame:frame];
    if(self){
        self.isRight = YES;
		[self setBackgroundColor:backgroundColor];
        [self initializeSubviews];
    }
    return self;
}


// The trending label is on a container view by itself
// The topics label is on a container view with the pull circle in order to cover the trending view when pulled
-(void) initializeSubviews {
	[self initLabelContainers];
	[self initPullCircle];
}

-(void) initLabelContainers {

	[self formatLabel: self.trendingLabel];
	self.trendingLabel.backgroundColor = self.backgroundColor;
	self.maxTrendingWidth = self.trendingLabel.frame.size.width;
	[self formatLabel: self.topicsLabel];

	self.leastPullCircleX = self.topicsLabel.frame.origin.x - PULL_CIRCLE_SIZE - PULLCIRCLE_OFFSET;
	if (self.leastPullCircleX < 0) { self.leastPullCircleX = PULLCIRCLE_OFFSET; }
	self.maxPullCircleX = self.trendingLabel.frame.origin.x + self.trendingLabel.frame.size.width + PULLCIRCLE_OFFSET;
	if (self.maxPullCircleX > self.frame.size.width - PULL_CIRCLE_SIZE) {
		self.maxPullCircleX = self.frame.size.width - PULL_CIRCLE_SIZE - PULLCIRCLE_OFFSET;
	}

	[self addSubview:self.topicsLabel];
	[self addSubview:self.trendingLabel];

	self.clipsToBounds = YES;
}

-(void) formatLabel: (UILabel*) label {
	label.font = [UIFont fontWithName:SWITCH_LABEL_FONT size:SWITCH_CATEGORY_BAR_FONT_SIZE];
	label.textAlignment = NSTextAlignmentCenter;
	label.lineBreakMode = NSLineBreakByClipping;

	CGRect expectedLabelSize = [label.text boundingRectWithSize: self.bounds.size
														options: NSStringDrawingUsesLineFragmentOrigin
													 attributes: @{NSFontAttributeName: label.font}
														context: nil];
	label.frame = CGRectMake(self.bounds.size.width/2.f - expectedLabelSize.size.width/2.f,
							 self.bounds.origin.y, expectedLabelSize.size.width, self.bounds.size.height);
}

//tbd - set the image for the pull circle
-(void) initPullCircle {
    self.pullCircle.frame = CGRectMake(self.maxPullCircleX, CATEGORY_SWITCH_OFFSET, PULL_CIRCLE_SIZE, PULL_CIRCLE_SIZE);
	self.pullCircle.image = [UIImage imageNamed: SWITCH_CATEGORY_CIRCLE_RIGHT];
	self.pullCircle.backgroundColor = self.backgroundColor;
    [self addPanGestureToView:self.pullCircle];
    [self addSubview: self.pullCircle];
}

-(void) addPanGestureToView: (UIView *) view {
    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pullCirclePan:)];
    pan.maximumNumberOfTouches = 1; //make sure it's only one finger
    pan.minimumNumberOfTouches = 1;
    view.userInteractionEnabled = YES;
    [view addGestureRecognizer:pan];
    
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pullCircleTap:)];
    [view addGestureRecognizer:tap];
}

//snap to the opposite side
-(void) pullCircleTap:(UITapGestureRecognizer *) sender {
	[self snapToEdgeLeft: (self.pullCircle.frame.origin.x + self.pullCircle.frame.size.width/2.f) < self.center.x ? NO : YES];
}

//Deals with pan gesture on circle
-(void) pullCirclePan:(UITapGestureRecognizer *) sender {
    
	    switch(sender.state) {
        case UIGestureRecognizerStateBegan: {
			if (sender.numberOfTouches < 1) return;
            self.lastPoint = [sender locationOfTouch:0 inView:self];
            break;
        }
        case UIGestureRecognizerStateChanged: {
			if (sender.numberOfTouches < 1) return;
            CGPoint touch = [sender locationOfTouch:0 inView:self];
			if (touch.y > self.pullCircle.frame.origin.y + self.pullCircle.frame.size.height) {
				return;
			}
            CGFloat newXOffset = touch.x - self.lastPoint.x;
            CGFloat newX = self.pullCircle.frame.origin.x + newXOffset;

            if (newX < self.leastPullCircleX) newX = self.leastPullCircleX;
            if (newX > self.maxPullCircleX) newX = self.maxPullCircleX;

			newXOffset = newX - self.pullCircle.frame.origin.x;
			self.pullCircle.frame = CGRectOffset(self.pullCircle.frame, newXOffset, 0);
			[self resizeTrendingLabel];

            self.lastPoint = touch;
			// notify delegate that we have panned our pullCircle
            [self.categorySwitchDelegate pullCircleDidPan:((newX - self.leastPullCircleX) / (self.maxPullCircleX - self.leastPullCircleX))];
            break;
        } case UIGestureRecognizerStateCancelled:
		case UIGestureRecognizerStateEnded: {
			[self snapToEdgeLeft: (self.pullCircle.frame.origin.x + self.pullCircle.frame.size.width/2.f) < self.center.x ? YES : NO];
            break;
        }
        default: {
            return;
        }
    }
}

-(void) resizeTrendingLabel {
	float newWidth = self.pullCircle.frame.origin.x - self.trendingLabel.frame.origin.x;
	if (newWidth < 0) { newWidth = 0; }
	if (newWidth > self.maxTrendingWidth) { newWidth = self.maxTrendingWidth; }

	self.trendingLabel.frame = CGRectMake(self.trendingLabel.frame.origin.x,
										  self.trendingLabel.frame.origin.y,
										  newWidth,
										  self.trendingLabel.frame.size.height);

}

//snaps the pull circle to an edge after a pan
-(void) snapToEdgeLeft: (BOOL) snapLeft {
	CGFloat newX;
	UIImage* pullCircleImage;
	if (snapLeft) {
		newX = self.leastPullCircleX;
		pullCircleImage = [UIImage imageNamed: SWITCH_CATEGORY_CIRCLE_LEFT];
	} else {
		newX = self.maxPullCircleX;
		pullCircleImage = [UIImage imageNamed: SWITCH_CATEGORY_CIRCLE_RIGHT];
	}

	[self.categorySwitchDelegate snapped: snapLeft];
	[UIView animateWithDuration:SNAP_ANIMATION_DURATION animations: ^ {
		self.pullCircle.frame = CGRectMake(newX,
														 self.pullCircle.frame.origin.y,
														 self.pullCircle.frame.size.width,
														 self.pullCircle.frame.size.height);
		[self resizeTrendingLabel];
        self.pullCircle.image = pullCircleImage;
	}];
}


#pragma mark - lazy instantiation -
-(UILabel *)trendingLabel {
    if(!_trendingLabel){
        _trendingLabel = [[UILabel alloc]init];
		_trendingLabel.text = TRENDING_LABEL_TEXT;
    }
    return _trendingLabel;
}

//for now topics is actually recent
-(UILabel *)topicsLabel{
    if(!_topicsLabel){
        _topicsLabel = [[UILabel alloc] init];
		_topicsLabel.text = TOPICS_LABEL_TEXT;
    }
    return _topicsLabel;
}

-(UIImageView *)pullCircle{
    if(!_pullCircle){
        _pullCircle =[[UIImageView alloc] init];
    }
    return _pullCircle;
}

@end
