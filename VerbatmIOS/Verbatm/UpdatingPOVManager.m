//
//  UpdatingManager.m
//  Verbatm
//
//  Created by Sierra Kaplan-Nelson on 9/16/15.
//  Copyright (c) 2015 Verbatm. All rights reserved.
//

#import "UpdatingPOVManager.h"
#import "GTLVerbatmAppPOV.h"
#import "GTLServiceVerbatmApp.h"
#import "GTMHTTPFetcherLogging.h"
#import "GTLQueryVerbatmApp.h"
#import "GTLVerbatmAppVerbatmUser.h"

#import "UserManager.h"

#import <PromiseKit/PromiseKit.h>

@interface UpdatingPOVManager()

@property(nonatomic, strong) GTLServiceVerbatmApp *service;

@end

@implementation UpdatingPOVManager


// Updates the like property of a POV. Unfortunately there's no
// more efficient way to do this than by getting the whole POV
// and then restoring it
- (void) povWithId: (NSNumber*) povID wasLiked: (BOOL) liked {
	UserManager* userManager = [UserManager sharedInstance];
	GTLVerbatmAppVerbatmUser* currentUser = [userManager getCurrentUser];
	NSArray* likedPOVIDs = currentUser.likedPOVIDs;
	NSMutableArray* updatedLikes = [[NSMutableArray alloc] initWithArray:likedPOVIDs copyItems:NO];
	[updatedLikes addObject: povID];
	currentUser.likedPOVIDs = updatedLikes;

	[self updateCurrentUser:currentUser].then(^(GTLVerbatmAppVerbatmUser* user) {
		//
	}).catch(^(NSError* error) {
//		NSLog(@"Error updating user: %@", error.description);
	});

	[self loadPOVWithID: povID].then(^(GTLVerbatmAppPOV* oldPOV) {
		long long newNumUpVotes = liked ? oldPOV.numUpVotes.longLongValue + 1 : oldPOV.numUpVotes.longLongValue - 1;
		oldPOV.numUpVotes = [NSNumber numberWithLongLong: newNumUpVotes];
		NSArray* usersWhoHaveLikedThisPOV = oldPOV.usersWhoHaveLikedIDs;
		NSMutableArray* updatedUsersWhoHaveLikedThisPOV = [[NSMutableArray alloc] initWithArray:usersWhoHaveLikedThisPOV copyItems:NO];
		[updatedUsersWhoHaveLikedThisPOV addObject: currentUser.identifier];
		oldPOV.usersWhoHaveLikedIDs = updatedUsersWhoHaveLikedThisPOV;
		return [self storePOV: oldPOV];
	}).then(^(GTLVerbatmAppPOV* newPOV) {
//		NSLog(@"Successfully updated pov \"%@\" 's number of upvotes to: %lld", newPOV.title, newPOV.numUpVotes.longLongValue);
	}).catch(^(NSError* error) {
//		NSLog(@"Error updating POV: %@", error.description);
	});
}

// Resolves to either an error or the POV with the given id
-(AnyPromise*) loadPOVWithID: (NSNumber*) povID {
	GTLQuery* loadPOVQuery = [GTLQueryVerbatmApp queryForPovGetPOVWithIdentifier: povID.longLongValue];

	AnyPromise* promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
		[self.service executeQuery: loadPOVQuery
				 completionHandler:^(GTLServiceTicket *ticket, GTLVerbatmAppPOV* pov, NSError *error) {
					 if (error) {
						 resolve(error);
					 } else {
						 resolve(pov);
					 }
				 }];
	}];
	return promise;
}

// Re inserts the given POV
-(AnyPromise*) storePOV: (GTLVerbatmAppPOV*) pov {
	GTLQuery* storePOVQuery = [GTLQueryVerbatmApp queryForPovUpdatePOVWithObject: pov];

	AnyPromise* promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
		[self.service executeQuery: storePOVQuery
				 completionHandler:^(GTLServiceTicket *ticket, GTLVerbatmAppPOV* pov, NSError *error) {
					 if (error) {
						 resolve(error);
					 } else {
						 resolve(pov);
					 }
				 }];
	}];
	return promise;
}

-(AnyPromise*) updateCurrentUser: (GTLVerbatmAppVerbatmUser*) currentUser {
	GTLQuery* updateUserQuery = [GTLQueryVerbatmApp queryForVerbatmuserUpdateUserWithObject: currentUser];

	AnyPromise* promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
		[self.service executeQuery: updateUserQuery
				 completionHandler:^(GTLServiceTicket *ticket, GTLVerbatmAppVerbatmUser* updatedUser, NSError *error) {
					 if (error) {
						 resolve(error);
					 } else {
						 resolve(updatedUser);
					 }
				 }];
	}];
	return promise;
}

#pragma mark - Lazy Instantiation -

- (GTLServiceVerbatmApp *)service {
	if (!_service) {
		_service = [[GTLServiceVerbatmApp alloc] init];

		_service.retryEnabled = YES;

		// Development only
		[GTMHTTPFetcher setLoggingEnabled:YES];
	}

	return _service;
}

@end
