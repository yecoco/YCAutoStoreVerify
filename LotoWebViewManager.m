//
//  LotoWebViewManager.m
//  TweakHeader
//
//  Created by yecongcong on 2017/7/19.
//  Copyright © 2017年 lotogram. All rights reserved.
//

#import "LotoWebViewManager.h"
#import "AppStoreVerifyManager.h"
#import "PTFakeMetaTouch.h"
#import <notify.h>

@interface LotoWebViewManager()
@property (nonatomic, assign) BOOL bInCreateEmail;
@property (nonatomic, assign) BOOL bInCreateInfo;
@property (nonatomic, assign) BOOL bInCreateAddress;
@property (nonatomic, assign) BOOL bInSelectCountry;
@property (nonatomic, assign) BOOL bInCheck;

@property (nonatomic, assign) int tapCount;
@property (nonatomic, assign) int tapTitleCount;
@end

@implementation LotoWebViewManager

+ (LotoWebViewManager *)sharedInstance
{
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[LotoWebViewManager alloc] init];
    });
    return _sharedInstance;
}

- (void)setWebVC:(SUWebViewController *)webVC
{
    if (_webVC == nil)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkWebStatus) object:nil];
        [self performSelector:@selector(checkWebStatus) withObject:nil afterDelay:5];
    }
    _webVC = webVC;
}

- (NSString *)randomPhoneNumber:(NSString *)oriphone
{
    NSUInteger steetNumberCount = [self occurrenceCountOfCharacter:'#' total:oriphone];
    double max = pow(10,steetNumberCount) - 1;
    double min = pow(10,(steetNumberCount - 1));
    NSInteger randoms = (arc4random() % ((NSInteger)max - (NSInteger)min + 1)) + (NSInteger)min;
    NSString *numberPhone = [NSString stringWithFormat:@"%ld",(long)randoms];
    NSString *replaceString = @"";
    for (int i=0; i<steetNumberCount; i++) {
        replaceString = [NSString stringWithFormat:@"%@#",replaceString];
    }
    return [oriphone stringByReplacingOccurrencesOfString:replaceString withString:numberPhone];
}

- (NSString *)randomStreet:(NSString *)oristreet
{
    NSUInteger steetNumberCount = [self occurrenceCountOfCharacter:'#' total:oristreet];
    double max = pow(10,steetNumberCount) - 1;
    double min = pow(10,(steetNumberCount - 1));
    NSInteger randoms = (arc4random() % ((NSInteger)max - (NSInteger)min + 1)) + (NSInteger)min;
    NSString *numberStreet = [NSString stringWithFormat:@"%ld",(long)randoms];
    NSString *replaceString = @"";
    for (int i=0; i<steetNumberCount; i++) {
        replaceString = [NSString stringWithFormat:@"%@#",replaceString];
    }
    return [oristreet stringByReplacingOccurrencesOfString:replaceString withString:numberStreet];
}

- (NSUInteger)occurrenceCountOfCharacter:(UniChar)character total:(NSString *)total
{
    CFStringRef selfAsCFStr = (__bridge CFStringRef)total;
    
    CFStringInlineBuffer inlineBuffer;
    CFIndex length = CFStringGetLength(selfAsCFStr);
    CFStringInitInlineBuffer(selfAsCFStr, &inlineBuffer, CFRangeMake(0, length));
    
    NSUInteger counter = 0;
    
    for (CFIndex i = 0; i < length; i++) {
        UniChar c = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, i);
        if (c == character) counter += 1;
    }
    
    return counter;
}

- (BOOL)bSuccessDoNext:(NSString *)source
{
    NSString *HTMLSource = nil;
    if (source == nil) {
        HTMLSource = [self.webVC.webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.innerHTML"];
    }
    else
        HTMLSource = source;
    if ([HTMLSource containsString:@"error-field has-error"] || [HTMLSource containsString:@"input-label has-error"]) {
        return NO;
    }
    return YES;
}

- (void)doSendNotify
{
    notify_post("com.lotogram.restartappstoredoverify");
}

- (void)bWebFailDoNext
{
    self.bInCheck = NO;
    // [self.webVC dismissViewControllerAnimated:YES completion:^{
    //     [self performSelector:@selector(doSendNotify) withObject:nil afterDelay:2];
    // }];
}

- (void)checkWebStatus
{
    self.bInCheck = YES;
    if (self.webVC == nil || self.webVC.webView == nil) {
        [self performSelector:@selector(checkWebStatus) withObject:nil afterDelay:5];
        return;
    }
    UIBarButtonItem *leftBtn = self.webVC.navigationItem.leftBarButtonItem;
    NSString *leftTitle = leftBtn.title;
    UIBarButtonItem *rightBtn = self.webVC.navigationItem.rightBarButtonItem;
    NSString *rightTitle = rightBtn.title;
    if ([leftTitle isEqualToString:@"Cancel"] && [rightTitle isEqualToString:@"Next"])
    {
        if (!self.bInCreateEmail)
        {
            self.bInCreateEmail = YES;
            [self createEmail];
            [self performSelector:@selector(checkWebStatus) withObject:nil afterDelay:5];
        }
        else
        {
            if (![self bSuccessDoNext:nil])
            {
                [[AppStoreVerifyManager sharedInstance] writeLog:@"--------CreateEmail error--------"];
                [self bWebFailDoNext];
            }
            else
            {
                [self performSelector:@selector(checkWebStatus) withObject:nil afterDelay:5];
            }
        }
    }
    else if([leftTitle isEqualToString:@"Back"] && rightBtn == nil)
    {
        if (!self.bInSelectCountry)
        {
            self.bInSelectCountry = YES;
            self.bInCreateEmail = NO;
            [self selectCountry];
            [self performSelector:@selector(checkWebStatus) withObject:nil afterDelay:5];
        }
        else
        {
            if (![self bSuccessDoNext:nil]) 
            {
                [[AppStoreVerifyManager sharedInstance] writeLog:@"--------select country error--------"];
                [self bWebFailDoNext];
            }
            else
            {
                [self performSelector:@selector(checkWebStatus) withObject:nil afterDelay:5];
            }
        }
    }
    else if ([leftTitle isEqualToString:@"Back"] && [rightTitle isEqualToString:@"Next"])
    {
        NSString *HTMLSource = [self.webVC.webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.innerHTML"];
        if ([HTMLSource containsString:@"PAYMENT METHOD"] && self.bInCreateInfo)
        {
            if (!self.bInCreateAddress)
            {
                self.bInCreateAddress = YES;
                [self selectNone];
                [self performSelector:@selector(checkWebStatus) withObject:nil afterDelay:5];
            }
            else
            {
                if (![self bSuccessDoNext:HTMLSource])
                {
                    [[AppStoreVerifyManager sharedInstance] writeLog:@"--------CreateAddress error--------"];
                    [self bWebFailDoNext];
                }
                else
                {
                    [self performSelector:@selector(checkWebStatus) withObject:nil afterDelay:5];
                }
            }
        }
        else if([HTMLSource containsString:@"PERSONAL INFORMATION"] && self.bInCreateEmail)
        {
            if (!self.bInCreateInfo)
            {
                self.bInCreateInfo = YES;
                [self performSelector:@selector(tapTitle) withObject:nil afterDelay:1];
                [self performSelector:@selector(checkWebStatus) withObject:nil afterDelay:5];
            }
            else
            {
                if (![self bSuccessDoNext:nil])
                {
                    [[AppStoreVerifyManager sharedInstance] writeLog:@"--------CreateInfo error--------"];
                    [self bWebFailDoNext];
                }
                else
                {
                    [self performSelector:@selector(checkWebStatus) withObject:nil afterDelay:5];
                }
            }
        }
        else
        {
            [self performSelector:@selector(checkWebStatus) withObject:nil afterDelay:5];
        }
    }
    else if(rightBtn == nil && leftBtn == nil && self.bInCreateAddress)
    {
        [self performSelector:@selector(completeDo) withObject:nil afterDelay:2];
    }
    else
    {
        [self performSelector:@selector(checkWebStatus) withObject:nil afterDelay:5];
    }
}

- (void)completeDo
{
    self.bInCheck = NO;
    [AppStoreVerifyManager sharedInstance].statusLabel.text = @"success register";
    [self.webVC.webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('button blue-ios-button')[0].click()"];
    [self performSelector:@selector(doSignout) withObject:nil afterDelay:2];
}

- (void)doSignout
{
    self.webVC = nil;
    self.tapCount = 0;
    self.tapTitleCount = 0;
    self.bInCreateEmail = NO;
    self.bInCreateInfo = NO;
    self.bInCreateAddress = NO;
    [[AppStoreVerifyManager sharedInstance] verifyUser:^(id responseObject, NSError *error) {
        NSString *status = [responseObject objectForKey:@"status"];
        if (error == nil && [status isEqualToString:@"ok"])
        {
            NSString *logString = @"success verifyUser";
            [[AppStoreVerifyManager sharedInstance] writeAccountLog:logString];
        }
        else if (error == nil)
        {
            NSString *logString = [NSString stringWithFormat:@"verifyUser fail %@",responseObject[@"message"]];
            [[AppStoreVerifyManager sharedInstance] writeAccountLog:logString];
        }
        else
        {
            NSString *logString = [NSString stringWithFormat:@"verifyUser fail %@",error.localizedDescription];
            [[AppStoreVerifyManager sharedInstance] writeAccountLog:logString];
        }
        [AppStoreVerifyManager sharedInstance].tabBarVc.selectedIndex = 0;
    }];
}

- (void)masterCardUser
{
    self.webVC = nil;
    self.tapCount = 0;
    self.tapTitleCount = 0;
    self.bInCreateEmail = NO;
    self.bInCreateInfo = NO;
    self.bInCreateAddress = NO;
    [[AppStoreVerifyManager sharedInstance] masterCardUser:^(id responseObject, NSError *error) {
        NSString *status = [responseObject objectForKey:@"status"];
        if (error == nil && [status isEqualToString:@"ok"])
        {
            NSString *logString = @"masterCard user success update";
            [[AppStoreVerifyManager sharedInstance] writeAccountLog:logString];
        }
        else if (error == nil)
        {
            NSString *logString = [NSString stringWithFormat:@"masterCardUser update fail %@",responseObject[@"message"]];
            [[AppStoreVerifyManager sharedInstance] writeAccountLog:logString];
        }
        else
        {
            NSString *logString = [NSString stringWithFormat:@"masterCardUser update  fail %@",error.localizedDescription];
            [[AppStoreVerifyManager sharedInstance] writeAccountLog:logString];
        }
        [self doSendNotify];
    }];
}

- (void)createEmail
{
    NSString *countryCode = [self.webVC.webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByName('iso3CountryCode')[0].value"];
    if ([countryCode isEqualToString:@"USA"])
    {
        [[AppStoreVerifyManager sharedInstance] writeLog:@"--------createEmail success US--------"];
        [AppStoreVerifyManager sharedInstance].statusLabel.text = @"createEmail success US...";
        [self.webVC.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('agreedToTerms').click()"];
        UIBarButtonItem *rightBtn = self.webVC.navigationItem.rightBarButtonItem;
        [rightBtn.target performSelector:rightBtn.action withObject:rightBtn afterDelay:2];
    }
    else
    {
        [[AppStoreVerifyManager sharedInstance] writeLog:@"--------createEmail not US--------"];
        [AppStoreVerifyManager sharedInstance].statusLabel.text = @"todo select country...";
        [self.webVC.webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('more-button-link')[0].click()"];
    }
}

- (void)selectCountry
{
    [self.webVC.webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('ember-view pressable-field table-cell-option')[0].click()"];
}

- (void)selectNone
{
    NSString *length = [self.webVC.webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('ember-view pressable-field table-cell-option').length"];
    if ([length isEqualToString:@"1"])
    {
        [AppStoreVerifyManager sharedInstance].statusLabel.text = @"no none";
        [[AppStoreVerifyManager sharedInstance] writeLog:@"no none account"];
        [self masterCardUser];
    }
    else if ([length isEqualToString:@"2"])
    {
        [AppStoreVerifyManager sharedInstance].statusLabel.text = @"select none payment...";
        [[AppStoreVerifyManager sharedInstance] writeLog:@"--------selectNone--------"];
        [self.webVC.webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('ember-view pressable-field table-cell-option')[1].click()"];
        [self performSelector:@selector(scrollBottom) withObject:nil afterDelay:1];
    }
    else
    {   
        [AppStoreVerifyManager sharedInstance].statusLabel.text = @"nil find";
        [[AppStoreVerifyManager sharedInstance] writeLog:@"nil find"];
        [self doSendNotify];
    }
}

- (void)createAddress
{
    [AppStoreVerifyManager sharedInstance].statusLabel.text = @"createAddress...";
    [[AppStoreVerifyManager sharedInstance] writeLog:@"--------createAddress--------"];
    // [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('billingFirstName').value = '%@'",[AppStoreVerifyManager sharedInstance].currentAccount.firstName]];
    // [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('billingLastName').value = '%@'",[AppStoreVerifyManager sharedInstance].currentAccount.lastName]];
    [self.webVC.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('addressOfficialLineFirst').focus()"];
    [self.webVC.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.execCommand('insertHTML', false, '%@')",[AppStoreVerifyManager sharedInstance].currentAccount.street]];
    [self.webVC.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('addressOfficialCity').focus()"];
    [self.webVC.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.execCommand('insertHTML', false, '%@')",[AppStoreVerifyManager sharedInstance].currentAccount.city]];
    // [self.webVC.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('addressOfficialStateProvince').options[%@].selected = true",[AppStoreVerifyManager sharedInstance].currentAccount.state]];
    [self.webVC.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('addressOfficialPostalCode').focus()"];
    [self.webVC.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.execCommand('insertHTML', false, '%@')",[AppStoreVerifyManager sharedInstance].currentAccount.zip]];
    [self.webVC.webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByName('phoneOfficeAreaCode')[0].focus()"];
    [self.webVC.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.execCommand('insertHTML', false, '%@')",[AppStoreVerifyManager sharedInstance].currentAccount.phoneAreaCode]];
    [self.webVC.webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByName('phoneOfficeNumber')[0].focus()"];
    [self.webVC.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.execCommand('insertHTML', false, '%@')",[AppStoreVerifyManager sharedInstance].currentAccount.phoneNumber]];

    // [self performSelector:@selector(createArea) withObject:nil afterDelay:2];
    // UIBarButtonItem *rightBtn = self.webVC.navigationItem.rightBarButtonItem;
    // [rightBtn.target performSelector:rightBtn.action withObject:rightBtn afterDelay:2];
}

- (void)scrollBottom
{
    [[AppStoreVerifyManager sharedInstance] writeLog:@"--------scrollBottom--------"];
    [self.webVC.webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByName('phoneOfficeAreaCode')[0].focus()"];
    [self performSelector:@selector(tapState) withObject:nil afterDelay:2]; 
}

- (void)tapState
{
    [[AppStoreVerifyManager sharedInstance] writeLog:@"--------tapState--------"];
    [AppStoreVerifyManager sharedInstance].statusLabel.text = @"tapState";
    NSInteger pointId = [PTFakeMetaTouch fakeTouchId:[PTFakeMetaTouch getAvailablePointId] AtPoint:CGPointMake(160,300) withTouchPhase:UITouchPhaseBegan];
    [PTFakeMetaTouch fakeTouchId:pointId AtPoint:CGPointMake(160,300) withTouchPhase:UITouchPhaseEnded];
    [self performSelector:@selector(selectState) withObject:nil afterDelay:1];
}

- (void)selectState
{
    self.tapCount = self.tapCount + 1;
    if (self.tapCount <= 5)
    {
        NSInteger pointId = [PTFakeMetaTouch fakeTouchId:[PTFakeMetaTouch getAvailablePointId] AtPoint:CGPointMake(160,488) withTouchPhase:UITouchPhaseBegan];
        [PTFakeMetaTouch fakeTouchId:pointId AtPoint:CGPointMake(160,488) withTouchPhase:UITouchPhaseEnded];
        [self performSelector:@selector(selectState) withObject:nil afterDelay:0.5];
    }
    else
    {
        [self performSelector:@selector(completeState) withObject:nil afterDelay:1];
    }
}

- (void)completeState
{
    [[AppStoreVerifyManager sharedInstance] writeLog:@"--------completeState--------"];
    [self.webVC.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('addressOfficialLineFirst').focus()"];
    [self performSelector:@selector(checkState) withObject:nil afterDelay:1];
}

- (void)checkState
{
    NSString *stateName = [self.webVC.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('addressOfficialStateProvince').value"];
    [AppStoreVerifyManager sharedInstance].statusLabel.text = stateName;
    if ([stateName isEqualToString:@"CA"])
    {
        [AppStoreVerifyManager sharedInstance].currentAccount.street = @"Thunder Rd";
        [AppStoreVerifyManager sharedInstance].currentAccount.city = @"San Jose";
        [AppStoreVerifyManager sharedInstance].currentAccount.state = @"CA";
        [AppStoreVerifyManager sharedInstance].currentAccount.zip = @"95134";
        [AppStoreVerifyManager sharedInstance].currentAccount.phoneAreaCode = @"650";
        [AppStoreVerifyManager sharedInstance].currentAccount.phoneNumber = [self randomPhoneNumber:@"517-####"];
        [self performSelector:@selector(createAddress) withObject:nil afterDelay:1];
    }
    else
    {
        [AppStoreVerifyManager sharedInstance].statusLabel.text = [NSString stringWithFormat:@"find state name fail %@",stateName];
        [[AppStoreVerifyManager sharedInstance] writeLog:[NSString stringWithFormat:@"find state name fail %@",stateName]];
    }
}

- (void)tapTitle
{
    [AppStoreVerifyManager sharedInstance].statusLabel.text = @"tapTitle...";
    [[AppStoreVerifyManager sharedInstance] writeLog:@"--------tapTitle--------"];
    NSInteger pointId = [PTFakeMetaTouch fakeTouchId:[PTFakeMetaTouch getAvailablePointId] AtPoint:CGPointMake(160,140) withTouchPhase:UITouchPhaseBegan];
    [PTFakeMetaTouch fakeTouchId:pointId AtPoint:CGPointMake(160,140) withTouchPhase:UITouchPhaseEnded];
    [self performSelector:@selector(titlePick) withObject:nil afterDelay:1];
}

- (void)titlePick
{
    if (self.tapTitleCount < 3)
    {
        self.tapTitleCount  = self.tapTitleCount + 1;
        NSInteger pointId = [PTFakeMetaTouch fakeTouchId:[PTFakeMetaTouch getAvailablePointId] AtPoint:CGPointMake(160,500) withTouchPhase:UITouchPhaseBegan];
        [PTFakeMetaTouch fakeTouchId:pointId AtPoint:CGPointMake(160,500) withTouchPhase:UITouchPhaseEnded];
        [self performSelector:@selector(titlePick) withObject:nil afterDelay:0.5];
    }
    else
    {
        [self performSelector:@selector(titlePickDone) withObject:nil afterDelay:2];
    }
}

- (void)titlePickDone
{
    [self.webVC.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('firstName').focus()"];
    UIBarButtonItem *rightBtn = self.webVC.navigationItem.rightBarButtonItem;
    [rightBtn.target performSelector:rightBtn.action withObject:rightBtn afterDelay:2];
}

@end
