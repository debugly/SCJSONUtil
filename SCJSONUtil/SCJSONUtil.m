//
//  SCJSONUtil.m
//
//  Created by xuqianlong on 15/9/3.
//  Copyright (c) 2015年 Mac. All rights reserved.
//

#import "SCJSONUtil.h"
#import "objc/runtime.h"
#import "scutil.h"

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
    QLPropertyTypeId        = '*',
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

static void *QLMallocInit(size_t __size) {
    void *p = malloc(__size);
    memset(p, 0, __size);
    return p;
}

static QLPropertyDesc * QLPropertyDescForClassProperty(Class clazz, const char *key) {
    objc_property_t property = class_getProperty(clazz, key);
    if (NULL == property) {
        return NULL;
    }
    // 2.成员类型
    const char *encodedType = property_getAttributes(property);
    //TB,N,V_boolType
    //T@"NSString",C,N,V_stringType
    //T@,&,N,V_idType
    //T@"NSString",R,C description debugDescription
    //T#,R  superclass
    //TQ,R  hash
    NSString *encodedStr = [[NSString alloc] initWithCString:encodedType encoding:NSUTF8StringEncoding];
    NSArray *items = [encodedStr componentsSeparatedByString:@","];
    //skip the readonly property. fix [<OCTypes 0x600000e9e880> setValue:forUndefinedKey:]: this class is not key value coding-compliant for the key description.'
    if ([items containsObject:@"R"]) {
        return NULL;
    }

    NSString *varFullType = [items firstObject];
    
    if (varFullType.length >= 2) {
        const char iType = [varFullType characterAtIndex:1];
        switch (iType) {
            case QLPropertyTypeObj:
            {
                //属性是对象类型，这里取出对象的类型，id取不出来；
                bool isID = [@"T@" isEqualToString:varFullType];
                if (isID) {
                    QLPropertyDesc *desc = (QLPropertyDesc *)QLMallocInit(sizeof(QLPropertyDesc));
                    desc->type = QLPropertyTypeId;
                    return desc;
                } else {
                    NSString *varType = [varFullType substringFromIndex:2];
                    varType = [varType stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                    QLPropertyDesc *desc = (QLPropertyDesc *)QLMallocInit(sizeof(QLPropertyDesc));
                    char *pclazz = (char *)QLMallocInit(varType.length + 1);
                    strcpy(pclazz, varType.UTF8String);
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
                SCJSONLog(@"unrecognized type:%c",iType);
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

- (void)sc_findPropertyFromCollideKeyMap:(NSString *)serverKey
                                forValue:(id)serverValue
                              completion:(void(^)(NSString *, NSString *,id))comp
{
    id<SCJSON2ModelProtocol>_self = (id<SCJSON2ModelProtocol>)self;
    if ([_self respondsToSelector:@selector(sc_collideKeysMap)]) {
        NSDictionary *map = [_self sc_collideKeysMap];
        NSString * mappedName = map[serverKey];
        //严格匹配上了，意味着很明确要映射
        if (mappedName) {
            if (comp) {
                //此时仍然使用 serverKey 作为后续的查询 Model 类名的 key
                comp(mappedName,serverKey,serverValue);
            }
            return;
        }
        //下面是支持 keypath 查找的逻辑
        __block BOOL matched = NO;
        [map enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull customServerKey, NSString * _Nonnull mappedPropertyName, BOOL * _Nonnull stop) {
            //自定义了属性名，将服务器返回的值根据keypath进一步查找，然后对应到自定义的属性名上
            if ([customServerKey hasPrefix:serverKey]) {
                NSRange range = [customServerKey rangeOfString:@"."];
                if (range.location != NSNotFound) {
                    if([serverValue isKindOfClass:[NSDictionary class]]) {
                        NSString *targetKey = [customServerKey substringFromIndex:range.location + range.length];
                        id mappedValue = [serverValue valueForKeyPath:targetKey];
                        //确定一个keypath查找就invoke下；但仍旧继续遍历，以处理通过多个 keypath 查找同一个字段下的多个子字段情况 @{@"data.a":"a",@"data.b":"b"}
                        if (comp) {
                            comp(mappedPropertyName,customServerKey,mappedValue);
                        }
                        matched = YES;
                    }
                }
            }
        }];
        //遍历完了还没匹配上，说明没有配置映射
        if (!matched) {
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

- (void)sc_resolveunDefinedKey:(NSString *)propertyName
                      forValue:(id)propertyValue
                        refObj:(id)refObj
                    completion:(void(^)(NSString *, NSString *,id))comp
{
    NSString *outName = propertyName;
    id outValue = propertyValue;
    
    id<SCJSON2ModelProtocol>_self = (id<SCJSON2ModelProtocol>)self;
    if ([_self respondsToSelector:@selector(sc_unDefinedKey:forValue:refObj:)] && [_self sc_unDefinedKey:&outName forValue:&outValue refObj:refObj]) {
        SCJSONLog(@"mapped server key:%@->%@.%@",propertyName,NSStringFromClass([self class]),outName);
        if (outName.length > 0) {
            if (comp) {
                //此时使用自定义映射属性名 outName 作为后续的查询 Model 类名的 key
                comp(outName,outName,outValue);
            }
            return;
        }
    } else {
        NSString *propertyClass = NSStringFromClass([propertyValue class]);
        if ([propertyClass hasPrefix:@"__"]) {
            propertyClass = NSStringFromClass([propertyValue superclass]);
        }
        SCJSONLog(@"igonred %@.%@,add property use %@ * %@",NSStringFromClass([self class]),propertyName,propertyClass,propertyName);
    }
}

- (void)sc_resolveProperty:(NSString *)propertyName
                  forValue:(id)propertyValue
                    refObj:(id)refObj
                completion:(void(^)(QLPropertyDesc *, NSString *, NSString *,id))comp
{
    /*
     为了支持 keypath 查找，只能优先查找 sc_collideKeysMap，否则会出现类型不匹配，出现没解析的情况！
     比如：{@"activity.on" : @"activity"}
     */
    [self sc_findPropertyFromCollideKeyMap:propertyName
                                  forValue:propertyValue
                                completion:^(NSString *pName, NSString *mKey, id mValue) {
        QLPropertyDesc * pdesc = NULL;
        if (pName) {
            //通过sc_collideKeysMap提供了
            pdesc = QLPropertyDescForClassProperty([self class], [pName UTF8String]);
        } else {
            //当sc_collideKeysMap没提供时，就把服务区返回字段当做 Model 属性名进行试探
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
            [self sc_resolveunDefinedKey:propertyName
                                forValue:propertyValue
                                  refObj:refObj
                              completion:^(NSString *aName,NSString *aKey,id aValue) {
                if (aName) {
                    QLPropertyDesc * pdesc = QLPropertyDescForClassProperty([self class], [aName UTF8String]);
                    //补救的属性存在?
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
    //1、处理属性名（顺序:根据sc_collideKeysMap获取;服务器返回的字段名;通过sc_unDefinedKey方法）
    [self sc_resolveProperty:serverKey
                    forValue:serverValue
                      refObj:refObj
                  completion:^(QLPropertyDesc *pdesc,NSString *propertyName,NSString *modelKey,id mappedValue) {
        if (pdesc) {
            //属性描述不空，则表示有这个属性
            id<SCJSON2ModelProtocol> instance = (id<SCJSON2ModelProtocol>)self;
            
            //2、进行自动匹配赋值之前，再给客户端一次机会，可根据业务逻辑自行处理
            if ([instance respondsToSelector:@selector(sc_key:beforeAssignedValue:refObj:)]) {
                mappedValue = [instance sc_key:propertyName beforeAssignedValue:mappedValue refObj:refObj];
            }
            
            //3、进入类型自动匹配流程
            do {
                //属性是 id 类型时，无法进行值的类型匹配
                if (pdesc->type == QLPropertyTypeId) {
                    if (mappedValue) {
                        [self setValue:mappedValue forKey:propertyName];
                    }
                    break;
                }
                
                //3.1、匹配数组类型
                if ([mappedValue isKindOfClass:[NSArray class]]) {
                    
                    if (pdesc->type == QLPropertyTypeObj && (QLCStrEqual((char *)pdesc->clazz, "NSMutableArray") || QLCStrEqual((char *)pdesc->clazz, "NSArray") )) {
                        //优先从 collideKeyModelMap 获取 Model 类名
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
                                SCJSONLog(@"⚠️⚠️⚠️[%@ Class] is undefined!",modleName);
                                break;
                            }
                        } else {
                            //当获取不到 Model 类名时不解析
                            objs = [NSArray arrayWithArray:mappedValue];
                        }
                        
                        char * pclazz = pdesc->clazz;
                        //如果属性是可变的，那么做个可变处理
                        if (QLCStrEqual(pclazz, "NSMutableArray")) {
                            objs = [NSMutableArray arrayWithArray:objs];
                        }
                        if (objs) {
                            [self setValue:objs forKey:propertyName];
                        }
                    } else {
                        //忽略掉 Model 属性不是 NSMutableArray/NSArray 的情况
                        SCJSONLog(@"⚠️⚠️ %@.%@ may be: (%@*)%@",NSStringFromClass([self class]),propertyName,NSStringFromClass([mappedValue class]),propertyName);
                    }
                }
                //3.2、匹配字典类型
                else if ([mappedValue isKindOfClass:[NSDictionary class]]) {
                    //如果 property 是字典类型则直接赋值，否则执行 model 解析
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
                                }
                            }
                        }
                    } else {
                        //忽略掉 Model 属性不是 NSMutableDictionary/NSDictionary 的情况
                        SCJSONLog(@"⚠️⚠️ %@.%@ may be: (%@*)%@",NSStringFromClass([self class]),propertyName,NSStringFromClass([mappedValue class]),propertyName);
                    }
                }
                //3.3、匹配非 NULL 类型
                else if (![mappedValue isKindOfClass:[NSNull class]]) {
                    //简单非空类型 id,NSStirng,NSNumber,int,bool,float...
                    switch (pdesc->type) {
                        case QLPropertyTypeObj:
                        {
                            id r = nil;
                            const char *pClazz = pdesc->clazz;
                            //目标类型可能是id类型，直接赋值
                            if (!pClazz) {
                                r = mappedValue;
                            } else if (QLCStrEqual((char *)pClazz, (char *)object_getClassName(mappedValue))) {
                                //目标类型和值类型相同，则直接赋值
                                r = mappedValue;
                            } else if (QLCStrEqual((char *)pClazz, "NSString")) {
                                //目标类型是NSString
                                r = QLValueTransfer2NSString(mappedValue);
                            } else if (QLCStrEqual((char *)pClazz, "NSMutableString")) {
                                //目标类型是NSMutableString
                                NSString *value = QLValueTransfer2NSString(mappedValue);
                                r = [NSMutableString stringWithString:value];
                            } else if (QLCStrEqual((char *)pClazz, "NSNumber")) {
                                //目标类型是NSNumber
                                r = QLValueTransfer2NSNumber(mappedValue);
                            } else if (QLCStrEqual((char *)pClazz, "NSDecimalNumber")) {
                                //目标类型是NSDecimalNumber
                                r = QLValueTransfer2NSDecimalNumber(mappedValue);
                            } else if (QLCStrEqual((char *)pClazz, "NSURL")) {
                                //目标类型是NSURL
                                r = QLValueTransfer2NSURL(mappedValue);
                            } else {
                                SCJSONError(@"unrecognized type (%s)%@ for (%@)",pClazz,propertyName,NSStringFromClass([mappedValue class]));
                            }
                            
                            if (r) {
                                [self setValue:r forKey:propertyName];
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
            
            //4、释放内存
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
                SCJSONError(@"WTF?can't convert json [%@] to [%@]",json,NSStringFromClass([self class]));
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
    SCJSONError(@"can't convert json [%@] to [%@]",json,NSStringFromClass([self class]));
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

id SCFindJSONwithKeyPathArr(NSArray *pathArr, NSDictionary *json){
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

id SCFindJSONwithKeyPathV2(NSString *keyPath, NSDictionary *JSON, NSString *separator){
    if (!keyPath || keyPath.length == 0) {
        return JSON;
    }
    if (!separator) {
        separator = @"";
    }
    NSArray *pathArr = [keyPath componentsSeparatedByString:separator];
    return SCFindJSONwithKeyPathArr(pathArr, JSON);
}

id SCFindJSONwithKeyPath(NSString *keyPath, NSDictionary *json){
    return SCFindJSONwithKeyPathV2(keyPath, json, @"/");
}

id SCJSON2ModelV2(id json, NSString *modelName, id refObj){
    Class clazz = NSClassFromString(modelName);
    return [clazz sc_instanceFromValue:json refObj:refObj];
}

id SCJSON2Model(id json, NSString *modelName){
    return SCJSON2ModelV2(json, modelName, nil);
}

NSString *JSON2String(id json, BOOL prettyPrinted) {
    if (@available(iOS 13.0,macos 10.15, watchos 6.0, tvos 13.0, *)) {
        NSJSONWritingOptions opts = NSJSONWritingWithoutEscapingSlashes;
        if (prettyPrinted) {
            opts |= NSJSONWritingPrettyPrinted;
        }
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:opts error:nil];
        if (data) {
            return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    } else {
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:prettyPrinted ? NSJSONWritingPrettyPrinted:0 error:nil];
        if (data) {
            NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            return [jsonStr stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
        }
    }
    return nil;
}
