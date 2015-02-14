//
//  ViewController.m
//  Link It Merchant
//
//  Created by Edward Rezaimehr on 2/4/15.
//  Copyright (c) 2015 Edward Rezaimehr. All rights reserved.
//

#import "ViewController.h"
#import "ListItem.h"
#import <SDWebImage/UIButton+WebCache.h>
#import "BrowserController.h"
#import "SignupController.h"

#define kPostedItemsUrl @"http://ec2-54-149-40-205.us-west-2.compute.amazonaws.com/users/%@/postedMedias"
#define kSubmitMessageForProduct @"http://ec2-54-149-40-205.us-west-2.compute.amazonaws.com/media/match/%@"
NSString * USER_ID_KEY=@"userIdKey";


@interface ViewController ()

@end

@implementation ViewController{
    NSMutableArray *items;
    NSURLConnection *currentConnection;
    NSMutableData *apiReturnData;
    UIGestureRecognizer *keyboardDismisser;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.tableView setRowHeight: UITableViewAutomaticDimension];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"linkit"]];
    [super viewDidLoad];
    keyboardDismisser = [[UITapGestureRecognizer alloc]
              initWithTarget:self action:@selector(dismissKeyboard:)];
    keyboardDismisser.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:keyboardDismisser];
}

- (void)dismissKeyboard:(UITapGestureRecognizer *) sender
{
    [self.view endEditing:YES];
    [self.tableView reloadData];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    // willRotateToInterfaceOrientation code goes here
    NSArray *indexes = [self.tableView indexPathsForVisibleRows];
    int index = floor(indexes.count / 2);
    NSIndexPath *currentIndexInTable = indexes[index];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // willAnimateRotationToInterfaceOrientation code goes here
        [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // didRotateFromInterfaceOrientation goes here (nothing for now)
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenHeight = screenRect.size.height;
        CGFloat cellHeight = [self tableView:self.tableView estimatedHeightForRowAtIndexPath:currentIndexInTable];
        int cellNumberToGoToInViewRect = floor(screenHeight / cellHeight / 2);
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndexInTable.row - cellNumberToGoToInViewRect
                                                              inSection:currentIndexInTable.section]
                          atScrollPosition:UITableViewScrollPositionTop animated:YES];
        
    }];
}

- (void)viewDidAppear:(BOOL)animated{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Get the results out
    NSString *currentUserId = [defaults stringForKey:USER_ID_KEY];
    
    if(currentUserId == nil) {
        [self performSegueWithIdentifier:@"segueToSignupPage" sender:self];
    } else {
        [self loadContentForUser:currentUserId];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) loadContentForUser:(NSString *) userId{
    NSURL *restURL = [NSURL URLWithString:[NSString stringWithFormat:kPostedItemsUrl, userId]];
    NSURLRequest *restRequest = [NSURLRequest requestWithURL:restURL];
    
    // we will want to cancel any current connections
    if(currentConnection)
    {
        [currentConnection cancel];
        currentConnection = nil;
        apiReturnData = nil;
    }
    
    currentConnection = [[NSURLConnection alloc]   initWithRequest:restRequest delegate:self];
    
    // If the connection was successful, create the data that will be returned.
    apiReturnData = [NSMutableData data];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = indexPath.row;
    NSString *identifier = @"posted-item";
    NSDictionary *item = [items objectAtIndex:index];
    ListItem *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    [cell.instaImage sd_setBackgroundImageWithURL:[NSURL URLWithString:[[[item valueForKey:@"images"] valueForKey:@"low_resolution"] valueForKey:@"url"]] forState:UIControlStateNormal
                       placeholderImage:[UIImage imageNamed:@"loading"]];
    NSString *linkSS = [item valueForKey:@"productLinkScreenshot"];
    if(linkSS != nil){
        [cell.productLinkImage sd_setBackgroundImageWithURL:[NSURL URLWithString:linkSS] forState:UIControlStateNormal
                                           placeholderImage:[UIImage imageNamed:@"loading"]];
    } else  {
        [cell.productLinkImage setBackgroundImage:[UIImage imageNamed:@"notLinked"] forState:UIControlStateNormal];
    }
    
    [cell.descriptionLabel setText:[item valueForKey:@"productDescription"]];
    [cell.descriptionLabel setTag: index];
    
    [cell.productLinkImage setTag: index];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    return screenWidth/2 + 40;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark - NSURLConnection Delegate

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse *)response {
    [apiReturnData setLength:0];
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    [apiReturnData appendData:data];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    NSLog(@"URL Connection Failed!");
    currentConnection = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    currentConnection = nil;
    NSError *error;
    NSMutableDictionary *returnedDict = [NSJSONSerialization JSONObjectWithData:apiReturnData options:kNilOptions error:&error];
    
    if (error != nil) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        items = [[returnedDict objectForKey:@"results"] mutableCopy];
        [self.tableView reloadData];
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showProductLink"])
    {
        BrowserController *browser = [segue destinationViewController];
        NSDictionary *item = [items objectAtIndex:((UIButton *)sender).tag];
        NSString *link = [item valueForKey:@"linkToProduct"];
        NSString *imageId = [item valueForKey:@"_id"];
        [browser setLink:link];
        [browser setImageId:imageId];
    }
}

- (IBAction)logout:(id)sender{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Logout"
                                                    message:@"Are you sure you want to logout?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
    [alert show];

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    switch(buttonIndex) {
        case 0: //"No" pressed
            //do something?
            break;
        case 1: //"Yes" pressed
            [defaults setObject:nil forKey:USER_ID_KEY.copy];
            NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
            
            NSArray *allCookies = [cookies cookies];
            
            for(NSHTTPCookie *cookie in allCookies) {
                if([[cookie domain] rangeOfString:@"instagram.com"].location != NSNotFound) {
                    [cookies deleteCookie:cookie];
                }
            }            [defaults synchronize];
            [self performSegueWithIdentifier:@"segueToSignupPage" sender:self];
            break;
    }
}

- (IBAction)saveMessage:(id)sender{
    UITextField *textField = (UITextField *)sender;
    textField.enabled = NO;
    NSDictionary *item = [items objectAtIndex:textField.tag];
    
    NSString *messageSubmitUrlString = [NSString stringWithFormat:kSubmitMessageForProduct, item[@"_id"]];
    NSString *messageSubmitUrl = [NSURL URLWithString:messageSubmitUrlString];
    NSDictionary *jsonDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                              textField.text, @"productDescription",
                              nil];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:&error];
    
    NSMutableURLRequest *requestForSubmittingUrl = [[NSMutableURLRequest alloc] init];
    [requestForSubmittingUrl setCachePolicy:NSURLRequestUseProtocolCachePolicy];
    [requestForSubmittingUrl setHTTPShouldHandleCookies:NO];
    [requestForSubmittingUrl setTimeoutInterval:30];
    [requestForSubmittingUrl setHTTPMethod:@"POST"];
    [requestForSubmittingUrl setURL:messageSubmitUrl];
    [requestForSubmittingUrl setValue: @"application/json" forHTTPHeaderField: @"Accept"];
    [requestForSubmittingUrl setValue: @"application/json; charset=utf-8" forHTTPHeaderField: @"content-type"];
    [requestForSubmittingUrl setHTTPBody: jsonData];
    
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
                                   textField.enabled = YES;
                                   if(statusCode != 200){
                                       //TODO
                                       [textField setText:@""];
                                       NSLog(@"%@", [error localizedDescription]);
                                   } else {
                                       NSDictionary *newItem = [item mutableCopy];
                                       [newItem setValue:textField.text forKey:@"productDescription"];
                                       [items replaceObjectAtIndex:textField.tag withObject:newItem];
                                   }
                               }
                           }
     ];

    
}


@end
