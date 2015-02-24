//
//  SignupController.h
//  Link It Merchant
//
//  Created by Edward Rezaimehr on 2/5/15.
//  Copyright (c) 2015 Edward Rezaimehr. All rights reserved.
//

#ifndef Link_It_Merchant_SignupController_h
#define Link_It_Merchant_SignupController_h

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface SignupController : UIViewController <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) MPMoviePlayerController *player;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UIButton *retryButton;

@end

#endif
