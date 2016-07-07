//
//  NotificationPostPreview.h
//  Verbatm
//
//  Created by Iain Usiri on 7/6/16.
//  Copyright © 2016 Verbatm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PostView.h"
#import <Parse/PFObject.h>

@protocol NotificationPostPreviewProtocol <NSObject>

-(void)exitPreview;

@end

@interface NotificationPostPreview : UIView
-(void)clearViews;
-(void)presentPost:(PFObject *) post andChannel:(Channel *) channel;
@property (nonatomic) id<NotificationPostPreviewProtocol> delegate;
@end