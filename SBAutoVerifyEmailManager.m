//
//  SBAutoVerifyEmailManager.m
//  TweakHeader
//
//  Created by yecongcong on 2017/7/17.
//  Copyright © 2017年 lotogram. All rights reserved.
//

#import "SBAutoVerifyEmailManager.h"

@implementation SBAutoVerifyEmailManager

+ (SBAutoVerifyEmailManager *)sharedInstance
{
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[SBAutoVerifyEmailManager alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self performSelector:@selector(checkAppStoreStatues) withObject:nil afterDelay:300];
        NSLog(@"------------------------SBAutoManager init------------------------");
    }
    return self;
}

- (void)registerErrorDo
{
    system("killall -9 AppStore");
    [self randomVerifySerialNumber];
    self.bOpenedAppStore = NO;
    [self performSelector:@selector(openApplication) withObject:nil afterDelay:5];
}

- (void)restartDo
{
    system("killall -9 AppStore");
    [self randomVerifySerialNumber];
    self.bOpenedAppStore = NO;
    [self performSelector:@selector(openApplication) withObject:nil afterDelay:5];
}

- (void)checkAppStoreStatues
{
    NSLog(@"---------checkAppStoreStatues-----------");
    if (!self.bAppStoreLive)
    {
        NSLog(@"---------checkAppStoreStatues bAppStoreLive NO TO KILL-----------");
        // NSString *txtPath = @"/var/mobile/Media/AppRank/auto.txt";
        // NSString *autoString = [[NSString alloc] initWithContentsOfFile:txtPath encoding:NSUTF8StringEncoding error:nil];
        // autoString = [autoString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        // autoString = [autoString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        // autoString = [autoString stringByReplacingOccurrencesOfString:@" " withString:@""];
        // if ([autoString isEqualToString:@"start"])
        // {
        //     system("killall -9 AppStore");
        //     self.bOpenedAppStore = NO;
        // }
        system("killall -9 AppStore");
        [self randomVerifySerialNumber];
        [self performSelector:@selector(openApplication) withObject:nil afterDelay:2];
    }
    self.bAppStoreLive = NO;
    [self performSelector:@selector(checkAppStoreStatues) withObject:nil afterDelay:300];
}

- (void)writeLog:(NSString *)logString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *strDate = [dateFormatter stringFromDate:[NSDate date]];
    NSString *filePath = @"/var/mobile/Media/AutoRegister/appleverifylogs.txt";
    NSError *error = nil;
    NSString *string = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    NSString *jsonStr = [NSString stringWithFormat:@"%@: SpringBoard: %@",strDate,logString];
    jsonStr = [jsonStr stringByAppendingString:@",\n"];
    string = [string stringByAppendingString:jsonStr];
    if(![string writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error])
    {
        NSLog(@"writeLog error:%@",error);
    }
}

- (void)openApplication
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
        if (LSApplicationWorkspace_class)
        {
            LSApplicationWorkspace *workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
            if (workspace && [workspace openApplicationWithBundleID:@"com.apple.AppStore"])
            {
                self.bAppStoreLive = YES;
                NSLog(@"------openApplication Successful!");
            }
            else
            {
                self.bAppStoreLive = NO;
                NSLog(@"-----openApplication failed");
            }
        }
        else
        {
            self.bAppStoreLive = NO;
            NSLog(@"-----openApplication failed nil LSApplicationWorkspace_class");
        }
    });
}

- (void)writeNewSerialNumber
{
    NSString *alphabet = @"A0B1CDEF2GHI3JKL4MN5OP6QRS7TU8VW9XYZ";
    NSString *randomString = @"";
    for (int i = 0; i < 12; ++i) {
        NSUInteger j = arc4random_uniform(36);
        NSString *cu = [alphabet substringWithRange:NSMakeRange(j,1)];
        randomString = [NSString stringWithFormat:@"%@%@",randomString,cu];
    }
    if (randomString.length != 12) {
        randomString = @"D68FK8PBDG2X";
    }
    NSError *error = nil;
    if(![randomString writeToFile:@"/var/mobile/Library/Preferences/deviceInfo.txt" atomically:YES encoding:NSUTF8StringEncoding error:&error])
    {
        NSLog(@"---------------write SerialNumber failed:%@",error);
    }
    NSLog(@"randomSerialNumber:%@",randomString);
}

- (void)randomVerifySerialNumber
{
    NSString *alphabet = @"A0B1CDEF2GHI3JKL4MN5OP6QRS7TU8VW9XYZ";
    NSString *randomString = @"";
    for (int i = 0; i < 12; ++i) {
        NSUInteger j = arc4random_uniform(36);
        NSString *cu = [alphabet substringWithRange:NSMakeRange(j,1)];
        randomString = [NSString stringWithFormat:@"%@%@",randomString,cu];
    }
    if (randomString.length != 12) {
        randomString = @"D68FK8PBDG2X";
    }
    NSError *error = nil;
    if(![randomString writeToFile:@"/var/mobile/Library/Preferences/deviceInfo.txt" atomically:YES encoding:NSUTF8StringEncoding error:&error])
    {
        NSLog(@"---------------write SerialNumber failed:%@",error);
    }
    NSLog(@"randomSerialNumber:%@",randomString);
    system("killall -9 absd & killall -9 itunesstored & killall -9 AppStore");
}

- (void)checkAutoTxt
{
    NSString *txtPath = @"/var/mobile/Media/AppRank/auto.txt";
    NSString *autoString = [[NSString alloc] initWithContentsOfFile:txtPath encoding:NSUTF8StringEncoding error:nil];
    autoString = [autoString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    autoString = [autoString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    autoString = [autoString stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([autoString isEqualToString:@"done"])
    {
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Cookies/com.apple.itunesstored.2.sqlitedb" error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Cookies/com.apple.itunesstored.binarycookies" error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Cookies/com.apple.itunesstored.2.sqlitedb-shm" error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Cookies/com.apple.itunesstored.2.sqlitedb-wal" error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Caches/sharedCaches" error:nil];
        self.bOpenedAppStore = NO;
        NSString *startString = @"start";
        [startString writeToFile:txtPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [self randomVerifySerialNumber];
    }
    else if ([autoString isEqualToString:@"start"])
    {
        if (self.bOpenedAppStore == NO)
        {
            NSString *txtPath = @"/var/mobile/Media/AppRank/alert.txt";
            [@"" writeToFile:txtPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            self.bOpenedAppStore = YES;
            NSLog(@"checkAutoTxt:start");
            [self openApplication];
            [self lotoUninstallApplication];
        }
    }
    else if ([autoString isEqualToString:@"pause"])
    {
        NSLog(@"checkAutoTxt %@",autoString);
    }
    else if ([autoString isEqualToString:@"complete"])
    {
        NSLog(@"checkAutoTxt %@",autoString);
    }
    if (self.bAutoCheck)
    {
        [self performSelector:@selector(checkAutoTxt) withObject:nil afterDelay:1];
    }
}

- (void)lotoUninstallApplication
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *bundleid = @"com.apple.itunesu";
        if (bundleid)
        {
            Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
            if (LSApplicationWorkspace_class) {
                LSApplicationWorkspace *workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
                if(workspace && [workspace applicationIsInstalled:bundleid])
                {
                    if([workspace uninstallApplication:bundleid withOptions:nil])
                    {
                        NSLog(@"-----lotoUninstallApplication uninstall success");
                    }
                    else
                    {
                        NSLog(@"-----lotoUninstallApplication uninstall failed");
                    }
                }
                else if (workspace)
                {
                    NSLog(@"-----lotoUninstallApplication not install application");
                }
                else
                {
                    NSLog(@"-----Uninstall failed workspace nil");
                }
            }
            else
            {
                NSLog(@"-----Uninstall failed nil LSApplicationWorkspace_class");
            }
        }
        else
        {
            NSLog(@"-----Uninstall not find bundldID");
        }
    });
}

- (void)doCreate:(NSArray *)objectArray
{
    typedef void (^actionHandle)(UIAlertAction *action);
    actionHandle handle = nil;
    SBUserNotificationAlert *alertItem = objectArray.firstObject;
    UIAlertController *alert = [alertItem _alertController];
    if (alert.actions.count != 3)
    {
        return;
    }
    UIAlertAction *action = alert.actions[1];
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
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doCreate:) object:objectArray];
}

- (void)doContinue:(NSArray *)objectArray
{
    typedef void (^actionHandle)(UIAlertAction *action);
    actionHandle handle = nil;
    SBUserNotificationAlert *alertItem = objectArray.firstObject;
    UIAlertController *alert = [alertItem _alertController];
    UIAlertAction *action = alert.actions.firstObject;
    if (objectArray.count == 2)
    {
        action = alert.actions.lastObject;
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
    }
    else
    {
        NSLog(@"handle nil");
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doContinue:) object:objectArray];
}

@end
