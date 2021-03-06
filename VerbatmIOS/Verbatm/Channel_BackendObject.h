//
//  Channel_BackendObject.h
//  Verbatm
//
//  Created by Iain Usiri on 1/27/16.
//  Copyright © 2016 Verbatm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/PFUser.h>
@class Channel;

@interface Channel_BackendObject : NSObject

+(void)createChannelWithName:(NSString *)channelName andCompletionBlock:(void(^)(PFObject *))block;

//this will return null of the channel already exists
//will return the newly created channel otherwise
-(void) createPostFromPinchViews: (NSArray*) pinchViews toChannel: (Channel *) channel
			 withCompletionBlock:(void(^)(PFObject *))block;

//takes a completion block that will be called with
//an nsarray of the channels
+ (void) getChannelsForUser:(PFUser *) user withCompletionBlock:(void(^)(NSMutableArray *))completionBlock;

+ (void) getChannelsForFollowers:(Channel*)channel withCompletionBlock:(void(^)(NSArray *))completionBlock;

// NOT IN USE
+ (void) getAllChannelsWithCompletionBlock:(void(^)(NSMutableArray *))completionBlock;

+(void)storeCoverPhoto:(UIImage *) coverPhoto withParseChannelObject:(PFObject *) channel;

+ (void) updateLatestPostDateForChannel:(PFObject*)channel;

+(NSArray*) channelsFromParseChannelObjects:(NSArray*)parseChannels;
@end
