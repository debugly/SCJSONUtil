//
//  NSObject+PrintProperties.m
//  QLJSON2Model
//
//  Created by qianlongxu on 15/11/25.
//  Copyright © 2015年 xuqianlong. All rights reserved.
//

#import "NSObject+PrintProperties.h"
#import "objc/runtime.h"

@implementation NSObject (PrintProperties)

- (NSArray *)propertyNames
{
    NSArray *(^classProperties)(Class clazz) = ^ NSArray * (Class clazz){
        
        unsigned int count = 0;
        objc_property_t *properties = class_copyPropertyList(clazz, &count);
        NSMutableArray *propertyNames = [NSMutableArray array];
        for (int i = 0; i < count; i++) {
            NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
            [propertyNames addObject:key];
        }
        free(properties);
        return propertyNames;
    };
    
    
    NSMutableArray *properties = [NSMutableArray array];
    Class supclass = [self class];
    do {
        NSMutableDictionary *propertyDic = [NSMutableDictionary dictionary];
        [propertyDic setObject:classProperties(supclass) forKey:NSStringFromClass(supclass)];
        [properties addObject:propertyDic];
        supclass = [supclass superclass];
    } while (supclass != [NSObject class]);
    
    return [properties copy];
}


- (NSString *)DEBUGDescrption
{
    return [self DEBUGDescrptionWithLeval:0];
}

- (NSString *)stringForLeval:(NSUInteger)leval
{
    NSMutableString *toString = [[NSMutableString alloc]init];
    while (leval --) {
        [toString appendFormat:@"\t"];
    }
    return toString;
}

- (NSString *)DEBUGDescrptionWithLeval:(NSUInteger)leval
{
    NSString *levalString = [self stringForLeval:leval];
    leval ++;
    if ([self isKindOfClass:[NSArray class]]) {
        NSArray *objs = (NSArray *)self;
        NSMutableString *toString = [[NSMutableString alloc]init];
        [toString appendString:levalString];
        [toString appendFormat:@"[\n"];
        for (NSObject *obj in objs) {
            [toString appendString:levalString];
            [toString appendFormat:@"%@",[obj DEBUGDescrptionWithLeval:leval]];
        }
        [toString appendString:levalString];
        [toString appendFormat:@"]\n"];
        return [toString copy];
    }else if([self isKindOfClass:[NSDictionary class]]){
        return [self description];
    }else if([self isKindOfClass:[NSNumber class]]) {
        return [self description];
    }else if([self isKindOfClass:[NSNull class]]) {
        return [self description];
    }else if([self isKindOfClass:[NSURL class]]) {
        NSURL *url = (NSURL *)self;
        return [url absoluteString];
    }else if([self isKindOfClass:[NSString class]]) {
        return [self description];
    }else if([self isKindOfClass:[NSDate class]]) {
        return [self description];
    }else{
        NSMutableString *toString = [[NSMutableString alloc]init];
        NSArray *properties = [self propertyNames];
        
        for (int i = 0; i < properties.count; i++) {
            NSMutableDictionary *propertyDic = properties[i];
            NSString *className = [[propertyDic allKeys]firstObject];
            [toString appendString:levalString];
            if (i > 0) {
                [toString appendFormat:@"<sup%d+",i];
            }else{
                [toString appendFormat:@"<"];
            }
            [toString appendFormat:@"%@:%p>\n",className,self];
            [toString appendFormat:@"%@{\n",levalString];
            NSArray *subProperties = [propertyDic objectForKey:className];
            for (NSString *key in subProperties) {
                [toString appendString:levalString];
                id value = [self valueForKey:key];
                if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSURL class]] || [value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSNumber class]]) {
                    [toString appendFormat:@"\t%@:%@\n",key,value];
                }else if([NSStringFromClass([value class]) isEqualToString:@"NSObject"]){
                    //ignore
                }else{
                    NSString *desc = [value DEBUGDescrptionWithLeval:leval+1];
                    [toString appendFormat:@"\t%@:%@\n",key,desc];
                }
            }
            [toString appendString:levalString];
            [toString appendFormat:@"}\n"];
        }
        return [toString copy];
    }
}

@end
