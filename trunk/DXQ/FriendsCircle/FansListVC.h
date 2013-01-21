//
//  FansListVC.h
//  DXQ
//
//  Created by Yuan on 12-10-20.
//  Copyright (c) 2012年 http://www.heyuan110.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserLoadFriendListRequest.h"

@interface FansListVC : BaseViewController{

    
    BOOL isUserLoadFriendListRequesting;
    
    NSString *accountID;
    
    UserLoadFriendListRequest *userLoadFriendListRequest;
}

-(id)initWithAccountID:(NSString *)accountID_;

@end
