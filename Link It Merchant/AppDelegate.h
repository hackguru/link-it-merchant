//
//  AppDelegate.h
//  Link It Merchant
//
//  Created by Edward Rezaimehr on 2/4/15.
//  Copyright (c) 2015 Edward Rezaimehr. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kUpdateRegIdUrl @"http://api.linkmy.photos/users/updateRegId"
#define kMostRecentNotificationForPostKey @"notificationId"
//#define kUpdateRegIdUrl @"http://192.168.1.16:3000/users/updateRegId"

extern const NSString *NOTIFICATION_TOKEN_KEY;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end

