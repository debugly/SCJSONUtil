//
//  SCJSONUtil.m
//
//  Created by xuqianlong on 15/9/3.
//  Copyright (c) 2015年 Mac. All rights reserved.
//

#import "SCJSONUtil.h"
#import "objc/runtime.h"

static BOOL s_SCJSONUtilLogOn = NO;

void SCJSONUtilLog(BOOL on) {
    s_SCJSONUtilLogOn = on;
}

BOOL isSCJSONUtilLogOn(void) {
    return s_SCJSONUtilLogOn;
}

#define SCJSONLog(...)   do{ \
    if (s_SCJSONUtilLogOn) { \
        NSLog(__VA_ARGS__); \
    } \
}while(0)

#define SCJSONError(...)   do{ \
    NSLog(__VA_ARGS__); \
}while(0)

typedef NS_ENUM(NSUInteger, QLPropertyType) {
    QLPropertyTypeUnknow,
    QLPropertyTypeObj       = '@',
    QLPropertyTypeFloat     = 'f',
    QLPropertyTypeDouble    = 'd',
    QLPropertyTypeBOOL      = 'B',
    QLPropertyTypeBool      = QLPropertyTypeBOOL,
    QLPropertyTypeInt8      = 'c',
    QLPropertyTypeUInt8     = 'C',
    QLPropertyTypeInt16     = 's',
    QLPropertyTypeUInt16    = 'S',
    QLPropertyTypeInt32     = 'i',
    QLPropertyTypeUInt32    = 'I',
    QLPropertyTypeLong32    = 'l', //32位机器 long 型
    QLPropertyTypeULong32   = 'L', //32位机器 unsigned long 型
    QLPropertyTypeInt64     = 'q', //32位机器 long long 类型；64位机器 long long 和 long 类型
    QLPropertyTypeUInt64    = 'Q'  //32位机器 unsigned long long 类型；64位机器 unsigned long long 和 unsigned long 类型
};

typedef struct QLPropertyDescS {
    QLPropertyType type;
    char * clazz;
} QLPropertyDesc;

#pragma mark - C  Functions  -Begin-

#pragma mark 【Utils】

static bool QLCStrEqual(char *v1,char *v2) {
    if (NULL == v1 || NULL == v2) {
        return 0;
    }
    return 0 == strcmp(v1, v2);
}

static void *QLMallocInit(size_t __size) {
    void *p = malloc(__size);
    memset(p, 0, __size);
    return p;
}

static QLPropertyDesc * QLPropertyDescForClassProperty(Class clazz,const char *key) {
    objc_property_t property = class_getProperty(clazz, key);
    if (NULL == property) {
        return NULL;
    }
    // 2.成员类型
    const char *encodedType = property_getAttributes(property);
    char *matched = strchr(encodedType, ',');
    long location = matched - encodedType;
    char fullType[location+1];
    sscanf(encodedType,"%[^,]",fullType);
    
    if (strlen(fullType)>=2) {
        const char iType = fullType[1];
        switch (iType) {
            case QLPropertyTypeObj:
            {
                //属性是对象类型，这里取出对象的类型，id取不出来；
                bool isID =  QLCStrEqual("T@", fullType);
                if (!isID) {
                    char buffer [location+1];
                    sscanf(fullType, "%*[^\"]\"%[^\"]",buffer);
                    
                    QLPropertyDesc *desc = (QLPropertyDesc *)QLMallocInit(sizeof(QLPropertyDesc));
                    char *pclazz = (char *)QLMallocInit(sizeof(buffer)+1);
                    strcpy(pclazz, buffer);
                    desc->clazz = pclazz;
                    desc->type = iType;
                    return desc;
                }
            }
                break;
            case QLPropertyTypeFloat:
            case QLPropertyTypeDouble:
            case QLPropertyTypeBOOL:
            case QLPropertyTypeInt8:
            case QLPropertyTypeUInt8:
            case QLPropertyTypeInt16:
            case QLPropertyTypeUInt16:
            case QLPropertyTypeInt32:
            case QLPropertyTypeUInt32:
            case QLPropertyTypeLong32:
            case QLPropertyTypeULong32:
            case QLPropertyTypeInt64:
            case QLPropertyTypeUInt64:
            {
                QLPropertyDesc *desc = QLMallocInit(sizeof(QLPropertyDesc));//must init!!! iphone 5 crash,clazz is empty string : '' ;
                desc->type = iType;
                return desc;
            }
                break;
                
            default: // #:^ igonre:Class,SEL,Method...
            {
                SCJSONLog(@"未识别的类型：%c",iType);
            }
                break;
        }
    }
    return NULL;
}

#pragma mark 【ValueTransfer】

static NSString * QLValueTransfer2NSString(id value) {
    return [value description];
}

static NSNumber * QLValueTransfer2NSNumber(id value) {
    if ([value isKindOfClass:[NSString class]]) {
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        return [numberFormatter numberFromString:value];
    } else if ([value isKindOfClass:[NSNumber class]]) {
        return value;
    }
    return nil;
}

static NSDecimalNumber * QLValueTransfer2NSDecimalNumber(id value) {
    if ([value isKindOfClass:[NSString class]]) {
        return [NSDecimalNumber decimalNumberWithString:value];
    }
    return nil;
}

static NSURL * QLValueTransfer2NSURL(id value) {
    if ([value isKindOfClass:[NSString class]]) {
        NSString *str = (NSString *)value;
        if ([str hasPrefix:@"file://"]) {
            str = [str stringByReplacingOccurrencesOfString:@"file://" withString:@""];
            return [NSURL fileURLWithPath:str];
        }
        return [NSURL URLWithString:str];
    }
    return nil;
}

#pragma mark C  Functions  -End-
#pragma mark -

@implementation NSObject (SCJSON2Model)

- (void)_findFromCollideKeyMap:(NSString *)serverKey
                      forValue:(id)serverValue
                    completion:(void(^)(NSString *,NSString *,id))comp
{
    id<SCJSON2ModelProtocol>_self = (id<SCJSON2ModelProtocol>)self;
    if ([_self respondsToSelector:@selector(sc_collideKeysMap)]) {
        //自定义key，覆盖服务器返回的key；并且支持keypath
        NSDictionary *map = [_self sc_collideKeysMap];
        NSString * mappedPropertyName = map[serverKey];
        //自定义了属性名，将服务器返回的值对应到自定义的属性名上
        if (mappedPropertyName) {
            if (comp) {
                comp(mappedPropertyName,serverKey,serverValue);
            }
            return;
        }
        
        __block BOOL found = NO;
        [map enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull customServerKey, NSString * _Nonnull mappedPropertyName, BOOL * _Nonnull stop) {
            //自定义了属性名，将服务器返回的值根据keypath进一步查找，然后对应到自定义的属性名上
            if ([customServerKey hasPrefix:serverKey]) {
                NSRange range = [customServerKey rangeOfString:@"."];
                if (range.location != NSNotFound) {
                    if([serverValue isKindOfClass:[NSDictionary class]]) {
                        NSString *targetKey = [customServerKey substringFromIndex:range.location + range.length];
                        id mappedValue = [serverValue valueForKeyPath:targetKey];
                        if (comp) {
                            comp(mappedPropertyName,customServerKey,mappedValue);
                        }
                        found = YES;
                    }
                }
            }
        }];
        if (!found) {
            if (comp) {
                comp(nil,serverKey,serverValue);
            }
        }
    } else {
        //默认情况下，把服务器返回的字段名，当做model的属性名
        if (comp) {
            comp(nil,serverKey,serverValue);
        }
    }
}

- (void)_resolveunDefinedKey:(NSString *)propertyName
                    forValue:(id)propertyValue
                      refObj:(id)refObj
                  completion:(void(^)(NSString *,NSString *,id))comp
                               
{
    id<SCJSON2ModelProtocol>_self = (id<SCJSON2ModelProtocol>)self;
    NSString *outPropertyName = propertyName;
    id outPropertyValue = propertyValue;
    if ([_self respondsToSelector:@selector(sc_unDefinedKey:forValue:refObj:)] && [_self sc_unDefinedKey:&outPropertyName forValue:&outPropertyValue refObj:refObj]) {
        SCJSONLog(@"mapped server key:%@->%@.%@",propertyName,NSStringFromClass([self class]),outPropertyName);
        if (outPropertyName.length > 0) {
            if (comp) {
                comp(outPropertyName,outPropertyName,outPropertyValue);
            }
            return;
        }
    } else {
        NSString *propertyClass = NSStringFromClass([propertyValue class]);
        if ([propertyClass hasPrefix:@"__"]) {
            propertyClass = NSStringFromClass([propertyValue superclass]);
        }
        SCJSONLog(@"⚠️ %@ 类没有解析 %@ 字段，请完善为 %@ * %@",NSStringFromClass([self class]),propertyName,propertyClass,propertyName);
    }
}

- (void)_resolveProperty:(NSString *)propertyName
                forValue:(id)propertyValue
                  refObj:(id)refObj
              completion:(void(^)(QLPropertyDesc *,NSString *,NSString *,id))comp
{
    [self _findFromCollideKeyMap:propertyName
                        forValue:propertyValue
                    completion:^(NSString *pName,NSString *mKey,id mValue) {
        QLPropertyDesc * pdesc = NULL;
        if (pName) {
            //通过sc_collideKeysMap提供了
            pdesc = QLPropertyDescForClassProperty([self class], [pName UTF8String]);
        } else {
            pdesc = QLPropertyDescForClassProperty([self class], [propertyName UTF8String]);
        }
        
        if (pdesc) {
            if (pName) {
                comp(pdesc,pName,mKey,mValue);
            } else {
                comp(pdesc,propertyName,propertyName,propertyValue);
            }
        } else {
            //获取属性类型，获取不到时走 sc_unDefinedKey 来补救
            [self _resolveunDefinedKey:propertyName
                              forValue:propertyValue
                                refObj:refObj
                            completion:^(NSString *aName,NSString *aKey,id aValue) {
                if (aName) {
                    QLPropertyDesc * pdesc = QLPropertyDescForClassProperty([self class], [aName UTF8String]);
                    if (pdesc) {
                        comp(pdesc,aName,aKey,aValue);
                    }
                }
            }];
        }
    }];
}

- (void)sc_autoMatchValue:(id)serverValue
                   forKey:(NSString *)serverKey
                   refObj:(id)refObj
{
    //1、默认情况下，把服务器返回的字段名，当做 model 的属性名
//    __block NSString *propertyName = serverKey;
//    __block NSString *modelKey = serverKey;
//    __block id mappedValue = serverValue;
//    __block QLPropertyDesc * pdesc = NULL;
    //2、处理自定义属性名
    [self _resolveProperty:serverKey
                  forValue:serverValue
                    refObj:refObj
                completion:^(QLPropertyDesc *pdesc,NSString *propertyName,NSString *modelKey,id mappedValue) {
        //有这个属性
        if (pdesc) {
            id<SCJSON2ModelProtocol> instance = (id<SCJSON2ModelProtocol>)self;
            
            //3、进行自动匹配赋值之前，再给客户端一次机会，可根据业务逻辑自行处理
            if ([instance respondsToSelector:@selector(sc_key:beforeAssignedValue:refObj:)]) {
                mappedValue = [instance sc_key:propertyName beforeAssignedValue:mappedValue refObj:refObj];
            }
            
            do {
                //4、进入类型自动匹配流程
                if ([mappedValue isKindOfClass:[NSArray class]]) {
                    //4.1、匹配数组类型
                    if (pdesc->type == QLPropertyTypeObj && (QLCStrEqual((char *)pdesc->clazz, "NSMutableArray") || QLCStrEqual((char *)pdesc->clazz, "NSArray") )) {
                        //获取model名字
                        NSString *modleName = nil;
                        if ([instance respondsToSelector:@selector(sc_collideKeyModelMap)]) {
                            modleName = [[instance sc_collideKeyModelMap]objectForKey:modelKey];
                        }
                        
                        NSArray *objs = nil;
                        if (modleName) {
                            Class clazz = NSClassFromString(modleName);
                            if (clazz) {
                                objs = [clazz sc_instanceArrFormArray:mappedValue];
                            } else {
                                SCJSONLog(@"⚠️⚠️[%@ Class] is undefined!",modleName);
                                break;
                            }
                        } else {
                            objs = [NSArray arrayWithArray:mappedValue];
                        }
                        
                        char * pclazz = pdesc->clazz;
                        // 如果属性是可变的，那么做个可变处理
                        if (QLCStrEqual(pclazz, "NSMutableArray")) {
                            objs = [NSMutableArray arrayWithArray:objs];
                        }
                        if (objs) {
                            [self setValue:objs forKey:propertyName];
                        }
                    } else {
                        // model 属性不是 NSMutableArray/NSArray，无法处理！默认忽略掉！
                        SCJSONLog(@"⚠️⚠️ %@ 类的 %@ 属性类型跟服务器返回类型不匹配，无法解析！请修改为NSArray * %@; 或者 NSMutableArray * %@;",NSStringFromClass([self class]),serverKey,serverKey,serverKey);
                    }
                }
                // 4.2、匹配字典类型
                else if ([mappedValue isKindOfClass:[NSDictionary class]]) {
                    // 如果class类型是字典类型则默认不执行内部解析，直接返回json数据，否则执行内层解析
                    if (pdesc->type == QLPropertyTypeObj) {
                        if (QLCStrEqual((char *)pdesc->clazz, "NSMutableDictionary")) {
                            [self setValue:[mappedValue mutableCopy] forKey:propertyName];
                        } else if (QLCStrEqual((char *)pdesc->clazz, "NSDictionary")) {
                            [self setValue:mappedValue forKey:propertyName];
                        } else {
                            Class clazz = objc_getClass(pdesc->clazz);
                            if (clazz) {
                                id value = [clazz sc_instanceFormDic:mappedValue];
                                if (value) {
                                    [self setValue:value forKey:propertyName];
                                } else {
                                    SCJSONLog(@"⚠️⚠️ %@ 类的 %@ 属性类型跟服务器返回的值 %@ 类型不法匹配！请修改为NSDictionary * %@; 或者 NSMutableDictionary * %@;",NSStringFromClass([self class]),propertyName,mappedValue,propertyName,propertyName);
                                }
                            }
                        }
                    } else {
                        SCJSONLog(@"⚠️⚠️ %@ 类的 %@ 属性类型跟服务器返回的值 %@ 类型不法匹配！请修改为NSDictionary * %@; 或者 NSMutableDictionary * %@;",NSStringFromClass([self class]),propertyName,mappedValue,propertyName,propertyName);
                    }
                }
                // 4.3、匹配非NULL类型
                else if (![mappedValue isKindOfClass:[NSNull class]]) {
                    //自定义对象或者系统的NSStirng，NSNumber等；
                    switch (pdesc->type) {
                        case QLPropertyTypeObj:
                        {
                            const char *dclazz = pdesc->clazz;
                            //目标类型是id，无法处理直接赋值；
                            if (!dclazz) {
                                [self setValue:mappedValue forKey:propertyName];
                                break;
                            }
                            const char *vclazz = object_getClassName(mappedValue);
                            //目标类型和值类型相同，则直接赋值
                            if (QLCStrEqual((char *)dclazz, (char *)vclazz)) {
                                [self setValue:mappedValue forKey:propertyName];
                            } else if (QLCStrEqual((char *)dclazz, "NSString")) {
                                //目标类型是NSString
                                NSString *value = QLValueTransfer2NSString(mappedValue);
                                [self setValue:value forKey:propertyName];
                            } else if (QLCStrEqual((char *)dclazz, "NSMutableString")) {
                                //目标类型是NSMutableString
                                NSString *value = QLValueTransfer2NSString(mappedValue);
                                value = [NSMutableString stringWithString:value];
                                [self setValue:value forKey:propertyName];
                            } else if (QLCStrEqual((char *)dclazz, "NSNumber")) {
                                //目标类型是NSNumber
                                NSNumber *value = QLValueTransfer2NSNumber(mappedValue);
                                [self setValue:value forKey:propertyName];
                            } else if (QLCStrEqual((char *)dclazz, "NSDecimalNumber")) {
                                //目标类型是NSDecimalNumber
                                NSDecimalNumber *value = QLValueTransfer2NSDecimalNumber(mappedValue);
                                [self setValue:value forKey:propertyName];
                            } else if (QLCStrEqual((char *)dclazz, "NSURL")) {
                                //目标类型是NSURL
                                NSURL *value = QLValueTransfer2NSURL(mappedValue);
                                [self setValue:value forKey:propertyName];
                            }
                        }
                            break;
                        //因为kvc本身需要的value是id类型，所以对于基本数据类型不处理，而是交给系统 KVC 处理;
                        case QLPropertyTypeFloat:
                        case QLPropertyTypeDouble:
                        case QLPropertyTypeBOOL:
                        case QLPropertyTypeInt8:
                        case QLPropertyTypeUInt8:
                        case QLPropertyTypeInt16:
                        case QLPropertyTypeUInt16:
                        case QLPropertyTypeInt32:
                        case QLPropertyTypeUInt32:
                        case QLPropertyTypeLong32:
                        case QLPropertyTypeULong32:
                        case QLPropertyTypeInt64:
                        case QLPropertyTypeUInt64:
                        {
                            NSNumber *numberValue = mappedValue;
                            //ios 8, -[__NSCFString longValue]: unrecognized selector
                            if ([numberValue isKindOfClass:[NSString class]]) {
                                numberValue = QLValueTransfer2NSNumber(mappedValue);
                            }
                            //could not set nil as the value for the scalar key(int,float,...)
                            if (numberValue) {
                                [self setValue:numberValue forKey:propertyName];
                            }
                        }
                            break;
                        default:
                            break;
                    }
                }
            } while (0);
            
            //5、释放内存
            if (NULL != pdesc) {
                if (NULL != pdesc->clazz) {
                    free((void *)pdesc->clazz);
                    pdesc->clazz = NULL;
                }
                free(pdesc);
                pdesc = NULL;
            }
        }
    }];
}

- (void)sc_assembleDataFormDic:(NSDictionary *)dic
{
    [self sc_assembleDataFormDic:dic refObj:nil];
}

- (void)sc_assembleDataFormDic:(NSDictionary *)dic refObj:(id)refObj
{
    [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self sc_autoMatchValue:obj forKey:key refObj:refObj];
    }];
    
    id<SCJSON2ModelProtocol> instance = (id<SCJSON2ModelProtocol>)self;
    if ([instance respondsToSelector:@selector(sc_willFinishConvert:refObj:)]) {
        [instance sc_willFinishConvert:dic refObj:refObj];
    }
}

+ (id)sc_instanceFromValue:(id)json refObj:(id)refObj
{
    if ([json isKindOfClass:[NSDictionary class]]) {
        NSObject *obj = [[self alloc]init];
        [obj sc_assembleDataFormDic:json refObj:refObj];
        return obj;
    }
    if ([json isKindOfClass:[NSArray class]]) {
        NSArray *jsonArr = json;
        
        if (!jsonArr || jsonArr.count == 0) {
            return nil;
        }
        
        NSMutableArray *modelArr = [[NSMutableArray alloc]initWithCapacity:3];
        [jsonArr enumerateObjectsUsingBlock:^(id json, NSUInteger idx, BOOL *stop) {
            id instance = [self sc_instanceFromValue:json refObj:refObj];
            if (instance) {
                [modelArr addObject:instance];
            } else {
                SCJSONError(@"WTF?无法将该[%@]转为[%@]",json,NSStringFromClass([self class]));
            }
        }];
        return [NSArray arrayWithArray:modelArr];
    }
    if ([self class] == [NSNumber class]) {
        return QLValueTransfer2NSNumber(json);
    }
    if ([self class] == [NSString class]) {
        return QLValueTransfer2NSString(json);
    }
    if ([self class] == [NSURL class]) {
        return QLValueTransfer2NSURL(json);
    }
    if ([self class] == [NSDecimalNumber class]) {
        return QLValueTransfer2NSDecimalNumber(json);
    }
    SCJSONError(@"无法将该[%@]转为[%@]",json,NSStringFromClass([self class]));
    return nil;
}

+ (id)sc_instanceFromValue:(id)json
{
    return [self sc_instanceFromValue:json refObj:nil];
}

+ (instancetype)sc_instanceFormDic:(NSDictionary *)jsonDic
{
    return [self sc_instanceFromValue:jsonDic];
}

+ (NSArray *)sc_instanceArrFormArray:(NSArray *)jsonArr
{
    return [self sc_instanceFromValue:jsonArr];
}

@end

#pragma mark - JOSNUtil public c functions

id SCFindJSONwithKeyPathArr(NSArray *pathArr,NSDictionary *json){
    if (!json) {
        return nil;
    }
    if (!pathArr || pathArr.count == 0) {
        return json;
    }
    NSMutableArray *pathArr2 = [NSMutableArray arrayWithArray:pathArr];
    
    while ([pathArr2 firstObject] && [[pathArr2 firstObject] description].length == 0) {
        [pathArr2 removeObjectAtIndex:0];
    }
    if ([pathArr2 firstObject]) {
        json = [json objectForKey:[pathArr2 firstObject]];
        [pathArr2 removeObjectAtIndex:0];
        return SCFindJSONwithKeyPathArr(pathArr2, json);
    } else {
        return json;
    }
}

id SCFindJSONwithKeyPathV2(NSString *keyPath,NSDictionary *JSON,NSString *separator){
    if (!keyPath || keyPath.length == 0) {
        return JSON;
    }
    if (!separator) {
        separator = @"";
    }
    NSArray *pathArr = [keyPath componentsSeparatedByString:separator];
    return SCFindJSONwithKeyPathArr(pathArr, JSON);
}

id SCFindJSONwithKeyPath(NSString *keyPath,NSDictionary *json){
    return SCFindJSONwithKeyPathV2(keyPath, json, @"/");
}

id SCJSON2ModelV2(id json,NSString *modelName,id refObj){
    Class clazz = NSClassFromString(modelName);
    return [clazz sc_instanceFromValue:json refObj:refObj];
}

id SCJSON2Model(id json,NSString *modelName){
    return SCJSON2ModelV2(json, modelName, nil);
}
