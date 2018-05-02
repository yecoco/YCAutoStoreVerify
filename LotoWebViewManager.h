//
//  LotoWebViewManager.h
//  TweakHeader
//
//  Created by yecongcong on 2017/7/19.
//  Copyright © 2017年 lotogram. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppStoreHeader.h"

@interface LotoWebViewManager : NSObject
+ (LotoWebViewManager *)sharedInstance;
@property (nonatomic, strong) SUWebViewController *webVC;
@end
