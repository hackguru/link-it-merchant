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
#import "AppDelegate.h"

#define kPostedItemsUrl @"http://api.linkmy.photos/users/%@/postedMedias"
#define kSubmitMessageForProduct @"http://api.linkmy.photos/media/match/%@"
NSString * USER_ID_KEY=@"userIdKey";


@interface ViewController ()

@end

@implementation ViewController{
    NSMutableArray *items;
    NSURLConnection *currentConnection;
    NSMutableData *apiReturnData;
    UIGestureRecognizer *keyboardDismisser;
    BOOL _draggingView;
    NSString *toBeshownPostIdFromRemoteNotification;
    CGFloat headerHeight, footerHeight;
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
    _draggingView = NO;
    headerHeight = self.tableView.sectionHeaderHeight;
    footerHeight = self.tableView.sectionFooterHeight;
    self.tableView.sectionHeaderHeight = 0;
    self.tableView.sectionFooterHeight = 0;
}

- (void)dismissKeyboard:(UITapGestureRecognizer *) sender
{
    [self.view endEditing:YES];
    [self.tableView reloadData];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _draggingView = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    _draggingView = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSInteger pullingDetectFrom = 50;
    if (scrollView.contentOffset.y < -pullingDetectFrom) {
        //Pull Down
        if(_draggingView){
            _draggingView = NO;
            [self updateTopOfList];
        }
    } else if (scrollView.contentSize.height <= scrollView.frame.size.height && scrollView.contentOffset.y > pullingDetectFrom) {
        _draggingView = NO;
        //Pull Up
    } else if (scrollView.contentSize.height > scrollView.frame.size.height &&
               scrollView.contentSize.height-scrollView.frame.size.height-scrollView.contentOffset.y < -pullingDetectFrom) {
        _draggingView = NO;
        //Pull Up
    } else if (scrollView.contentOffset.y + scrollView.frame.size.height >= scrollView.contentSize.height - (pullingDetectFrom*8)) {
        // we are at the end
        [self getMoreForBottomOfList];
    }
}

- (void) newInstaPost
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString * newPost = [defaults stringForKey:kMostRecentNotificationForPostKey.copy];
    if(newPost != nil){
        toBeshownPostIdFromRemoteNotification = newPost;
        [defaults setObject:nil forKey:kMostRecentNotificationForPostKey];
        [defaults synchronize];
        [self updateTopOfList];
    }
}

- (void)updateTopOfList{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *currentUserId = [defaults stringForKey:USER_ID_KEY];
    
    if(currentUserId != nil){
        NSString *startDate =  nil;
        NSString *endDate =  nil;
        if(items.count){
            startDate = [items.firstObject valueForKey:@"created"];
        }
        [self loadContentForUser:currentUserId from:startDate to:endDate];
        self.tableView.sectionHeaderHeight = headerHeight;
        [self.tableView reloadData];
    }
}

- (void)getMoreForBottomOfList{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *currentUserId = [defaults stringForKey:USER_ID_KEY];
    
    if(currentUserId!=nil){
        NSString *startDate =  nil;
        NSString *endDate =  nil;
        if(items.count){
            endDate = [items.lastObject valueForKey:@"created"];
        }
        [self loadContentForUser:currentUserId from:startDate to:endDate];
        self.tableView.sectionFooterHeight = footerHeight;
        [self.tableView reloadData];
    }
}


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    if(items!= nil && items.count>0){
        // willRotateToInterfaceOrientation code goes here
        NSArray *indexes = [self.tableView indexPathsForVisibleRows];
        int index = floor(indexes.count / 2);
        NSIndexPath *currentIndexInTable = indexes[index];
        
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            // willAnimateRotationToInterfaceOrientation code goes here
            [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            // didRotateFromInterfaceOrientation goes here (nothing for now)
            CGFloat tableHeight = self.tableView.frame.size.height;
            CGFloat cellHeight = [self tableView:self.tableView estimatedHeightForRowAtIndexPath:currentIndexInTable];
            int cellNumberToGoToInViewRect = floor(tableHeight / cellHeight / 2);
            int cellToGoInTable = currentIndexInTable.row - cellNumberToGoToInViewRect;
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:cellToGoInTable
                                                                      inSection:currentIndexInTable.section]
                                  atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }];
    } else {
        [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *currentUserId = [defaults stringForKey:USER_ID_KEY];
    
    if(currentUserId == nil) {
        [self performSegueWithIdentifier:@"segueToSignupPage" sender:self];
    } else {
        NSString *startDate =  nil;
        NSString *endDate =  nil;
        if(items.count){
            startDate = [items.lastObject valueForKey:@"created"];
            endDate = [items.firstObject valueForKey:@"created"];
        }
        [self loadContentForUser:currentUserId from:startDate to:endDate];
        
        toBeshownPostIdFromRemoteNotification = [defaults stringForKey:kMostRecentNotificationForPostKey];
        if (toBeshownPostIdFromRemoteNotification != nil) {
            [defaults setObject:nil forKey:kMostRecentNotificationForPostKey];
            [defaults synchronize];
            [self updateTopOfList];
        } else {
            [defaults addObserver:self
                        forKeyPath:kMostRecentNotificationForPostKey
                           options:NSKeyValueObservingOptionNew
                           context:NULL];
            
        }
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == [NSUserDefaults standardUserDefaults] && [keyPath isEqualToString:kMostRecentNotificationForPostKey]) {
        [self newInstaPost];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object
                               change:change context:context];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) loadContentForUser:(NSString *) userId from:(NSString *) startDate to:(NSString *) endDate {
    
    NSURL *restURL = [NSURL URLWithString:[NSString stringWithFormat:kPostedItemsUrl, userId]];
    if(startDate != nil){
        restURL = [self URLByAppendingQueryStringKey:@"startDate" andValue:startDate forUrl:restURL];
    }
    if(endDate != nil){
        restURL = [self URLByAppendingQueryStringKey:@"endDate" andValue:endDate forUrl:restURL];
    }
    NSMutableURLRequest *restRequest = [NSMutableURLRequest requestWithURL:restURL];
    NSString *currentNotificationToken = self.getRegId;
    [restRequest setValue: currentNotificationToken forHTTPHeaderField: @"token"];
    [restRequest setValue: @"ios" forHTTPHeaderField: @"device"];
    [restRequest setValue: @"merchant" forHTTPHeaderField: @"userType"];

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
    if(items.count>0){
        return items.count;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = indexPath.row;
    if (items.count>0) {
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
    return [tableView dequeueReusableCellWithIdentifier:@"emptyTable" forIndexPath:indexPath];
}
-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    static NSString *CellIdentifier = @"loadingCell";
    UITableViewCell *headerView = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    return headerView;
}

-(UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    static NSString *CellIdentifier = @"loadingCell";
    UITableViewCell *footerView = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    return footerView;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (items.count>0) {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        if(indexPath.row == 0){
            return screenWidth/2 + 45;
        }
        return screenWidth/2 + 50;
    }
    return 300;
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
    
    if(items.count > 0){
        if(indexPath.row == 0){
            ((ListItem *)cell).topMargin.constant = 0;
        }else{
            ((ListItem *)cell).topMargin.constant = 5;
        }
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
    self.tableView.sectionHeaderHeight = 0;
    self.tableView.sectionFooterHeight = 0;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    currentConnection = nil;
    NSError *error;
    NSMutableDictionary *returnedDict = [NSJSONSerialization JSONObjectWithData:apiReturnData options:kNilOptions error:&error];
    
    if (error != nil) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        [self updateItemsWith:[returnedDict objectForKey:@"results"]];
        self.tableView.sectionHeaderHeight = 0;
        self.tableView.sectionFooterHeight = 0;
        [self.tableView reloadData];
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showProductLink"])
    {
        BrowserController *browser = [segue destinationViewController];
        NSDictionary *item;
        if([sender isKindOfClass:UIButton.class]){
            item = [items objectAtIndex:((UIButton *)sender).tag];
        } else {
            //coming from self
            item = [items objectAtIndex:[self getItemIndexById:toBeshownPostIdFromRemoteNotification]];
            toBeshownPostIdFromRemoteNotification = nil;
        }
        NSString *link = [item valueForKey:@"linkToProduct"];
        if(link == nil || [link isEqualToString:@""]){
            link = [[item valueForKey:@"owner"] valueForKey:@"website"];
        }
        if([link isEqualToString:@""]){
            link = nil;
        }
        NSString *imageId = [item valueForKey:@"_id"];
        NSString *instaImageUrl = [[[item valueForKey:@"images"] valueForKey:@"low_resolution"] valueForKey:@"url"];
        [browser setLink:link];
        [browser setImageId:imageId];
        [browser setInstaImageUrl:instaImageUrl];
    }
}

- (IBAction)gotToInsta:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"instagram://app"]];
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
            NSURL *restURL = [NSURL URLWithString:kUpdateRegIdUrl];
            NSMutableURLRequest *restRequest = [NSMutableURLRequest requestWithURL:restURL];
            [restRequest setHTTPMethod:@"POST"];
            [restRequest setValue: @"application/json" forHTTPHeaderField: @"Accept"];
            [restRequest setValue: @"application/json; charset=utf-8" forHTTPHeaderField: @"content-type"];
            [restRequest setValue: [defaults valueForKey:NOTIFICATION_TOKEN_KEY.copy] forHTTPHeaderField:@"token"];
            [restRequest setValue: @"ios" forHTTPHeaderField: @"device"];
            [restRequest setValue: @"merchant" forHTTPHeaderField: @"userType"];
            
            [NSURLConnection sendAsynchronousRequest:restRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                //TODO: what to do?
                return;
            }];
            
            items = nil;
            
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
    
    NSString *currentNotificationToken = self.getRegId;
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

- (NSString *)getRegId{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Get the results out
    NSString *currentNotificationToken = [defaults stringForKey:NOTIFICATION_TOKEN_KEY.copy];
    
    return currentNotificationToken;

}

- (NSURL *)URLByAppendingQueryStringKey:(NSString *)key andValue:(NSString *)value forUrl:(NSURL *)url{
    if (![key length] || ![value length]) {
        return url;
    }
    
    NSString *URLString = [[NSString alloc] initWithFormat:@"%@%@%@", [url absoluteString],
                           [url query] ? @"&" : @"?", [NSString stringWithFormat:@"%@=%@", [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],[value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    NSURL *theURL = [NSURL URLWithString:URLString];
    return theURL;
}

- (int)getItemIndexById:(NSString *)id{
    for(int i=0; i<items.count; i++){
        if([[items[i] valueForKey:@"_id"] isEqualToString:id]){
            return i;
        }
    }
    return -1;
}

- (void) updateItemsWith:(NSArray *)newItems{
    if(items == nil){
        items = newItems.mutableCopy;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        return;
    }
    for(int i=0; i<newItems.count; i++){
        int currentIndex = [self getItemIndexById:[newItems[i] valueForKey:@"_id"]];
        if(currentIndex >= 0){
            [items replaceObjectAtIndex:currentIndex withObject:newItems[i]];
        } else {
            [self insertIntoItemsSorted:newItems[i]];
        }
    }
}

- (void)insertIntoItemsSorted:(NSDictionary *)toAdd{
    for(int i=0; i<items.count; i++){
        if([items[i][@"created"] caseInsensitiveCompare:toAdd[@"created"]] == NSOrderedAscending){
            [items insertObject:toAdd atIndex:i];
            if (i==0){
                [self newItemsAddedToTheTop:toAdd];
            }
            return;
        }
    }
    [items addObject:toAdd];
}

-(void)newItemsAddedToTheTop:(NSDictionary *) newItem{
    if([newItem[@"_id"] isEqualToString:toBeshownPostIdFromRemoteNotification]){
        //TODO Move to the browser
        [self.tableView scrollsToTop];
        [self performSegueWithIdentifier:@"showProductLink" sender:self];
    }
}

-(void)viewDidDisappear:(BOOL)animated
{
    @try {
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:kMostRecentNotificationForPostKey];
    }
    @catch (NSException * __unused exception) {}
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField.text.length >= 46 && ![string isEqualToString:@""])
        return NO;
    return YES;
}

@end
