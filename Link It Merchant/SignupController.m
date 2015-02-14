//
//  SignupController.m
//  Link It Merchant
//
//  Created by Edward Rezaimehr on 2/5/15.
//  Copyright (c) 2015 Edward Rezaimehr. All rights reserved.
//

#import "SignupController.h"
#import "AppDelegate.h"
#import "ViewController.h"

#define signupUrlUrl @"http://ec2-54-149-40-205.us-west-2.compute.amazonaws.com/users/auth/merchant/ios/%@"
#define getUserIdUrl @"http://ec2-54-149-40-205.us-west-2.compute.amazonaws.com/users/userId/merchant/ios/%@"
#define merchantLoggedInUrl @"http://ec2-54-149-40-205.us-west-2.compute.amazonaws.com/users/insta-merchant-cb"

@interface SignupController ()

@end

@implementation SignupController{
    NSString *currentNotificationToken;
}

@synthesize webView = _webView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Get the results out
    currentNotificationToken = [defaults stringForKey:NOTIFICATION_TOKEN_KEY.copy];
    
    if(currentNotificationToken != nil){
        [self loadRequestFromString: [NSString stringWithFormat:signupUrlUrl, currentNotificationToken]];
    } else {
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:NOTIFICATION_TOKEN_KEY.copy
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadRequestFromString:(NSString*)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    if(!url.scheme)
    {
        NSString* modifiedURLString = [NSString stringWithFormat:@"http://%@", urlString];
        url = [NSURL URLWithString:modifiedURLString];
    }
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:urlRequest];
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *currentURL = webView.request.URL.absoluteString;
    if([currentURL rangeOfString:merchantLoggedInUrl].location == 0){
        
        NSURL *restURL = [NSURL URLWithString:[NSString stringWithFormat:getUserIdUrl, currentNotificationToken]];
        NSURLRequest *restRequest = [NSURLRequest requestWithURL:restURL];
        [NSURLConnection sendAsynchronousRequest:restRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            //TODO : what if error?? - server not responding

            NSError *error;
            NSMutableDictionary *returnedDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];

            if (error != nil) {
                //TODO
                NSLog(@"%@", [error localizedDescription]);
            } else {
                NSString *userId = [returnedDict objectForKey:@"userId"];
                if(userId != nil){
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    [defaults setObject:userId forKey:USER_ID_KEY.copy];
                    [defaults synchronize]; // this method is optional
                    [self dismissViewControllerAnimated:YES completion:nil];
                } else {
                    //TODO
                    NSLog(@"%@", [error localizedDescription]);
                }
            }

        }];
        
    }
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == [NSUserDefaults standardUserDefaults] && [keyPath isEqualToString:NOTIFICATION_TOKEN_KEY.copy]) {
        if ([[NSOperationQueue mainQueue].operations count] == 0) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            
            // Get the results out
            currentNotificationToken = [defaults stringForKey:NOTIFICATION_TOKEN_KEY.copy];
            [self loadRequestFromString: [NSString stringWithFormat:signupUrlUrl, currentNotificationToken]];
            @try {
                [object removeObserver:self forKeyPath:NOTIFICATION_TOKEN_KEY.copy];
            }
            @catch (NSException * __unused exception) {}
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object
                               change:change context:context];
    }
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    //TODO: what if sign in fails??
}

@end
