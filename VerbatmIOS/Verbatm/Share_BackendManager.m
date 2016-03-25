//
//  Share_BackendManager.m
//  Verbatm
//
//  Created by Sierra Kaplan-Nelson on 3/24/16.
//  Copyright © 2016 Verbatm. All rights reserved.
//

#import "ParseBackendKeys.h"
#import <Parse/PFUser.h>
#import <Parse/PFQuery.h>

#import "Share_BackendManager.h"

/*
 CLASS_KEY @"ShareClass"
 #define SHARE_USER_KEY @"UserSharing"
 #define SHARE_POST_SHARED_KEY "PostShared"
 #define SHARE_TYPE "ShareType"
 #define SHARE_TYPE_REBLOG "ShareTypeReblog"
 #define SHARE_REBLOG_CHANNE
 */

@implementation Share_BackendManager

+(void) currentUserReblogPost: (PFObject *) postParseObject toChannel: (PFObject *) channelObject {
	[postParseObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
		if(succeeded){
			NSLog(@"Saved share relationship");
			PFObject *newShareObject = [PFObject objectWithClassName:SHARE_PFCLASS_KEY];
			[newShareObject setObject:[PFUser currentUser]forKey:SHARE_USER_KEY];
			[newShareObject setObject:postParseObject forKey:SHARE_POST_SHARED_KEY];
			[newShareObject setObject:SHARE_TYPE_REBLOG forKey:SHARE_TYPE];
			[newShareObject setObject:channelObject forKey:SHARE_REBLOG_CHANNEL];
			[newShareObject saveInBackground];
		}
	}];
}

+(void) currentUserSharePost: (PFObject *) postParseObject {

	[postParseObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
		if(succeeded){
			NSLog(@"Saved share relationship");
			PFObject *newShareObject = [PFObject objectWithClassName:SHARE_PFCLASS_KEY];
			[newShareObject setObject:[PFUser currentUser]forKey:SHARE_USER_KEY];
			[newShareObject setObject:postParseObject forKey:SHARE_POST_SHARED_KEY];
			[newShareObject saveInBackground];
		}
	}];
}

//tests to see if the logged in user shared this post
+(void)currentUserSharedPost:(PFObject *) postParseObject withCompletionBlock:(void(^)(bool))block{
	if(!postParseObject)return;
	//we just delete the Follow Object
	PFQuery * userChannelQuery = [PFQuery queryWithClassName:LIKE_PFCLASS_KEY];
	[userChannelQuery whereKey:SHARE_POST_SHARED_KEY equalTo:postParseObject];
	[userChannelQuery whereKey:SHARE_USER_KEY equalTo:[PFUser currentUser]];
	[userChannelQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects,
														 NSError * _Nullable error) {
		if(objects && !error) {
			if(objects.count >= 1) block(YES);
			else block(NO);
		}
	}];
}

+(void) numberOfSharesForPost:(PFObject*) postParseObject withCompletionBlock:(void(^)(NSNumber*)) block {
	PFQuery *numSharesQuery = [PFQuery queryWithClassName:LIKE_PFCLASS_KEY];
	[numSharesQuery whereKey:SHARE_POST_SHARED_KEY equalTo:postParseObject];
	[numSharesQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects,
													  NSError * _Nullable error) {
		if(objects && !error) {
			block ([NSNumber numberWithInteger:objects.count]);
			return;
		}
		block ([NSNumber numberWithInt: 0]);
	}];
}

@end