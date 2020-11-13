//
//  StoreModel.m
//  SCJSONUtilDemo
//
//  Created by Matt Reach on 2020/11/13.
//  Copyright © 2020 xuqianlong. All rights reserved.
//

#import "StoreModel.h"

@implementation StoreModel

- (NSDictionary *)sc_collideKeysMap
{
    return @{
        @"data.order":@"order",
        @"data.category":@"category",
        @"data.weight":@"weight",
    };
}

@end
