//
//  AppleAccount.h
//  SpinnerDemo
//
//  Created by yecongcong on 2017/8/11.
//  Copyright © 2017年 lotogram. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppleAccount : NSObject

@property (nonatomic, strong) NSString *appleid;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *serialNumber;
@property (nonatomic, strong) NSString *street;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *zip;
@property (nonatomic, strong) NSString *phoneAreaCode;
@property (nonatomic, strong) NSString *phoneNumber;

+ (AppleAccount *)itemWithDictionary:(NSDictionary *)dic;
- (NSMutableDictionary *)toDictionary;

@end
