//
//  SBAutoVerifyEmailManager.h
//  TweakHeader
//
//  Created by yecongcong on 2017/7/17.
//  Copyright © 2017年 lotogram. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpringBoardHeader.h"
#import <objc/runtime.h>

@interface SBAutoVerifyEmailManager : NSObject
+ (SBAutoVerifyEmailManager *)sharedInstance;
- (void)writeLog:(NSString *)logString;
- (void)doContinue:(NSArray *)objectArray;
- (void)doCreate:(NSArray *)objectArray;
- (void)registerErrorDo;
- (void)openApplication;
- (void)randomVerifySerialNumber;
- (void)writeNewSerialNumber;
- (void)restartDo;

@property (nonatomic, assign) BOOL bAppStoreLive;
@property (nonatomic, assign) BOOL bOpenedAppStore;
@property (nonatomic, assign) BOOL bAutoCheck;
@property (nonatomic, assign) BOOL bShowAgree;

@end
