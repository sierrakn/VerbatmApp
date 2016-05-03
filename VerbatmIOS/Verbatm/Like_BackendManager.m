//
//  Like_BackendManager.m
//  Verbatm
//
//  Created by Iain Usiri on 3/20/16.
//  Copyright © 2016 Verbatm. All rights reserved.
//

#import "Like_BackendManager.h"
#import "ParseBackendKeys.h"
#import <Parse/PFUser.h>
#import <Parse/PFQuery.h>
#import <Parse/PFCloud.h>
#import <Crashlytics/Crashlytics.h>

@implementation Like_BackendManager

+(void)currentUserLikePost:(PFObject *) postParseObject{

	[postParseObject incrementKey:POST_NUM_LIKES];
	[postParseObject saveInBackground];
	PFObject *newLikeObject = [PFObject objectWithClassName:LIKE_PFCLASS_KEY];
	[newLikeObject setObject:[PFUser currentUser]forKey:LIKE_USER_KEY];
	[newLikeObject setObject:postParseObject forKey:LIKE_POST_LIKED_KEY];
	[newLikeObject saveInBackground];

	[PFCloud callFunctionInBackground:@"sendPushToUser"
					   withParameters:@{@"recipientId": ((PFUser*)[postParseObject objectForKey:POST_ORIGINAL_CREATOR_KEY]).objectId, @"message": @"liked your post"}
								block:^(NSString *success, NSError *error) {
									if (!error) {
										NSLog(@"%@", success);
									} else {
										NSLog(@"Unable to send push notification: %@", error.localizedDescription);
										[[Crashlytics sharedInstance] recordError:error];
									}
								}];
}

+ (void)currentUserStopLikingPost:(PFObject *) postParseObject{

	[postParseObject incrementKey:POST_NUM_LIKES byAmount:[NSNumber numberWithInteger:-1]];
	[postParseObject saveInBackground];
	PFQuery * userChannelQuery = [PFQuery queryWithClassName:LIKE_PFCLASS_KEY];
	[userChannelQuery whereKey:LIKE_POST_LIKED_KEY equalTo:postParseObject];
	[userChannelQuery whereKey:LIKE_USER_KEY equalTo:[PFUser currentUser]];
	[userChannelQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects,
														 NSError * _Nullable error) {
		if(objects && !error) {
			if(objects.count){
				PFObject *likeObject = [objects firstObject];
				[likeObject deleteInBackground];
			}
		}
	}];
}

//tests to see if the logged in user likes this post
+(void)doesCurrentUserLikesPost:(PFObject *) postParseObject withCompletionBlock:(void(^)(bool))block {
    if(!postParseObject)return;
    //we just delete the Follow Object
    PFQuery * userChannelQuery = [PFQuery queryWithClassName:LIKE_PFCLASS_KEY];
    [userChannelQuery whereKey:LIKE_POST_LIKED_KEY equalTo:postParseObject];
    [userChannelQuery whereKey:LIKE_USER_KEY equalTo:[PFUser currentUser]];
    [userChannelQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects,
                                                         NSError * _Nullable error) {
        if(objects && !error) {
            if(objects.count >= 1)block(YES);
            else block(NO);
        }
    }];
}

+(AnyPromise *) numberOfLikesForPost:(PFObject*) postParseObject {
	AnyPromise *promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver  _Nonnull resolve) {
		PFQuery *numLikesQuery = [PFQuery queryWithClassName:LIKE_PFCLASS_KEY];
		[numLikesQuery whereKey:LIKE_POST_LIKED_KEY equalTo:postParseObject];
		[numLikesQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects,
														  NSError * _Nullable error) {
			if(objects && !error) {
				resolve ([NSNumber numberWithInteger:objects.count]);
				return;
			}
			resolve ([NSNumber numberWithInt: 0]);
		}];
	}];
	return promise;
}

+(void) deleteLikesForPost:(PFObject*) postParseObject withCompletionBlock:(void(^)(BOOL)) block {
	PFQuery *likesQuery = [PFQuery queryWithClassName:LIKE_PFCLASS_KEY];
	[likesQuery whereKey:LIKE_POST_LIKED_KEY equalTo:postParseObject];
	[likesQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects,
													NSError * _Nullable error) {
		if(objects && !error) {
			for (PFObject *likeObject in objects) {
				[likeObject deleteInBackground];
			}
			block (YES);
			return;
		}
		block (NO);
	}];
}

@end
