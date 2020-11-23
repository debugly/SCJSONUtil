//
//  SCModelUtil.m
//  SCJSONUtil
//
//  Created by qianlongxu on 2020/11/15.
//

#import "SCModelUtil.h"
#import "objc/runtime.h"
#import "scutil.h"

@implementation NSObject (SCModel2JSON)

- (NSArray *)sc_propertyNames
{
    NSArray *ignoreArr = @[@"superclass", @"description", @"debugDescription", @"hash"];
    
    NSArray *(^propertiesForClass)(Class clazz) = ^ NSArray * (Class clazz) {
        unsigned int count = 0;
        objc_property_t *properties = class_copyPropertyList(clazz, &count);
        NSMutableArray *propertyNames = [NSMutableArray array];
        for (int i = 0; i < count; i++) {
            NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
            if (key) {
                if ([ignoreArr containsObject:key]) {
                    continue;
                }
                [propertyNames addObject:key];
            }
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

- (id)sc_toJSON
{
    return [self sc_toJSONWithProperyType:NO];
}

- (id)sc_toJSONWithProperyType:(BOOL)printProperyType
{
    if ([self isKindOfClass:[NSArray class]]) {
        NSMutableArray *json = [NSMutableArray array];
        NSArray *arr = (NSArray *)self;
        for (NSObject *obj in arr) {
            id o = [obj sc_toJSONWithProperyType:printProperyType];
            if (o) {
                [json addObject:o];
            }
        }
        return [json copy];
    } else if ([self isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *json = [NSMutableDictionary dictionary];
        NSDictionary *dic = (NSDictionary *)self;
        [dic enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
            id o = [obj sc_toJSONWithProperyType:printProperyType];
            if (o) {
                [json setObject:o forKey:key];
            }
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
    } else {
        NSArray *propertiesForClass = [self sc_propertyNames];
        NSMutableDictionary *json = [NSMutableDictionary dictionary];
        for (NSDictionary *propertyDic in propertiesForClass) {
            NSArray *properties = [propertyDic objectForKey:@"property"];
            for (NSString *property in properties) {
                id propertyValue = [self valueForKey:property];
                NSString *aKey = property;
                if (printProperyType) {
                    aKey = [NSString stringWithFormat:@"%@ %@",[self sc_typeForProperty:property],property];
                }
                id obj = [propertyValue sc_toJSONWithProperyType:printProperyType];
                if (obj) {
                    [json setObject:obj forKey:aKey];
                }
            }
        }
        return json;
    }
}

@end
