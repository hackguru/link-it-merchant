//
//  BrowserController.m
//  Link It Merchant
//
//  Created by Edward Rezaimehr on 2/6/15.
//  Copyright (c) 2015 Edward Rezaimehr. All rights reserved.
//

#import "BrowserController.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import <SDWebImage/UIImageView+WebCache.h>

#define kSubmitScreenshotUrl @"http://ec2-54-149-40-205.us-west-2.compute.amazonaws.com/media/matchScreenShot/%@"
#define kSubmitUrlForProduct @"http://ec2-54-149-40-205.us-west-2.compute.amazonaws.com/media/match/%@"

@interface BrowserController ()

@end

@implementation BrowserController{
    UIViewController *cropController;
    NSTimer *progressBarTimer;
    bool isDoneLoadingAPage;
}

@synthesize webView = _webView;
@synthesize link = _link;
@synthesize urlTextField = _urlTextField;
@synthesize instaImageUrl = _instaImageUrl;
@synthesize toolBar = _toolBar;
@synthesize progressBar = _progressBar;
@synthesize imageId = _imageId;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    if(self.link != nil){
        [self loadRequestFromString: self.link];
    } else  {
        [self loadRequestFromString: @"http://www.google.com"];
    }
    UIImageView *instaImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 35,35)];
    [instaImage sd_setImageWithURL:[NSURL URLWithString:self.instaImageUrl] placeholderImage:[UIImage imageNamed:@"loading"]];
    UIBarButtonItem *instaImageButton =[[UIBarButtonItem alloc] initWithCustomView:instaImage];
    NSMutableArray *currentItems = self.toolBar.items.mutableCopy;
    [currentItems insertObject:instaImageButton atIndex:0];
    [self.toolBar setItems:currentItems];
    self.progressBar.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated{
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:kMostRecentNotificationForPostKey
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
}


-(void)viewDidDisappear:(BOOL)animated
{
    @try {
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:kMostRecentNotificationForPostKey];
    }
    @catch (NSException * __unused exception) {}
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadRequestFromString:(NSString*)urlString
{
    [self.urlTextField setText:urlString];
    NSURL *url = [NSURL URLWithString:urlString];
    if(!url.scheme)
    {
        NSString* modifiedURLString = [NSString stringWithFormat:@"http://%@", urlString];
        url = [NSURL URLWithString:modifiedURLString];
    }
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    
    [self.webView loadRequest:urlRequest];
}

- (IBAction)goBack:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)loadRequestFromAddressField:(id)addressField
{
    NSString *urlString = [addressField text];
    [self loadRequestFromString:urlString];
}

- (IBAction)capture:(id)sender
{
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        UIGraphicsBeginImageContextWithOptions(self.webView.bounds.size, NO, [UIScreen mainScreen].scale);
    else
        UIGraphicsBeginImageContext(self.webView.bounds.size);
    
    [self.webView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    PECropViewController *controller = [[PECropViewController alloc] init];
    controller.delegate = self;
    controller.image = image;
    
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    CGFloat length = MIN(width, height);
    controller.imageCropRect = CGRectMake((width - length) / 2,
                                          (height - length) / 2,
                                          length,
                                          length);
    controller.cropAspectRatio = 1.0;
    controller.keepingCropAspectRatio = YES;
    controller.toolbarHidden = YES;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self presentViewController:navigationController animated:YES completion:NULL];
}

#pragma mark - PECropViewControllerDelegate methods

- (void)cropViewControllerDidCancel:(PECropViewController *)controller
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//        [self updateEditButtonEnabled];
    }
    
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

- (void)cropViewController:(PECropViewController *)controller didFinishCroppingImage:(UIImage *)croppedImage
{
    cropController = controller;
    
    // the boundary string : a random string, that will not repeat in post data, to separate post data fields.
    NSString *boundary = @"----------V2ymHFg03ehbqgZCaKO6jy";

    // create request
    NSMutableURLRequest *screenshotSubmitRequest = [[NSMutableURLRequest alloc] init];
    [screenshotSubmitRequest setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [screenshotSubmitRequest setHTTPShouldHandleCookies:NO];
    [screenshotSubmitRequest setTimeoutInterval:30];
    [screenshotSubmitRequest setHTTPMethod:@"POST"];
    
    // set Content-Type in HTTP header
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [screenshotSubmitRequest setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    // post body
    NSMutableData *body = [NSMutableData data];
    
    // add image data
    NSData *imageData = UIImageJPEGRepresentation(croppedImage, 1.0);
    if (imageData) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name=\"upload\"; filename=\"ios-image.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:imageData];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // setting the body of the post to the reqeust
    [screenshotSubmitRequest setHTTPBody:body];
    
    // set the content-length
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
    [screenshotSubmitRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    //waiting for both calls to complete
    
    // set URL
    NSString *screenshotUrlString = [NSString stringWithFormat:kSubmitScreenshotUrl, self.imageId];
    NSURL* screenshotRequestURL = [NSURL URLWithString:screenshotUrlString];
    [screenshotSubmitRequest setURL:screenshotRequestURL];
   
    
    NSString *currentNotificationToken = self.getRegId;
    [screenshotSubmitRequest setValue: currentNotificationToken forHTTPHeaderField: @"token"];
    [screenshotSubmitRequest setValue: @"ios" forHTTPHeaderField: @"device"];
    [screenshotSubmitRequest setValue: @"merchant" forHTTPHeaderField: @"userType"];
    
    [NSURLConnection sendAsynchronousRequest:screenshotSubmitRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        //TODO : what if error?? - server not responding
        
        NSError *error;
        NSMutableDictionary *returnedDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        
        if (error != nil) {
            //TODO
            NSLog(@"%@", [error localizedDescription]);
        } else {
            int statusCode = [[returnedDict objectForKey:@"statusCode"] integerValue];
            if(statusCode == 200){
                // TODO : reset image to url
            } else {
                //TODO
                NSLog(@"%@", [error localizedDescription]);
            }
        }
        
    }];
    
    //also setting url!
    
    NSString *urlSubmitURLString = [NSString stringWithFormat:kSubmitUrlForProduct, self.imageId];
    NSString *urlSubmitURL = [NSURL URLWithString:urlSubmitURLString];
    NSDictionary *jsonDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                              self.urlTextField.text, @"linkToProduct",
                              nil];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:&error];
    
    NSMutableURLRequest *requestForSubmittingUrl = [[NSMutableURLRequest alloc] init];
    [requestForSubmittingUrl setCachePolicy:NSURLRequestUseProtocolCachePolicy];
    [requestForSubmittingUrl setHTTPShouldHandleCookies:NO];
    [requestForSubmittingUrl setTimeoutInterval:30];
    [requestForSubmittingUrl setHTTPMethod:@"POST"];
    [requestForSubmittingUrl setURL:urlSubmitURL];
    [requestForSubmittingUrl setValue: @"application/json" forHTTPHeaderField: @"Accept"];
    [requestForSubmittingUrl setValue: @"application/json; charset=utf-8" forHTTPHeaderField: @"content-type"];
    [requestForSubmittingUrl setHTTPBody: jsonData];

    [requestForSubmittingUrl setValue: currentNotificationToken forHTTPHeaderField: @"token"];
    [requestForSubmittingUrl setValue: @"ios" forHTTPHeaderField: @"device"];
    [requestForSubmittingUrl setValue: @"merchant" forHTTPHeaderField: @"userType"];

    [NSURLConnection sendAsynchronousRequest: requestForSubmittingUrl
                                       queue: [NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *error) {
                               NSError *jsonError;
                               NSMutableDictionary *returnedDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
                               
                               if (jsonError != nil) {
                                   //TODO
                                   NSLog(@"%@", [jsonError localizedDescription]);
                               } else {
                                   int statusCode = [[returnedDict objectForKey:@"statusCode"] integerValue];
                                   if(statusCode == 200){
                                       // TODO : reset image to url
                                   } else {
                                       //TODO
                                       NSLog(@"%@", [error localizedDescription]);
                                   }
                               }
                           }
     ];


    [[NSOperationQueue mainQueue] addObserver:self forKeyPath:@"operations" options:0 context:NULL];
    
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == [NSOperationQueue mainQueue] && [keyPath isEqualToString:@"operations"]) {
        if ([[NSOperationQueue mainQueue].operations count] == 0) {
            // Do something here when your queue has completed
            NSLog(@"queue has completed");
            [cropController dismissViewControllerAnimated:YES completion:NULL];
            [self dismissViewControllerAnimated:YES completion:nil];
            cropController = nil;
            @try {
                [object removeObserver:self forKeyPath:@"operations"];
            }
            @catch (NSException * __unused exception) {}
        }
    } else if (object == [NSUserDefaults standardUserDefaults] && [keyPath isEqualToString:kMostRecentNotificationForPostKey] && [[NSUserDefaults standardUserDefaults] valueForKey:kMostRecentNotificationForPostKey] != nil) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        @try{
            [super observeValueForKeyPath:keyPath ofObject:object
                                   change:change context:context];
        }
        @catch (NSException * __unused exception) {}
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    isDoneLoadingAPage = true;
    [self.urlTextField setText:webView.request.URL.absoluteString];
}

- (NSString *)getRegId{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Get the results out
    NSString *currentNotificationToken = [defaults stringForKey:NOTIFICATION_TOKEN_KEY.copy];
    
    return currentNotificationToken;
    
}

- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
   navigationType:(UIWebViewNavigationType)navigationType {
    if(self.progressBar.hidden){
        self.progressBar.hidden = false;
        self.progressBar.progress = 0;
        isDoneLoadingAPage = false;
        progressBarTimer = [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(timerCallback) userInfo:nil repeats:YES];
    }
    return YES;
}

-(void)timerCallback {
    if (isDoneLoadingAPage) {
        if (self.progressBar.progress >= 1) {
            self.progressBar.hidden = true;
            [progressBarTimer invalidate];
        }
        else {
            self.progressBar.progress += 0.1;
        }
    }
    else {
        self.progressBar.progress += 0.005;
        if (self.progressBar.progress >= 0.95) {
            self.progressBar.progress = 0.95;
        }
    }
}


@end
