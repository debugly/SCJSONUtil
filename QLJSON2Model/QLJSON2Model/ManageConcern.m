
//
//  ManageConcern.m
//  QLJSON2Model
//
//  Created by xuqianlong on 15/7/16.
//  Copyright (c) 2015年 xuqianlong. All rights reserved.
//

#import "ManageConcern.h"

@implementation FavModel
//处理就好了
- (void)valueNeedTransfer
{
    if (self.pic) {
        self.pic = [NSURL URLWithString:(NSString *)self.pic];
    }
}

@end

@implementation ContenModel

- (NSDictionary *)collideKeysMap
{
    return @{@"favList":@"favArr"};
}

- (NSDictionary *)collideKeyModelMap
{
    return @{@"favList":@"FavModel"};
}

@end

@implementation ManageConcern

- (NSDictionary *)collideKeysMap
{
    return @{@"content":@"contenModel"}; //字典的key：json的key，字典的value：model的属性名
}

- (NSDictionary *)collideKeyModelMap
{
    return @{@"content":@"ContenModel"}; //字典的key：json的key，字典的value：model的类名
}
@end
