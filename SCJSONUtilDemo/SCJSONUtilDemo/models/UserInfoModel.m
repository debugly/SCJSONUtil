//
//  UserInfoModel.m
//  QLJSON2Model
//
//  Created by xuqianlong on 15/7/14.
//  Copyright (c) 2015年 xuqianlong. All rights reserved.
//

#import "UserInfoModel.h"
#import <SCJSONUtil/SCJSONUtil.h>

@implementation CarInfoModel

- (NSDictionary *)sc_collideKeysMap
{
    return @{@"brand_img_url":@"brandImg"};
}

@end

@implementation AvatarInfoModel

@end

@implementation BasicInfoModel

- (NSDictionary *)sc_collideKeysMap
{
    return @{@"avatar_img":@"avatarInfo"};
}

//给name加个前缀；

- (id)sc_key:(NSString *)key beforeAssignedValue:(NSString *)value
{
    if ([key isEqualToString:@"name"]) {
        if ([value isKindOfClass:[NSString class]]) {
            return [@"xql." stringByAppendingString:value];
        }
        return nil;
    }
    return value;
}

@end

@implementation DataInfoModel

- (NSDictionary *)sc_collideKeyModelMap
{
    return @{@"cars":@"CarInfoModel"};
}

- (NSDictionary *)sc_collideKeysMap
{
    return @{@"basic":@"basicInfo",@"cars":@"carInfoArr"};
}

@end

@implementation UserInfoModel

@end
