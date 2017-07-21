//
//  NSObject+DebugDescription.m
//  QLJSON2Model
//
//  Created by qianlongxu on 15/11/25.
//  Copyright © 2015年 xuqianlong. All rights reserved.
//

#import "NSObject+DebugDescription.h"
#import "objc/runtime.h"
#import "NSArray+DebugDescription.h"

@implementation NSObject (DebugDescription)

- (NSDictionary *)object2Dictionary
{
    unsigned int count = 0;
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    
    for (int i = 0; i < count; i++) {
        
        NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
        id value = [self valueForKey:key];
        
        if (value == nil) {
            // nothing todo
        }
        else if ([value isKindOfClass:[NSNumber class]]
                 || [value isKindOfClass:[NSString class]]
                 || [value isKindOfClass:[NSDictionary class]]) {
            [dictionary setObject:value forKey:key];
        }else if ([value isKindOfClass:[NSMutableArray class]]){
            NSArray *resultArr = [value objectArray2JSONArray];
            [dictionary setObject:resultArr forKey:key];
        }else if ([value isKindOfClass:[NSObject class]]) {
            NSString *keyClass = NSStringFromClass([value class]);
            key = [NSString stringWithFormat:@"%@:(%@)",key,keyClass];
            [dictionary setObject:[value object2Dictionary] forKey:key];
        }else {
            NSLog(@"Invalid type for %@ (%@)", NSStringFromClass([self class]), key);
        }
    }
    free(properties);
    return dictionary;
}

//- (NSString *)description
//{
//    return [NSString stringWithFormat:@"%@",[self object2Dictionary]];
//}

@end
