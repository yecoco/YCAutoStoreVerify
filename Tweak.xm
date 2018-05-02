#import <notify.h>
#import "AppStoreVerifyManager.h"
#import "SBAutoVerifyEmailManager.h"
#import "LotoWebViewManager.h"

%group workAutoVerify

void LogEvent(CFNotificationCenterRef center,
              void *observer,
              CFStringRef name,
              const void *object,
              CFDictionaryRef userInfo)
{
    [SBAutoVerifyEmailManager sharedInstance].bAppStoreLive = YES;
    NSLog(@"-----------------------------LogEvent------------------------------");
}

void RestartDo(CFNotificationCenterRef center,
              void *observer,
              CFStringRef name,
              const void *object,
              CFDictionaryRef userInfo)
{
    [[SBAutoVerifyEmailManager sharedInstance] restartDo];
    NSLog(@"-----------------------------ContinueDo------------------------------");
}

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application
{
    NSLog(@"---------applicationDidFinishLaunching");
    CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,
            LogEvent,
            (CFStringRef)@"com.lotogram.checkappstoreliveforautoverify",
            NULL,
            CFNotificationSuspensionBehaviorCoalesce);

    CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,
            RestartDo,
            (CFStringRef)@"com.lotogram.restartappstoredoverify",
            NULL,
            CFNotificationSuspensionBehaviorCoalesce);

    %orig(application);
}
%end

//iOS10 解锁屏幕
%hook SBDashBoardViewController
%new
- (void)lotounlockScreen
{
    [(SBLockScreenManager *)[%c(SBLockScreenManager) sharedInstance] attemptUnlockWithPasscode:nil];
}
%new
- (void)lotolightScreen
{
    [(SBBacklightController *)[%c(SBBacklightController) sharedInstance] turnOnScreenFullyWithBacklightSource:1];
}

-(void)viewDidAppear:(BOOL)arg1
{
    NSLog(@"SBDashBoardViewController viewDidAppear");
    %orig(arg1);
    //[SBAutoVerifyEmailManager sharedInstance].bAutoCheck = YES;
    [(SBBacklightController *)[%c(SBBacklightController) sharedInstance] cancelLockScreenIdleTimer];
    [self performSelector:@selector(lotolightScreen) withObject:nil afterDelay:1];
    [self performSelector:@selector(lotounlockScreen) withObject:nil afterDelay:2];
    [[SBAutoVerifyEmailManager sharedInstance] performSelector:@selector(openApplication) withObject:nil afterDelay:5];
    // [[SBAutoVerifyEmailManager sharedInstance] performSelector:@selector(checkAutoTxt) withObject:nil afterDelay:5];
}
%end

//iOS10 AppStore输入账号密码提示框及各种提示的弹窗包括No SIM Card Installed
%hook SBSharedModalAlertItemPresenter
%new
- (void)doOkSimAlert:(SBSIMLockAlertItem *)alertItem
{
    typedef void (^actionHandle)(UIAlertAction *action);
    actionHandle handle = nil;
    UIAlertController *alert = [alertItem _alertController];
    if (alert == nil)
    {
        NSLog(@"SBSIMLockAlertItem _alertController nil");
        return;
    }
    UIAlertAction *action = alert.actions.firstObject;
    NSLog(@"do alert action title %@",action.title);
    unsigned int numIvars; 
    Ivar *vars = class_copyIvarList(NSClassFromString(@"UIAlertAction"), &numIvars);
    NSString *key = nil;
    for(int i = 0; i < numIvars; i++) {
        Ivar thisIvar = vars[i];
        key = [NSString stringWithUTF8String:ivar_getName(thisIvar)];
        if ([key isEqualToString:@"_handler"]) 
        {
            handle = object_getIvar(action,thisIvar);
            break;
        }  
    }
    free(vars);
    if (handle != nil)
    {
        handle(action);
    }
    else
    {
        NSLog(@"handle nil");
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doOkSimAlert:) object:alertItem];
}

-(void)presentAlertItem:(id)arg1 isLocked:(BOOL)arg2 animated:(BOOL)arg3
{
    NSLog(@"SBSharedModalAlertItemPresenter presentAlertItem %@",arg1);
    %orig(arg1,arg2,arg3);
    NSString *className = NSStringFromClass([arg1 class]);
    if ([className isEqualToString:@"SBSIMLockAlertItem"])
    {
        NSLog(@"className %@",className);
        SBSIMLockAlertItem *alertItem = (SBSIMLockAlertItem *)arg1;
        [self performSelector:@selector(doOkSimAlert:) withObject:alertItem afterDelay:1];
        return;
    }
    else if (![className isEqualToString:@"SBUserNotificationAlert"])
    {
        return;
    }
    SBUserNotificationAlert *alertItem = (SBUserNotificationAlert *)arg1;
    UIAlertController *alert = [alertItem _alertController];
    if (!alert)
    {
        NSLog(@"alertController nil");
        return;
    }
    else
    {
        NSString *alerttitle = alertItem.alertHeader;
        NSString *logString = [NSString stringWithFormat:@"alert %@",alerttitle];
        [[SBAutoVerifyEmailManager sharedInstance] writeLog:logString];
        if ([alerttitle isEqualToString:@"Sign In to iTunes Store"]||[alerttitle isEqualToString:@"Sign-In Required"])
        {
            NSString *txtPath = @"/var/mobile/Media/AutoRegister/currentuser.plist";
            NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:txtPath];
            if (dic != nil)
            {
                NSString *appleid = [dic objectForKey:@"appleid"];
                NSString *applepwd = [dic objectForKey:@"applepwd"];
                NSLog(@"%@ do 1111111",alerttitle);
                NSArray *textFields = alert.textFields;
                if (textFields.count == 0 || textFields == nil)
                {
                    NSLog(@"alertController not nil but textFields nil");
                }
                else if(textFields.count == 1)
                {
                    UITextField *textField = textFields.firstObject;
                    textField.text = applepwd;
                }
                else if(textFields.count == 2)
                {
                    UITextField *textField = textFields.firstObject;
                    textField.text = appleid;
                    textField = textFields.lastObject;
                    textField.text = applepwd;
                }
                else
                {
                    NSLog(@"over 3 count textFields");
                }
                NSArray *objectArray = [NSArray arrayWithObjects:alertItem,@(1),nil];
                [[SBAutoVerifyEmailManager sharedInstance] performSelector:@selector(doContinue:) withObject:objectArray afterDelay:2];
            }   
        }
        else if ([alerttitle isEqualToString:@"Sign In"])
        {
            NSArray *objectArray = [NSArray arrayWithObjects:alertItem, nil];
            [[SBAutoVerifyEmailManager sharedInstance] performSelector:@selector(doCreate:) withObject:objectArray afterDelay:1];
        }
        else if ([alerttitle isEqualToString:@"Require password for additional purchases on this device?"])
        {
            NSLog(@"%@ do 000000",alerttitle);
            [SBAutoVerifyEmailManager sharedInstance].bShowAgree = NO;
            NSArray *objectArray = [NSArray arrayWithObjects:alertItem, nil];
            [[SBAutoVerifyEmailManager sharedInstance] performSelector:@selector(doContinue:) withObject:objectArray afterDelay:1];
        }
        else if ([alerttitle isEqualToString:@"Verification Failed"])
        {
            NSString *txtPath = @"/var/mobile/Media/AutoRegister/alert.txt";
            [alerttitle writeToFile:txtPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            NSLog(@"%@ do 000000",alerttitle);
            NSArray *objectArray = [NSArray arrayWithObjects:alertItem, nil];
            [[SBAutoVerifyEmailManager sharedInstance] performSelector:@selector(doContinue:) withObject:objectArray afterDelay:1];
        }
        else if([alerttitle isEqualToString:@"Your Apple ID has been disabled."])
        {
            NSString *txtPath = @"/var/mobile/Media/AutoRegister/alert.txt";
            [alerttitle writeToFile:txtPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            NSLog(@"%@ do 000000",alerttitle);
            NSArray *objectArray = [NSArray arrayWithObjects:alertItem, nil];
            [[SBAutoVerifyEmailManager sharedInstance] performSelector:@selector(doContinue:) withObject:objectArray afterDelay:1];
        }
        else if([alerttitle isEqualToString:@"Verification Required"])
        {
            NSString *txtPath = @"/var/mobile/Media/AutoRegister/alert.txt";
            [alerttitle writeToFile:txtPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            NSLog(@"%@ do 000000",alerttitle);
            NSArray *objectArray = [NSArray arrayWithObjects:alertItem, nil];
            [[SBAutoVerifyEmailManager sharedInstance] performSelector:@selector(doContinue:) withObject:objectArray afterDelay:1];
        }
        else if([alerttitle isEqualToString:@"Apple ID Verification"])
        {
            NSString *txtPath = @"/var/mobile/Media/AutoRegister/alert.txt";
            [alerttitle writeToFile:txtPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            NSLog(@"%@ do 000000",alerttitle);
            NSArray *objectArray = [NSArray arrayWithObjects:alertItem, nil];
            [[SBAutoVerifyEmailManager sharedInstance] performSelector:@selector(doContinue:) withObject:objectArray afterDelay:1];
        }
        else if([alerttitle isEqualToString:@"Cannot connect to iTunes Store"])
        {
            NSString *txtPath = @"/var/mobile/Media/AutoRegister/alert.txt";
            [alerttitle writeToFile:txtPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            NSLog(@"%@ do 000000",alerttitle);
            NSArray *objectArray = [NSArray arrayWithObjects:alertItem, nil];
            [[SBAutoVerifyEmailManager sharedInstance] performSelector:@selector(doContinue:) withObject:objectArray afterDelay:1];
        }
        else if([alerttitle isEqualToString:@"This Apple ID has not yet been used in the iTunes Store."])
        {
            NSArray *objectArray = [NSArray arrayWithObjects:alertItem,@(1),nil];
            [[SBAutoVerifyEmailManager sharedInstance] performSelector:@selector(doContinue:) withObject:objectArray afterDelay:2];
        }
        else 
        {
            NSLog(@"%@ do 000000",alerttitle);
            NSArray *objectArray = [NSArray arrayWithObjects:alertItem, nil];
            [[SBAutoVerifyEmailManager sharedInstance] performSelector:@selector(doContinue:) withObject:objectArray afterDelay:1];
        } 
    }
}
%end

%hook SUWebViewController
- (void)_finishLoadWithResult:(_Bool)arg1 error:(id)arg2
{
    %orig(arg1,arg2);
    [AppStoreVerifyManager sharedInstance].statusLabel.text = [NSString stringWithFormat:@"finishLoadWithResult--bool:%i",arg1];
    [[AppStoreVerifyManager sharedInstance] writeLog:[NSString stringWithFormat:@"----------_finishLoadWithResult--bool:%i---error:%@-----",arg1,arg2]];
    [LotoWebViewManager sharedInstance].webVC = self;
    [AppStoreVerifyManager sharedInstance].bNoVerifyAccount = YES;
    // NSString *HTMLSource = [self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('html')[0].innerHTML"];
}
%end

%hook SKUIStorePageSectionsViewController
%new
- (void)getUserToLogin
{
    // [[AppStoreVerifyManager sharedInstance] randomInfo:@"shimufbiz25@163.com" password:@"qiangmei68219734"];
    [AppStoreVerifyManager sharedInstance].currentAccount = nil;
    [[AppStoreVerifyManager sharedInstance] getUserFromServer:^(id responseObject, NSError *error) {
        NSString *status = [responseObject objectForKey:@"status"];
        if (error == nil && [status isEqualToString:@"ok"])
        {
            [AppStoreVerifyManager sharedInstance].bNoVerifyAccount = NO;
            NSDictionary *user = responseObject[@"user"];
            NSString *emailPwd = user[@"applepwd"];
            NSString *email = user[@"appleid"];
            [[AppStoreVerifyManager sharedInstance] randomInfo:email password:emailPwd];
            [AppStoreVerifyManager sharedInstance].statusLabel.text = @"signin...";
            [[AppStoreVerifyManager sharedInstance].appleIDButton sendActionsForControlEvents:UIControlEventTouchUpInside];
            if ([AppStoreVerifyManager sharedInstance].bCheckSignIn == NO)
            {
                [[AppStoreVerifyManager sharedInstance] checksigninstatues];
            }
            else
            {
                [AppStoreVerifyManager sharedInstance].statusLabel.text = @"already in checksigninstatues";
            }
        }
        else
        {
            NSString *logString = @"";
            if (error != nil)
            {
                logString = [NSString stringWithFormat:@"have devicename fail getuser %@",error.localizedDescription];
            }
            else
            {
                logString = [NSString stringWithFormat:@"have devicename fail getuser %@",responseObject[@"message"]];
            }
            [[AppStoreVerifyManager sharedInstance] writeLog:logString];
            [AppStoreVerifyManager sharedInstance].statusLabel.text = [NSString stringWithFormat:@"%@",logString];
        }
    }];
}

%new 
- (void)bottomTodoNext
{
    if ([AppStoreVerifyManager sharedInstance].appleIDButton == nil)
    {
        [AppStoreVerifyManager sharedInstance].statusLabel.text = @"please wait scrollToBottom";
        [self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:2];
    }
    else
    {
        NSString *btnTitle = [AppStoreVerifyManager sharedInstance].appleIDButton.titleLabel.text;
        if ([btnTitle isEqualToString:@"Sign In"])
        {
            [AppStoreVerifyManager sharedInstance].statusLabel.text = @"get user from server...";
            [self performSelector:@selector(getUserToLogin) withObject:nil afterDelay:0];
        }
        else
        {
            [AppStoreVerifyManager sharedInstance].statusLabel.text = [NSString stringWithFormat:@"%@ sign out.......",[AppStoreVerifyManager sharedInstance].currentAccount.appleid];
            [[AppStoreVerifyManager sharedInstance].accountVC _signOut];
            [AppStoreVerifyManager sharedInstance].signoutcount = 0;
            if ([AppStoreVerifyManager sharedInstance].bCheckSignout == NO)
            {
                [[AppStoreVerifyManager sharedInstance] checksignoutstatues];
            }
            else
            {
                [AppStoreVerifyManager sharedInstance].statusLabel.text = @"already in checksignoutstatues";
            }
        }
    }
}

%new
- (void)scrollToBottom
{
    id view = self.view.subviews.firstObject;
    if ([view isKindOfClass:[UICollectionView class]])
    {
        UICollectionView *collection = (UICollectionView *)view;
        NSInteger sections = [collection numberOfSections];
        NSInteger cellcount = [collection numberOfItemsInSection:sections-1];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(cellcount-1) inSection:sections-1];
        [collection scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
        [self performSelector:@selector(bottomTodoNext) withObject:nil afterDelay:2.0f];
    }
    else
    {
        [AppStoreVerifyManager sharedInstance].statusLabel.text = @"featured page no find UICollectionView";
    }  
}

- (void)viewDidAppear:(_Bool)arg1
{
    %orig(arg1);
    notify_post("com.lotogram.checkappstoreliveforautoverify");
    UITabBarController *tabbarvc = self.tabBarController;
    if (tabbarvc == nil || ![tabbarvc isKindOfClass:[UITabBarController class]])
    {
        [AppStoreVerifyManager sharedInstance].statusLabel.text = [NSString stringWithFormat:@"self.tabBarController is nil %@",NSStringFromClass([tabbarvc class])];
        return;
    }
    [AppStoreVerifyManager sharedInstance].tabBarVc = tabbarvc;
    if (tabbarvc.selectedIndex == 0) 
    {
        [self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:2.0f];
    }
}
%end

%hook SKUIAccountButtonsViewController
- (void)viewDidAppear:(bool)arg1
{
    [AppStoreVerifyManager sharedInstance].accountVC = self;
    %orig(arg1);
}
%end

%hook SKUIAccountButtonsView
- (void)layoutSubviews
{
    [AppStoreVerifyManager sharedInstance].appleIDButton = self.appleIDButton;
    %orig;
}
%end

%hook SKUITabBarController
- (void)viewDidAppear:(bool)arg1
{
    %orig(arg1);
    NSLog(@"------SKUITabBarController viewDidAppear");
    [AppStoreVerifyManager sharedInstance].tabBarVc = self;
}
%end

%hook ASAppDelegate
- (_Bool)application:(id)arg1 didFinishLaunchingWithOptions:(id)arg2 {

    BOOL didfinish = %orig(arg1,arg2);
    UIWindow* window = [UIApplication sharedApplication].keyWindow;
    [window makeKeyAndVisible];
    CGRect frame = [UIScreen mainScreen].bounds;
    frame.origin.y = frame.size.height - 100;
    frame.size.height = 50;
    UIView *polygonView = [[UIView alloc] initWithFrame: frame];
    polygonView.backgroundColor = [UIColor redColor];
    [window addSubview:polygonView];

    UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 320, 30)];
    statusLabel.font = [UIFont systemFontOfSize:12];
    [polygonView addSubview:statusLabel];

    [AppStoreVerifyManager sharedInstance].statusLabel = statusLabel;
    [AppStoreVerifyManager sharedInstance].tabBarVc = nil;
    [AppStoreVerifyManager sharedInstance].naviVC = nil;
    [AppStoreVerifyManager sharedInstance].appleIDButton = nil;
    [AppStoreVerifyManager sharedInstance].accountVC = nil;
    return didfinish;
}
%end

%hook SSAuthenticationContext
-(BOOL)canCreateNewAccount
{
    return NO;
}
%end

%hook UIAlertView
%new 
- (void)completeAgreeDo
{
    NSLog(@"UIAlertView completeAgreeDo");
    [self.delegate alertView:self didDismissWithButtonIndex:0];
    [self dismissWithClickedButtonIndex:1 animated:NO];
}
%new
- (void)agreedonext
{
    NSLog(@"UIAlertView agreedonext");
    [self.delegate alertView:self clickedButtonAtIndex:1];
    [self dismissWithClickedButtonIndex:1 animated:NO];
}

- (void)show
{
    NSLog(@"UIAlertView show message%@",self.message);
    [[AppStoreVerifyManager sharedInstance] writeLog:[NSString stringWithFormat:@"UIAlertView title:%@ message:%@",self.title,self.message]];
    %orig;
}
%end

%hook UIAlertController
%new
- (void)doContinue:(NSNumber *)bcontinue
{
    typedef void (^actionHandle)(UIAlertAction *action);
    actionHandle handle = nil;
    UIAlertAction *action = self.actions.firstObject;
    if (bcontinue)
    {
        action = self.actions.lastObject;
    }
    NSLog(@"do alert action title %@",action.title);
    unsigned int numIvars; 
    Ivar *vars = class_copyIvarList(NSClassFromString(@"UIAlertAction"), &numIvars);
    NSString *key = nil;
    for(int i = 0; i < numIvars; i++) {
        Ivar thisIvar = vars[i];
        key = [NSString stringWithUTF8String:ivar_getName(thisIvar)];
        if ([key isEqualToString:@"_handler"]) 
        {
            handle = object_getIvar(action,thisIvar);
            break;
        }
    }
    free(vars);
    if (handle != nil)
    {
       handle(action);
       [self dismissViewControllerAnimated:NO completion:nil];

    }
    else
    {
        NSLog(@"handle nil");
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doContinue:) object:bcontinue];
}

%new
- (void)changSN
{
    if ([LotoWebViewManager sharedInstance].webVC)
    {
        [[LotoWebViewManager sharedInstance].webVC dismissViewControllerAnimated:YES completion:^{
            [self performSelector:@selector(sendNotify) withObject:nil afterDelay:2];
        }];
    }
}

%new
- (void)sendNotify
{
    notify_post("com.lotogram.restartappstoredoverify");
}

- (void)viewDidAppear:(_Bool)arg1
{
    %orig(arg1);
    NSLog(@"UIAlertController viewDidAppear title:%@ message:%@",self.title,self.message);
    if ([self.title isEqualToString:@"We've run into a problem. Please try again later."])
    {
        [self performSelector:@selector(doContinue:) withObject:nil afterDelay:1];
        [self performSelector:@selector(changSN) withObject:nil afterDelay:2];
    }
    else
    {
        [[AppStoreVerifyManager sharedInstance] writeLog:[NSString stringWithFormat:@"UIAlertController viewDidAppear title:%@ message:%@",self.title,self.message]];
    }
}
%end
%end

%ctor {
    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.lotogram.lotosettings.plist"];
    NSInteger work = [dic[@"work"] integerValue];
    if (work == 1)
    {
        NSLog(@"---------work autoRank-----------");
    }
    else if (work == 2)
    {
        NSLog(@"---------work autoregister-----------");
    }
    else if(work == 3)
    {
        %init(workAutoVerify);
        NSLog(@"---------work autoverify-----------");
    }
    else
    {
        NSLog(@"---------work other-----------");
    }
}
