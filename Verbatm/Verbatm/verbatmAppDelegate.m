//
//  verbatmAppDelegate.m
//  Verbatm
//
//  Created by Iain Usiri on 8/14/14.
//  Copyright (c) 2014 Verbatm. All rights reserved.
//

#import "verbatmAppDelegate.h"
#import <Parse/Parse.h>
#import "UserPinchViews.h"
#import <AVFoundation/AVFoundation.h>


@implementation verbatmAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //verbatm's identifier
    [Parse setApplicationId:@"rzSvJWHhiN8KUnhDVXTlapJkJ4eCe3xAlmEscSK3"
                  clientKey:@"qmXzBTKKMNqm5A3eogopkL2ZY6SeKGcWah0zP9kk"];
    
    //when app is opened this tracks it in parse
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];

	[[UserPinchViews sharedInstance] loadPinchViewsFromUserDefaults];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application{
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
