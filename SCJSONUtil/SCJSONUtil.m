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

- (void)sc_autoMatchValue:(id)obj
                   forKey:(NSString *)serverKey
                   refObj:(id)refObj
{
    id<SCJSON2ModelProtocol> instance = (id<SCJSON2ModelProtocol>)self;
    NSString *mapedKey = serverKey; //服务器返回的key
    if ([instance respondsToSelector:@selector(sc_collideKeysMap)]) {
        // 自定义key，覆盖服务器返回的key
        mapedKey = [[instance sc_collideKeysMap]objectForKey:serverKey] ?: serverKey;
    }
    
    // 获取属性类型
    QLPropertyDesc * pdesc = NULL;
    
    pdesc = QLPropertyDescForClassProperty([self class], [mapedKey UTF8String]);
    if (NULL == pdesc) {
        // Model 里没有定义 key 这个属性
        if ([instance respondsToSelector:@selector(sc_unDefinedKey:forValue:refObj:)] && [instance sc_unDefinedKey:&mapedKey forValue:&obj refObj:refObj]) {
            SCJSONLog(@"重新定义了key或者value");
            //改变key值！！
            serverKey = mapedKey;
            pdesc = QLPropertyDescForClassProperty([self class], [mapedKey UTF8String]);
        } else {
            NSString *objClass = NSStringFromClass([obj class]);
            if ([objClass hasPrefix:@"__"]) {
                objClass = NSStringFromClass([obj superclass]);
            }
            SCJSONLog(@"⚠️ %@ 类没有解析 %@ 字段，请完善为 %@ * %@",NSStringFromClass([self class]),serverKey,objClass,serverKey);
            return;
        }
    }
    
    if (NULL == pdesc) {
        return;
    }
    
    //处理之前给客户端一次对值处理的机会，做一些业务逻辑！
    if ([instance respondsToSelector:@selector(sc_key:beforeAssignedValue:refObj:)]) {
        obj = [instance sc_key:mapedKey beforeAssignedValue:obj refObj:refObj];
    }
    
    if ([obj isKindOfClass:[NSArray class]]) {
        //匹配目标类型
        if (pdesc->type == QLPropertyTypeObj && (QLCStrEqual((char *)pdesc->clazz, "NSMutableArray") || QLCStrEqual((char *)pdesc->clazz, "NSArray") )) {
            
            NSString *modleName = nil;
            if ([instance respondsToSelector:@selector(sc_collideKeyModelMap)]) {
                modleName = [[instance sc_collideKeyModelMap]objectForKey:serverKey];
            }
            
            NSArray *objs = nil;
            
            if (modleName) {
                Class clazz = NSClassFromString(modleName);
                objs = [clazz sc_instanceArrFormArray:obj];
            } else {
                objs = [NSArray arrayWithArray:obj];
                SCJSONLog(@"⚠️⚠️ %@ 类的 %@ 属性没有指定model类名，这会导致解析后数组里的值是原始值，并非model对象！可以通过 sc_collideKeyModelMap 指定 @{@\"%@\":@\"%@\"}",NSStringFromClass([self class]),serverKey,serverKey,@"XyzModel");
            }
            
            char * pclazz = pdesc->clazz;
            // 如果属性是可变的，那么做个可变处理
            if (QLCStrEqual(pclazz, "NSMutableArray")) {
                objs = [NSMutableArray arrayWithArray:objs];
            }
            [self setValue:objs forKey:mapedKey];
        } else {
            // model 属性不是 NSMutableArray/NSArray，无法处理！默认忽略掉！
            SCJSONLog(@"⚠️⚠️ %@ 类的 %@ 属性类型跟服务器返回类型不匹配，无法解析！请修改为NSArray * %@; 或者 NSMutableArray * %@;",NSStringFromClass([self class]),serverKey,serverKey,serverKey);
        }
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        // 如果class类型是字典类型则默认不执行内部解析，直接返回json数据，否则执行内层解析
        if (pdesc->type == QLPropertyTypeObj) {
            if (QLCStrEqual((char *)pdesc->clazz, "NSMutableDictionary")) {
                [self setValue:[obj mutableCopy] forKey:mapedKey];
            } else if (QLCStrEqual((char *)pdesc->clazz, "NSDictionary")) {
                [self setValue:obj forKey:mapedKey];
            } else {
                Class clazz = objc_getClass(pdesc->clazz);
                if (clazz) {
                    id value = [clazz sc_instanceFormDic:obj];
                    if (value) {
                        [self setValue:value forKey:mapedKey];
                    } else {
                        SCJSONLog(@"⚠️⚠️ %@ 类的 %@ 属性类型跟服务器返回的值 %@ 类型不法匹配！请修改为NSDictionary * %@; 或者 NSMutableDictionary * %@;",NSStringFromClass([self class]),mapedKey,obj,mapedKey,mapedKey);
                    }
                } else {
                    SCJSONLog(@"⚠️⚠️ %@ 类的 %@ 属性类型跟服务器返回的值的类型不法匹配！请修改为%s * %@;",NSStringFromClass([self class]),mapedKey,pdesc->clazz,mapedKey);
                }
            }
        } else {
            SCJSONLog(@"⚠️⚠️ %@ 类的 %@ 属性类型跟服务器返回的值 %@ 类型不法匹配！请修改为NSDictionary * %@; 或者 NSMutableDictionary * %@;",NSStringFromClass([self class]),mapedKey,obj,mapedKey,mapedKey);
        }
    } else if (![obj isKindOfClass:[NSNull class]]) {
        //自定义对象或者系统的NSStirng，NSNumber等；
        switch (pdesc->type) {
            case QLPropertyTypeObj:
            {
                const char *dclazz = pdesc->clazz;
                //目标类型是id，无法处理直接赋值；
                if (!dclazz) {
                    [self setValue:obj forKey:mapedKey];
                    break;
                }
                const char *vclazz = object_getClassName(obj);
                //目标类型和值类型相同，则直接赋值
                if (QLCStrEqual((char *)dclazz, (char *)vclazz)) {
                    [self setValue:obj forKey:mapedKey];
                } else if (QLCStrEqual((char *)dclazz, "NSString")) {
                    //目标类型是NSString
                    NSString *value = QLValueTransfer2NSString(obj);
                    [self setValue:value forKey:mapedKey];
                } else if (QLCStrEqual((char *)dclazz, "NSMutableString")) {
                    //目标类型是NSMutableString
                    NSString *value = QLValueTransfer2NSString(obj);
                    value = [NSMutableString stringWithString:value];
                    [self setValue:value forKey:mapedKey];
                } else if (QLCStrEqual((char *)dclazz, "NSNumber")) {
                    //目标类型是NSNumber
                    NSNumber *value = QLValueTransfer2NSNumber(obj);
                    [self setValue:value forKey:mapedKey];
                } else if (QLCStrEqual((char *)dclazz, "NSDecimalNumber")) {
                    //目标类型是NSDecimalNumber
                    NSDecimalNumber *value = QLValueTransfer2NSDecimalNumber(obj);
                    [self setValue:value forKey:mapedKey];
                } else if (QLCStrEqual((char *)dclazz, "NSURL")) {
                    //目标类型是NSURL
                    NSURL *value = QLValueTransfer2NSURL(obj);
                    [self setValue:value forKey:mapedKey];
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
                NSNumber *tmpValue = obj;
                
                //ios 8, -[__NSCFString longValue]: unrecognized selector
                if ([obj isKindOfClass:[NSString class]]) {
                    tmpValue = QLValueTransfer2NSNumber(obj);
                }
                
                //could not set nil as the value for the scalar key(int,float,...)
                if (tmpValue) {
                    [self setValue:tmpValue forKey:mapedKey];
                }
            }
                break;
            default:
                break;
        }
    }
    
    if (NULL != pdesc) {
        if (NULL != pdesc->clazz) {
            free((void *)pdesc->clazz);
            pdesc->clazz = NULL;
        }
        free(pdesc);
        pdesc = NULL;
    }
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
