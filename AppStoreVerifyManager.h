//
//  AppStoreVerifyManager.h
//  TweakHeader
//
//  Created by yecongcong on 2017/7/17.
//  Copyright © 2017年 lotogram. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppStoreHeader.h"
#import "AppleAccount.h"
#import <objc/runtime.h>

@interface AppStoreVerifyManager : NSObject

+ (AppStoreVerifyManager *)sharedInstance;
- (void)writeLog:(NSString *)logString;
- (void)randomInfo:(NSString *)email password:(NSString *)password;
- (void)getUserFromServer:(void (^)(id responseObject, NSError *error))complete;
- (void)masterCardUser:(void (^)(id responseObject, NSError *error))complete;
- (void)verifyUser:(void (^)(id responseObject, NSError *error))complete;
- (void)checksignoutstatues;
- (void)writeAccountLog:(NSString *)errorMessage;
- (void)checksigninstatues;

@property (nonatomic, assign) BOOL bCheckSignout;
@property (nonatomic, strong) UIButton *appleIDButton;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, assign) NSInteger signoutcount;
@property (nonatomic, assign) AppleAccount *currentAccount;
@property (nonatomic, strong) UINavigationController *naviVC;
@property (nonatomic, strong) UITabBarController *tabBarVc;
@property (nonatomic, strong) SKUIAccountButtonsViewController *accountVC;
@property (nonatomic, assign) BOOL bNoVerifyAccount;
@property (nonatomic, assign) BOOL bCheckSignIn;
@property (nonatomic, assign) NSInteger signincount;

@end
