//
//  NSArray+DebugDescription.m
//  QLJSON2Model
//
//  Created by qianlongxu on 15/11/25.
//  Copyright © 2015年 xuqianlong. All rights reserved.
//

#import "NSArray+DebugDescription.h"
#import "NSObject+DebugDescription.h"

@implementation NSArray (DebugDescription)

- (NSArray *)objectArray2JSONArray
{
    NSMutableArray *result = [NSMutableArray array];
    for (NSObject *obj in self) {
        if ([obj respondsToSelector:@selector(object2Dictionary)]) {
            NSDictionary *dic = [obj object2Dictionary];
            [result addObject:dic];
        }
    }
    return result;
}

@end
