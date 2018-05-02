//
//  AppStoreVerifyManager.m
//  TweakHeader
//
//  Created by yecongcong on 2017/7/17.
//  Copyright © 2017年 lotogram. All rights reserved.
//

#import "AppStoreVerifyManager.h"
#import <notify.h>

@implementation AppStoreVerifyManager

+ (AppStoreVerifyManager *)sharedInstance
{
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[AppStoreVerifyManager alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    if (self = [super init]) {

    }
    return self;
}

- (void)writeLog:(NSString *)logString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *strDate = [dateFormatter stringFromDate:[NSDate date]];
    NSString *filePath = @"/var/mobile/Media/AutoRegister/appleverifylogs.txt";
    NSError *error = nil;
    NSString *string = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    NSString *jsonStr = [NSString stringWithFormat:@"%@: AppStore: %@",strDate,logString];
    jsonStr = [jsonStr stringByAppendingString:@",\n"];
    string = [string stringByAppendingString:jsonStr];
    if(![string writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error])
    {
        NSLog(@"writeLog error:%@",error);
    }
}

- (void)writeAccountLog:(NSString *)errorMessage
{
    NSString *logString = [NSString stringWithFormat:@"%@ %@",self.currentAccount.appleid,errorMessage];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *strDate = [dateFormatter stringFromDate:[NSDate date]];
    NSString *filePath = @"/var/mobile/Media/AutoRegister/failgetcodeaccount.txt";
    NSError *error = nil;
    NSString *string = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    NSString *jsonStr = [NSString stringWithFormat:@"%@: %@",strDate,logString];
    jsonStr = [jsonStr stringByAppendingString:@",\n"];
    string = [string stringByAppendingString:jsonStr];
    if(![string writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error])
    {
        NSLog(@"writeLog error:%@",error);
    }
}


- (void)randomInfo:(NSString *)email password:(NSString *)password
{
    AppleAccount *account =  [[AppleAccount alloc] init];
    account.appleid = email;
    account.password = password;
    self.currentAccount = account;

    NSString *txtPath = @"/var/mobile/Media/AutoRegister/currentuser.plist";
    NSMutableDictionary *dic = [self.currentAccount toDictionary];
    [dic writeToFile:txtPath atomically:YES];
        
    NSLog(@"randomInfo %@",[self.currentAccount toDictionary]);
}

- (void)getUserFromServer:(void (^)(id responseObject, NSError *error))complete
{
    NSString *urlString = @"http://10.0.1.11:8088/users?exappid=0&status=-1";
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    request.HTTPMethod = @"GET";
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error)
            {
                NSLog(@"error:%@", error.localizedDescription);
                if (complete) {
                    complete(nil,error);
                }
            }
            else
            {
                NSError *errorJson = nil;
                NSDictionary *object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&errorJson];
                NSLog(@"success:%@",object);
                if (complete) {
                    complete(object,errorJson);
                }
                
            }
        });
    }];
    [task resume];
}

- (void)masterCardUser:(void (^)(id responseObject, NSError *error))complete
{
    NSDictionary *userInfo = @{@"appleid":self.currentAccount.appleid,@"status":@(4),@"holdingtime":@(0)};
    NSDictionary *para = @{@"user":userInfo};
    NSLog(@"verifyUser para %@",para);
    NSError *jsonerror = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:para options:0 error:&jsonerror];
    if (jsonerror) {
        NSLog(@"%@",jsonerror);
        complete(nil,jsonerror);
        return;
    }
    NSString *urlString = @"http://10.0.1.11:8088/users";
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    request.HTTPMethod = @"PUT";
    request.HTTPBody = jsonData;
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error)
            {
                NSLog(@"error:%@", error.localizedDescription);
                if (complete) {
                    complete(nil,error);
                }
            }
            else
            {
                NSError *errorJson = nil;
                NSDictionary *object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&errorJson];
                NSLog(@"success:%@",object);
                if (complete) {
                    complete(object,errorJson);
                }
            }
        });
    }];
    [task resume];
}

- (void)verifyUser:(void (^)(id responseObject, NSError *error))complete
{
    NSDictionary *userInfo = @{@"appleid":self.currentAccount.appleid,@"status":@(1),@"holdingtime":@(0),@"verify":@(YES),@"verifiedType":@(1)};
    NSDictionary *para = @{@"user":userInfo};
    NSLog(@"verifyUser para %@",para);
    NSError *jsonerror = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:para options:0 error:&jsonerror];
    if (jsonerror) {
        NSLog(@"%@",jsonerror);
        complete(nil,jsonerror);
        return;
    }
    NSString *urlString = @"http://10.0.1.11:8088/users";
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    request.HTTPMethod = @"PUT";
    request.HTTPBody = jsonData;
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error)
            {
                NSLog(@"error:%@", error.localizedDescription);
                if (complete) {
                    complete(nil,error);
                }
            }
            else
            {
                NSError *errorJson = nil;
                NSDictionary *object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&errorJson];
                NSLog(@"success:%@",object);
                if (complete) {
                    complete(object,errorJson);
                }
            }
        });
    }];
    [task resume];
}

- (void)doSignout
{
    [self verifyUser:^(id responseObject, NSError *error) {
        NSString *status = [responseObject objectForKey:@"status"];
        if (error == nil && [status isEqualToString:@"ok"])
        {
            NSString *logString = @"success verifyUser";
            [self writeAccountLog:logString];
        }
        else if (error == nil)
        {
            NSString *logString = [NSString stringWithFormat:@"verifyUser fail %@",responseObject[@"message"]];
            [self writeAccountLog:logString];
        }
        else
        {
            NSString *logString = [NSString stringWithFormat:@"verifyUser fail %@",error.localizedDescription];
            [self writeAccountLog:logString];
        }
        self.statusLabel.text = @"sign out...";
        [self.accountVC _signOut];
        self.signoutcount = 0;
        [self checksignoutstatues];
    }];
}

- (void)checksigninstatues
{
    self.bCheckSignIn = YES;
    NSString *btnTitle = self.appleIDButton.titleLabel.text;
    if (self.bNoVerifyAccount)
    {
        self.signincount = 0;
        self.bCheckSignIn = NO;
        return;
    }
    else if (![btnTitle isEqualToString:@"Sign In"])
    {
        self.signincount = 0;
        self.bCheckSignIn = NO;
        self.statusLabel.text = @"already verified";
        [self doSignout];
    }
    else if (self.signincount > 15)
    {
        self.statusLabel.text = @"sign in failed";
        self.signincount = 0;
        self.bCheckSignIn = NO;
        [self performSelector:@selector(completesignout) withObject:nil afterDelay:2];
    }
    else
    {
        self.signincount ++;
        [self performSelector:@selector(checksigninstatues) withObject:nil afterDelay:5];
    }
}

- (void)checksignoutstatues
{
    self.bCheckSignout = YES;
    NSString *btnTitle = self.appleIDButton.titleLabel.text;
    if ([btnTitle isEqualToString:@"Sign In"])
    {
        self.signoutcount = 0;
        self.statusLabel.text = @"sign out success";
        self.bCheckSignout = NO;
        [self performSelector:@selector(completesignout) withObject:nil afterDelay:2];
    }
    else if (self.signoutcount > 15)
    {
        NSString *logString = [NSString stringWithFormat:@"%@ checksignoutstatues failed",self.currentAccount.appleid];
        [self writeLog:logString];
        self.statusLabel.text = [NSString stringWithFormat:@"sign out failed %@",btnTitle];
        self.signoutcount = 0;
        self.bCheckSignout = NO;
        [self performSelector:@selector(completesignout) withObject:nil afterDelay:2];
    }
    else
    {
        self.signoutcount++;
        [self performSelector:@selector(checksignoutstatues) withObject:nil afterDelay:5];
    }
}

- (void)completesignout
{
    //[self removeAppStoreFile];
    // NSString *autoPath = @"/var/mobile/Media/AppRank/auto.txt";
    // NSString *startString = @"done";
    // [startString writeToFile:autoPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    // exit(0);
    notify_post("com.lotogram.restartappstoredoverify");
    
    // self.tabBarVc.selectedIndex = 4;
    // notify_post("com.lotogram.registerchangeserinalnumber");
    // [self performSelector:@selector(goFeature) withObject:nil afterDelay:4];
}

- (void)goFeature
{
    self.tabBarVc.selectedIndex = 0;
}
@end
