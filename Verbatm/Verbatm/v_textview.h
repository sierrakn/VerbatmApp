//
//  v_textview.h
//  Verbatm
//
//  Created by Lucio Dery Jnr Mwinmaarong on 12/18/14.
//  Copyright (c) 2014 Verbatm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface v_textview : UITextView
-(void)setText:(NSString*)text;
-(void)setAttributedText:(NSMutableAttributedString*)text;

@end
