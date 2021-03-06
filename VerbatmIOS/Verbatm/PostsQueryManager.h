//
//  PostsQueryManager.h
//  Verbatm
//
//  Created by Sierra Kaplan-Nelson on 4/24/16.
//  Copyright © 2016 Verbatm. All rights reserved.
//
//	Manages downloading the posts in a channel, maintaining a cursor.

#import <Foundation/Foundation.h>

@interface PostsQueryManager : NSObject

-(instancetype) initInSmallMode:(BOOL)smallMode;

/* Loads posts in channel newer or equal to latest date
 If less than 3 posts are found, loads 3 older posts too
 (If latest date is nil, just loads oldest posts)
 */
-(void) loadPostsInChannel:(Channel*)channel withLatestDate:(NSDate*)date
	   withCompletionBlock:(void(^)(NSArray *))block;

// Loads posts older than the current oldest date
-(void) loadOlderPostsInChannel:(Channel*)channel withCompletionBlock:(void(^)(NSArray *))block;

// Finds all posts newer than latest date (if there are any) or if latest date is nil
// just finds newest posts
-(void) loadNewerPostsInChannel:(Channel *)channel withCompletionBlock:(void(^)(NSArray *))block;

// Loads newest posts in channel up to the given limit
+(void) getPostsInChannel:(Channel*)channel withLimit:(NSInteger)limit withCompletionBlock:(void(^)(NSArray *))block;

@end
