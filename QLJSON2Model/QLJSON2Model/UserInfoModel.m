//
//  UserInfoModel.m
//  QLJSON2Model
//
//  Created by xuqianlong on 15/7/14.
//  Copyright (c) 2015年 xuqianlong. All rights reserved.
//

#import "UserInfoModel.h"

@implementation CarInfoModel

- (NSDictionary *)collideKeyModelMap
{
    return @{@"brand_img_url":@"AvatarInfoModel"};
}

- (NSDictionary *)collideKeysMap
{
    return @{@"brand_img_url":@"brandImg"};
}

@end

@implementation AvatarInfoModel

@end

@implementation BasicInfoModel

- (NSDictionary *)collideKeyModelMap
{
    return @{@"avatar_img":@"AvatarInfoModel"};
}

- (NSDictionary *)collideKeysMap
{
    return @{@"avatar_img":@"avatarInfo",@"id":@"uid"};
}

//给name加个前缀；
- (void)valueNeedTransfer
{
    self.name = [@"xql." stringByAppendingString:self.name];
}
@end

@implementation DataInfoModel

- (NSDictionary *)collideKeyModelMap
{
    return @{@"basic":@"BasicInfoModel",@"cars":@"CarInfoModel"};
}

- (NSDictionary *)collideKeysMap
{
    return @{@"basic":@"basicInfo",@"cars":@"carInfoArr"};
}

@end

@implementation UserInfoModel

- (NSDictionary *)collideKeyModelMap
{
    return @{@"data":@"DataInfoModel"};
}

- (NSDictionary *)collideKeysMap
{
    return @{@"data":@"dataInfo"};
}
@end
