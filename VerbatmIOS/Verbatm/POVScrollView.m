//
//  POVScrollView.m
//  Verbatm
//
//  Created by Sierra Kaplan-Nelson on 12/2/15.
//  Copyright © 2015 Verbatm. All rights reserved.
//

#import "AVETypeAnalyzer.h"
#import "POV.h"
#import "POVView.h"
#import "POVScrollView.h"

@interface POVScrollView()

@end

@implementation POVScrollView

-(instancetype) initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		self.scrollEnabled = YES;
		self.pagingEnabled = YES;
		self.showsHorizontalScrollIndicator = NO;
		self.showsVerticalScrollIndicator = NO;
	}
	return self;
}

-(void) displayPOVs: (NSArray*)povs {
	AVETypeAnalyzer * analyzer = [[AVETypeAnalyzer alloc]init];

	CGFloat xPosition = 0.f;
	for (POV* pov in povs) {
		NSMutableArray* aves = [analyzer getAVESFromPinchViews:pov.pinchViews withFrame:self.bounds];
		POVView* povView = [[POVView alloc] initWithFrame:self.bounds andPOVInfo:nil];
		[povView renderAVES: aves];
		[povView scrollToPageAtIndex:0];
		[povView povOnScreen];
		[self addSubview: povView];
		xPosition += self.bounds.size.width;
	}
	self.contentSize = CGSizeMake(povs.count * self.bounds.size.width, 0.f);
}

-(void) clearPOVs {
	for (UIView* subview in self.subviews) {
		[subview removeFromSuperview];
	}
}

@end