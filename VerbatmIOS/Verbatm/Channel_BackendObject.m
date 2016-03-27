//
//  Channel_BackendObject.m
//  Verbatm
//
//  Created by Iain Usiri on 1/27/16.
//  Copyright © 2016 Verbatm. All rights reserved.
//

/*
 Manges creating channel objects and saving them as well as saving posts to channels
 */

#import "Channel_BackendObject.h"
#import "Channel.h"
#import "Post_BackendObject.h"
#import "ParseBackendKeys.h"
#import <Parse/PFQuery.h>
#import "UserManager.h"
#import "UserInfoCache.h"

@interface Channel_BackendObject ()
@property (nonatomic) NSMutableArray * ourPosts;
@end

@implementation Channel_BackendObject

-(instancetype)init{
	self = [super init];
	if(self){
		self.ourPosts = [[NSMutableArray alloc] init];
	}
	return self;
}

+(void)createChannelWithName:(NSString *)channelName andCompletionBlock:(void(^)(PFObject *))block {
	PFUser * ourUser = [PFUser currentUser];
	if(ourUser){
		PFObject * newChannelObject = [PFObject objectWithClassName:CHANNEL_PFCLASS_KEY];
		[newChannelObject setObject:channelName forKey:CHANNEL_NAME_KEY];
		[newChannelObject setObject:[PFUser currentUser] forKey:CHANNEL_CREATOR_KEY];
		[newChannelObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
			if(succeeded){
				block(newChannelObject);
			} else {
				block(nil);
			}
		}];
	} else {
		block (nil);
	}
}

//returns channel when we create a new one
-(void) createPostFromPinchViews: (NSArray*) pinchViews toChannel: (Channel *) channel
				  withCompletionBlock:(void(^)(PFObject *))block {
	if(channel.parseChannelObject){
		Post_BackendObject * newPost = [[Post_BackendObject alloc]init];
		[self.ourPosts addObject:newPost];
		PFObject *parsePostObject = [newPost createPostFromPinchViews:pinchViews toChannel:channel];
		block(parsePostObject);
	} else {
		[Channel_BackendObject createChannelWithName:channel.name andCompletionBlock:^(PFObject* channelObject){
			[channel addParseChannelObject:channelObject];
			Post_BackendObject * newPost = [[Post_BackendObject alloc]init];
			[self.ourPosts addObject:newPost];
			PFObject * parsePostObject = [newPost createPostFromPinchViews:pinchViews toChannel:channel];
			block(parsePostObject);
		}];
	}
}

+ (void) getChannelsForUser:(PFUser *) user withCompletionBlock:(void(^)(NSMutableArray *))completionBlock{
	if(user) {
		PFQuery * userChannelQuery = [PFQuery queryWithClassName:CHANNEL_PFCLASS_KEY];
		[userChannelQuery whereKey:CHANNEL_CREATOR_KEY equalTo:user];
		[userChannelQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects,
															 NSError * _Nullable error) {
			NSMutableArray * finalChannelObjects = [[NSMutableArray alloc] init];
			if(objects && !error){
				for(PFObject * parseChannelObject in objects){

					NSString * channelName  = [parseChannelObject valueForKey:CHANNEL_NAME_KEY];
					// get number of follows from follow objects
					Channel * verbatmChannelObject = [[Channel alloc] initWithChannelName:channelName andParseChannelObject:parseChannelObject];
					[finalChannelObjects addObject:verbatmChannelObject];
				}
			}
			completionBlock(finalChannelObjects);
		}];
	} else {
		completionBlock([[NSMutableArray alloc] init]);
	}
}

//gets all the channels on V except the provided user.
//often this will be the current user
+(void) getAllChannelsButNoneForUser:(PFUser *) user withCompletionBlock:(void(^)(NSMutableArray *))completionBlock{
	PFQuery * userChannelQuery = [PFQuery queryWithClassName:CHANNEL_PFCLASS_KEY];
	[userChannelQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
		if(objects.count){
			NSMutableArray * finalObjects = [[NSMutableArray alloc] init];
			for(PFObject * parseChannelObject in objects){
				if([parseChannelObject valueForKey:CHANNEL_CREATOR_KEY] !=
				   [PFUser currentUser]){
					NSString * channelName  = [parseChannelObject valueForKey:CHANNEL_NAME_KEY];
					Channel * verbatmChannelObject = [[Channel alloc] initWithChannelName:channelName
																	andParseChannelObject:parseChannelObject];
					[finalObjects addObject:verbatmChannelObject];
				}
			}
			completionBlock(finalObjects);
		}
	}];
}


//gets all channels on Verbatm including the current user
+(void) getAllChannelsWithCompletionBlock:(void(^)(NSMutableArray *))completionBlock{

}

@end
