//
//  Commenting_BackendObject.m
//  Verbatm
//
//  Created by Iain Usiri on 8/16/16.
//  Copyright © 2016 Verbatm. All rights reserved.
//

#import <Crashlytics/Crashlytics.h>
#import "Commenting_BackendObject.h"
#import "Comment.h"

#import "Notification_BackendManager.h"
#import "Notifications.h"

#import "ParseBackendKeys.h"
#import <Parse/PFUser.h>
#import <Parse/PFQuery.h>
#import <Parse/PFRelation.h>

@implementation Commenting_BackendObject

+(void)getCommentsForObject:(PFObject *) postParseObject withCompletionBlock:(void(^)(NSArray *))block{
    
    PFQuery * commentQuery = [PFQuery queryWithClassName:COMMENT_PFCLASS_KEY];
    commentQuery.limit = 1000;
    [commentQuery whereKey:COMMENT_POSTCOMMENTED_KEY equalTo:postParseObject];
    [commentQuery orderByAscending:@"createdAt"];
    [commentQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects,
                                                  NSError * _Nullable error) {
        if(objects && !error) {
            NSMutableArray * finalComments = [[NSMutableArray alloc] initWithCapacity:objects.count];
            
            for(PFObject * parseComment in objects){
                [finalComments addObject:[[Comment alloc] initWithParseCommentObject:parseComment]];
            }
            block(finalComments);
            
        } else {
            block(nil);
        }
    }];
}


+(void)addUserToConversationList:(PFUser *)user toPost:(PFObject *)postParseObject{
    NSString * postOwnerId = [[postParseObject valueForKey:POST_ORIGINAL_CREATOR_KEY] objectId];
    if(![postOwnerId isEqualToString:[user objectId]]){
        //PFRelations don't store duplicates
        PFRelation * pageRelation = [postParseObject relationForKey:POST_COMMENTORS_PFRELATION];
        [pageRelation addObject:user];
        [postParseObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if(error) {
                [[Crashlytics sharedInstance] recordError:error];
            }
        }];
    }
}

+(void)sendNotificationToOtherCommentorsOfPost:(PFObject *)postParseObject{
    PFRelation * pageRelation = [postParseObject relationForKey:POST_COMMENTORS_PFRELATION];
    [[pageRelation query] findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for(PFUser * user in objects){
                [Notification_BackendManager createNotificationWithType:NotificationTypeCommentReply
														  receivingUser:user relevantPostObject:postParseObject];
            }
        }
    }];
}


+(void)storeComment:(NSString *) commentString forPost:(PFObject *) postParseObject{
    PFObject *newComment = [PFObject objectWithClassName:COMMENT_PFCLASS_KEY];
    [newComment setObject:[PFUser currentUser]forKey:COMMENT_USER_KEY];
    [newComment setObject:postParseObject forKey:COMMENT_POSTCOMMENTED_KEY];
    [newComment setObject:commentString forKey:COMMENT_STRING];
    
    // Will return error if comment already existed - ignore
    [newComment saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if(succeeded) {
            [postParseObject incrementKey:POST_NUM_COMMENTS];
            [postParseObject saveInBackground];
			[Commenting_BackendObject sendNotificationToOtherCommentorsOfPost:postParseObject];
			[Commenting_BackendObject addUserToConversationList:[PFUser currentUser] toPost:postParseObject];
            [Notification_BackendManager createNotificationWithType:NotificationTypeNewComment
													  receivingUser:[postParseObject valueForKey:POST_ORIGINAL_CREATOR_KEY]
												 relevantPostObject:postParseObject];
            [Commenting_BackendObject notifyNewCommentOnPost:postParseObject];
            
        }
    }];
}

+(void)deleteCommentObject:(PFObject *)comment{
        [comment deleteInBackground];
}

+(void)notifyNewCommentOnPost:(PFObject *)postParseObject{
    NSDictionary * userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:[postParseObject objectId],POST_COMMENTED_ON_NOTIFICATION_USERINFO_KEY,nil];
    
    NSNotification * notification = [[NSNotification alloc]initWithName:NOTIFICATION_NEW_COMMENT_USER object:nil userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}


@end
