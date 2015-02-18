//
//  AppDelegate.m
//  Link It Merchant
//
//  Created by Edward Rezaimehr on 2/4/15.
//  Copyright (c) 2015 Edward Rezaimehr. All rights reserved.
//

#import "AppDelegate.h"
#import "NSData+Conversion.h"

NSString * NOTIFICATION_TOKEN_KEY=@"notificationToken";

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [NSHTTPCookieStorage sharedHTTPCookieStorage].cookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
    
    NSLog(@"Registering for push notifications...");
    #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            [[UIApplication sharedApplication] registerUserNotificationSettings:
             [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge |
                                                           UIRemoteNotificationTypeSound |
                                                           UIRemoteNotificationTypeAlert) categories:nil]];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        } else {
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(
                                                                                   UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
        }
    #else
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(
                                                                               UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    #endif
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [self sendDeviceTokenToServer:deviceToken.hexadecimalString];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Error registering for application %@", error);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)sendDeviceTokenToServer:(NSString *)devTokenstring{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Get the results out
    NSString *currentNotificationToken = [defaults stringForKey:NOTIFICATION_TOKEN_KEY];

    //We cannot update after cause the first time we get this its always going to be nil from setting store
    [defaults setObject:devTokenstring forKey:NOTIFICATION_TOKEN_KEY];
    [defaults synchronize]; // this method is optional

    if(currentNotificationToken != nil){
        NSURL *restURL = [NSURL URLWithString:kUpdateRegIdUrl];
        NSMutableURLRequest *restRequest = [NSMutableURLRequest requestWithURL:restURL];
        NSDictionary *jsonDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  devTokenstring, @"newRegId",
                                  nil];
        
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:&error];
        
        [restRequest setHTTPMethod:@"POST"];
        [restRequest setValue: @"application/json" forHTTPHeaderField: @"Accept"];
        [restRequest setValue: @"application/json; charset=utf-8" forHTTPHeaderField: @"content-type"];
        [restRequest setValue: currentNotificationToken forHTTPHeaderField:@"token"];
        [restRequest setValue: @"ios" forHTTPHeaderField: @"device"];
        [restRequest setValue: @"merchant" forHTTPHeaderField: @"userType"];
        [restRequest setHTTPBody: jsonData];

        [NSURLConnection sendAsynchronousRequest:restRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            //TODO: what to do?
            return;
        }];
    }
}


//TODO: failt to get notification token???


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler{
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:userInfo[@"postId"] forKey:kMostRecentNotificationForPostKey];
    [defaults synchronize];
}

@end
