//
//  NSObject+PrintProperties.m
//  QLJSON2Model
//
//  Created by qianlongxu on 15/11/25.
//  Copyright © 2015年 xuqianlong. All rights reserved.
//

#import "NSObject+PrintProperties.h"
#import "objc/runtime.h"

static bool QLCStrEqual(char *v1,char *v2) {
    if (NULL == v1 || NULL == v2) {
        return 0;
    }
    return 0 == strcmp(v1, v2);
}

@implementation NSObject (PrintProperties)

- (NSArray *)sc_propertyNames
{
    NSArray *ignoreArr = @[@"superclass", @"description", @"debugDescription", @"hash"];
    
    NSArray *(^propertiesForClass)(Class clazz) = ^ NSArray * (Class clazz) {
        unsigned int count = 0;
        objc_property_t *properties = class_copyPropertyList(clazz, &count);
        NSMutableArray *propertyNames = [NSMutableArray array];
        for (int i = 0; i < count; i++) {
            NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
            if ([ignoreArr containsObject:key]) {
                continue;
            }
            [propertyNames addObject:key];
        }
        free(properties);
        return propertyNames;
    };
    
    NSMutableArray *properties = [NSMutableArray array];
    Class supclass = [self class];
    do {
        NSMutableDictionary *propertyDic = [NSMutableDictionary dictionary];
        [propertyDic setObject:propertiesForClass(supclass) forKey:@"property"];
        [propertyDic setObject:NSStringFromClass(supclass) forKey:@"name"];
        [properties addObject:propertyDic];
        supclass = [supclass superclass];
    } while (supclass != [NSObject class]);
    
    return [properties copy];
}

- (NSString *)sc_typeForProperty:(NSString *)name
{
    objc_property_t property = class_getProperty([self class], [name UTF8String]);
    if (NULL == property) {
        return NULL;
    }
    // 2.成员类型
    const char *encodedType = property_getAttributes(property);
    //TB,N,V_boolType
    //T@"NSString",C,N,V_stringType
    //T@,&,N,V_idType
    char *comma = strchr(encodedType, ',');
    int bufferLen = (int)(comma - encodedType + 1);
    char fullType[bufferLen];
    bzero(fullType, bufferLen);
    sscanf(encodedType,"%[^,]",fullType);
    
    if (strlen(fullType)>=2) {
        const char iType = fullType[1];
        switch (iType) {
            case '@':
            {
                //属性是对象类型，这里取出对象的类型，id取不出来；
                bool isID = QLCStrEqual("T@", fullType);
                if (isID) {
                    return @"id";
                } else {
                    char buffer [bufferLen + 1];
                    bzero(buffer, bufferLen + 1);
                    sscanf(fullType, "%*[^\"]\"%[^\"]",buffer);
                    buffer[strlen(buffer)] = '*';
                    return [[NSString alloc]initWithCString:buffer encoding:NSUTF8StringEncoding];
                }
            }
                break;
            case 'f':
            {
                return @"float";
            }
            case 'd':
            {
                return @"double";
            }
            case 'B':
            {
                return @"BOOL";
            }
            case 'c':
            {
                return @"char";
            }
            case 'C':
            {
                return @"unsigned char";
            }
            case 's':
            {
                return @"short";
            }
            case 'S':
            {
                return @"unsigned short";
            }
            case 'i':
            {
                return @"int";
            }
            case 'I':
            {
                return @"unsigned int";
            }
            case 'l':
            {
                return @"long";
            }
            case 'L':
            {
                return @"unsigned long";
            }
            case 'q':
            {
                return @"long long";
            }
            case 'Q':
            {
                return @"unsigned long long";
            }
            default: // #:^ igonre:Class,SEL,Method...
            {
                return @"unknown";
            }
                break;
        }
    }
    return @"unknown";
}

- (NSString *)sc_calssName
{
    NSString *clazz = NSStringFromClass([self class]);
    if ([clazz hasPrefix:@"__"]) {
        clazz = NSStringFromClass([self superclass]);
    }
    if ([clazz isEqualToString:@"NSTaggedPointerString"]) {
        clazz = NSStringFromClass([[self superclass]superclass]);
    }
    return clazz;
}

- (id)sc_allPropertiesToJSON
{
    if ([self isKindOfClass:[NSArray class]]) {
        NSMutableArray *json = [NSMutableArray array];
        NSArray *arr = (NSArray *)self;
        for (NSObject *obj in arr) {
            [json addObject:[obj sc_allPropertiesToJSON]];
        }
        return [json copy];
    } else if ([self isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *json = [NSMutableDictionary dictionary];
        NSDictionary *dic = (NSDictionary *)self;
        [dic enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
            [json setObject:[obj sc_allPropertiesToJSON] forKey:key];
        }];
        return [json copy];
    } else if ([self isKindOfClass:[NSNumber class]]) {
        return self;
    } else if ([self isKindOfClass:[NSNull class]]) {
        return [self description];
    } else if ([self isKindOfClass:[NSURL class]]) {
        NSURL *url = (NSURL *)self;
        return [url absoluteString];
    } else if ([self isKindOfClass:[NSString class]]) {
        return [self description];
    } else if ([self isKindOfClass:[NSDate class]]) {
        return [self description];
    } else{
        NSArray *propertiesForClass = [self sc_propertyNames];
        NSMutableDictionary *json = [NSMutableDictionary dictionary];
        for (int i = 0; i < propertiesForClass.count; i++) {
            NSMutableDictionary *propertyDic = propertiesForClass[i];
            NSArray *properties = [propertyDic objectForKey:@"property"];
            for (NSString *property in properties) {
                id propertyValue = [self valueForKey:property];
                NSString *aKey = [NSString stringWithFormat:@"%@ %@",[self sc_typeForProperty:property],property];
                [json setObject:[propertyValue sc_allPropertiesToJSON] forKey:aKey];
            }
        }
        return json;
    }
}

- (NSString *)sc_printAllProperties
{
    NSDictionary *dic = [self sc_allPropertiesToJSON];
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted|1UL << 3 error:nil];
    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"%@* %p:\n%@",[self sc_calssName],self,jsonStr];
}

@end
