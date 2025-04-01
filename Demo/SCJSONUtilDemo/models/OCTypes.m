//
//  OCTypes.m
//  SCJSONUtilDemo
//
//  Created by qianlongxu on 2019/11/26.
//  Copyright © 2019 xuqianlong. All rights reserved.
//

#import "OCTypes.h"

@implementation OCClassA

@end

@implementation OCTypes

- (instancetype)init
{
    self = [super init];
    if (self) {
        _skipMe = @"我没有被解析";
    }
    return self;
}

@end
