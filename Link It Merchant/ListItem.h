//
//  ListItem.h
//  Link It Merchant
//
//  Created by Edward Rezaimehr on 2/4/15.
//  Copyright (c) 2015 Edward Rezaimehr. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef Link_It_Merchant_ListItem_h
#define Link_It_Merchant_ListItem_h


@interface ListItem : UITableViewCell

@property (nonatomic, weak) IBOutlet UIButton *instaImage;
@property (nonatomic, weak) IBOutlet UIButton *productLinkImage;
@property (nonatomic, weak) IBOutlet UITextField *descriptionLabel;

@end


#endif
