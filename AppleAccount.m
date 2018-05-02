//
//  AppleAccount.m
//  SpinnerDemo
//
//  Created by yecongcong on 2017/8/11.
//  Copyright © 2017年 lotogram. All rights reserved.
//

#import "AppleAccount.h"

@implementation AppleAccount

+ (AppleAccount *)itemWithDictionary:(NSDictionary *)dic
{
    AppleAccount *account = [[AppleAccount alloc] init];
    account.appleid = [dic objectForKey:@"appleid"];
    account.serialNumber = [dic objectForKey:@"sn"];
    account.password = [dic objectForKey:@"applepwd"];
    return account;
}

- (NSMutableDictionary *)toDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.appleid) {
        [dict setObject:self.appleid forKey:@"appleid"];
    }
    if (self.serialNumber) {
        [dict setObject:self.serialNumber forKey:@"sn"];
    }
    if (self.password){
        [dict setObject:self.password forKey:@"applepwd"];
    }
    return dict;
}


@end
