//
//  JSONUtil.m
//  BeautyLore
//
//  Created by xuqianlong on 15/9/3.
//  Copyright (c) 2015年 Mac. All rights reserved.
//

#import "SLJSONUtil.h"
#import "objc/runtime.h"

#define QLJSONLogON 0
#if QLJSONLogON
#define QLJSONLog(...)   printf( __VA_ARGS__)
#else
#define QLJSONLog(...)
#endif

typedef NS_ENUM(NSUInteger, QLPropertyType) {
    QLPropertyTypeUnknow,
    QLPropertyTypeObj = '@',
    QLPropertyTypeFloat = 'f',
    QLPropertyTypeDouble = 'd',
    QLPropertyTypeBOOL = 'B',
    QLPropertyTypeBool = QLPropertyTypeBOOL,
    QLPropertyTypeChar = 'c',
    QLPropertyTypeShort = 's',
    QLPropertyTypeInt = 'i',
    QLPropertyTypeLong = 'q',
    QLPropertyTypeLong32 = 'l',
    QLPropertyTypeLongLong = QLPropertyTypeLong
};

typedef struct QLPropertyDescS {
    QLPropertyType type;
    char * clazz;
} QLPropertyDesc;

#pragma mark - C  Functions  -Begin-

#pragma mark 【Utils】

static bool QLCStrEqual(char *v1,char *v2)
{
    return 0 == strcmp(v1, v2);
}

static void	*QLMallocInit(size_t __size)
{
    void *p = malloc(__size);
    memset(p, 0, __size);
    return p;
}

static QLPropertyDesc * QLQLPropertyDescForClassProperty(Class clazz,const char *key)
{
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
            case QLPropertyTypeChar:
            case QLPropertyTypeShort:
            case QLPropertyTypeInt:
            case QLPropertyTypeLong:
            case QLPropertyTypeLong32:
            {
                QLPropertyDesc *desc = QLMallocInit(sizeof(QLPropertyDesc));//must init!!! iphone 5 crash,clazz is empty string : '' ;
                desc->type = iType;
                return desc;
            }
                break;
                
            default: // #:^ igonre:Class,SEL,Method...
            {
                QLJSONLog("未识别的类型：%c",iType);
            }
                break;
        }
    }
    return NULL;
}

#pragma mark 【ValueTransfer】

static NSString * QLValueTransfer2NSString(id value){
    return [value description];
}

static NSNumber * QLValueTransfer2NSNumber(id value){
    if ([value isKindOfClass:[NSString class]]){
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        return [numberFormatter numberFromString:value];
    }else if ([value isKindOfClass:[NSNumber class]]){
        return value;
    }
    return nil;
}

static NSDecimalNumber * QLValueTransfer2NSDecimalNumber(id value){
    if ([value isKindOfClass:[NSString class]]){
        return [NSDecimalNumber decimalNumberWithString:value];
    }
    return nil;
}

static NSURL * QLValueTransfer2NSURL(id value){
    if ([value isKindOfClass:[NSString class]]){
        return [NSURL URLWithString:(NSString *)value];
    }
    return nil;
}

#pragma mark C  Functions  -End-
#pragma mark -

@implementation NSObject (SLAnalyzeJSON2Model)

- (void)sl_autoMatchValue:(id)obj forKey:(NSString *)key
{
    NSString *mapedKey = key;
    if ([self respondsToSelector:@selector(sl_collideKeysMap)]) {
        mapedKey = [[self sl_collideKeysMap]objectForKey:key] ?: key;
    }
    
    QLPropertyDesc * pdesc = QLQLPropertyDescForClassProperty([self class], [mapedKey UTF8String]);
    if (NULL == pdesc) {
        QLJSONLog("未解析的key:%s",[key UTF8String]);
        return;
    }
    
    if ([obj isKindOfClass:[NSArray class]]) {
        NSString *modleName = nil;
        if ([self respondsToSelector:@selector(sl_collideKeyModelMap)]) {
            modleName = [[self sl_collideKeyModelMap]objectForKey:key];
        }
        if (modleName) {
            Class clazz = NSClassFromString(modleName);
            NSArray *objs = [clazz sl_instanceArrFormArray:obj];
            char * pclazz = pdesc->clazz;
            // 如果属性是可变的，那么做个可变处理
            if (QLCStrEqual(pclazz, "NSMutableArray")) {
                objs = [NSMutableArray arrayWithArray:objs];
            }
            [self setValue:objs forKey:mapedKey];
        }
    }else if ([obj isKindOfClass:[NSDictionary class]]){
        Class clazz = objc_getClass(pdesc->clazz) ;
        id value = [clazz sl_instanceFormDic:obj];
        [self setValue:value forKey:mapedKey];
    }else if (![obj isKindOfClass:[NSNull class]]){
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
                ///目标类型和值类型一直，则直接赋值
                if(QLCStrEqual((char *)dclazz, (char *)vclazz)){
                    [self setValue:obj forKey:mapedKey];
                    
                    ///目标类型是NSString
                }else if(QLCStrEqual((char *)dclazz, "NSString")){
                    NSString *value = QLValueTransfer2NSString(obj);
                    [self setValue:value forKey:mapedKey];
                    
                    ///目标类型是NSMutableString
                }else if(QLCStrEqual((char *)dclazz, "NSMutableString")){
                    NSString *value = QLValueTransfer2NSString(obj);
                    value = [NSMutableString stringWithString:value];
                    [self setValue:value forKey:mapedKey];
                    
                    ///目标类型是NSNumber
                }else if(QLCStrEqual((char *)dclazz, "NSNumber")){
                    NSNumber *value = QLValueTransfer2NSNumber(obj);
                    [self setValue:value forKey:mapedKey];
                    
                    ///目标类型是NSDecimalNumber
                }else if(QLCStrEqual((char *)dclazz, "NSDecimalNumber")){
                    NSDecimalNumber *value = QLValueTransfer2NSDecimalNumber(obj);
                    [self setValue:value forKey:mapedKey];
                    
                    ///目标类型是NSURL
                }else if(QLCStrEqual((char *)dclazz, "NSURL")){
                    NSURL *value = QLValueTransfer2NSURL(obj);
                    [self setValue:value forKey:mapedKey];
                }
            }
                break;
                ///因为kvc本身需要的value是id类型，所以对于基本数据类型不处理，而是交给系统 KVC 处理;
            case QLPropertyTypeInt:
            case QLPropertyTypeFloat:
            case QLPropertyTypeDouble:
            case QLPropertyTypeChar:
            case QLPropertyTypeShort:
            case QLPropertyTypeLong:
            case QLPropertyTypeBOOL:
            case QLPropertyTypeLong32:
            {
                [self setValue:obj forKey:mapedKey];
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

- (void)sl_assembleDataFormDic:(NSDictionary *)dic
{
    [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self sl_autoMatchValue:obj forKey:key];
    }];
}

+ (instancetype)sl_instanceFormDic:(NSDictionary *)jsonDic
{
    NSObject *obj = [[self alloc]init];
    [obj sl_assembleDataFormDic:jsonDic];
    [obj respondsToSelector:@selector(sl_valueNeedTransfer)]?[obj sl_valueNeedTransfer]:(nil);
    return obj;
}

+ (NSArray *)sl_instanceArrFormArray:(NSArray *)jsonArr
{
    if(!jsonArr || jsonArr.count == 0) return nil;
    
    NSMutableArray *modelArr = [[NSMutableArray alloc]initWithCapacity:3];
    [jsonArr enumerateObjectsUsingBlock:^(id json, NSUInteger idx, BOOL *stop) {
        id instance = [self sl_instanceFromValue:json];
        if (instance) {
            [modelArr addObject:instance];
        }else{
            NSAssert(NO, @"WTF?无法将该json转为model，因此过滤掉该元素！");
        }
    }];
    return [NSArray arrayWithArray:modelArr];
}

+ (instancetype)sl_instanceFromValue:(id)json
{
    if ([json isKindOfClass:[NSDictionary class]]) {
        return [self sl_instanceFormDic:json];
    }
    if([json isKindOfClass:[NSArray class]]){
        return [self sl_instanceArrFormArray:json];
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
    NSAssert(NO,@"无法将该value转为model");
    return nil;
}

@end

#pragma mark - JOSNUtil methods

static inline id SLFindJSONwithKeyPathArr(NSArray *pathArr,NSDictionary *JSON)
{
    if (!JSON) {
        return nil;
    }
    if (!pathArr || pathArr.count == 0) {
        return JSON;
    }
    NSMutableArray *pathArr2 = [NSMutableArray arrayWithArray:pathArr];
    
    while ([pathArr2 firstObject] && [[pathArr2 firstObject] description].length == 0) {
        [pathArr2 removeObjectAtIndex:0];
    }
    if ([pathArr2 firstObject]) {
        JSON = [JSON objectForKey:[pathArr2 firstObject]];
        [pathArr2 removeObjectAtIndex:0];
        return SLFindJSONwithKeyPathArr(pathArr2, JSON);
    }else{
        return JSON;
    }
}

id SLFindJSONwithKeyPath(NSString *keyPath,NSDictionary *JSON)
{
    if (!keyPath || keyPath.length == 0) {
        return JSON;
    }
    NSArray *pathArr = [keyPath componentsSeparatedByString:@"/"];
    return SLFindJSONwithKeyPathArr(pathArr, JSON);
}

id SLJSON2Model(id json,NSString *modelName)
{
    Class clazz = NSClassFromString(modelName);
    return [clazz sl_instanceFromValue:json];
}

id SLJSON2StringJOSN(id findJson)
{
    if ([findJson isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:findJson];
        [findJson enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj && ![obj isKindOfClass:[NSNull class]]) {
                [dic setObject:SLJSON2StringJOSN(obj) forKey:key];
            }
        }];
        return dic;
    }else if([findJson isKindOfClass:[NSArray class]]){
        NSMutableArray *arr = [NSMutableArray array];
        for (id obj in findJson) {
            if (obj && ![obj isKindOfClass:[NSNull class]]) {
                [arr addObject:SLJSON2StringJOSN(obj)];
            }
        }
        return arr;
    }else if ([findJson isKindOfClass:[NSString class]]){
        return findJson;
    }else if ([findJson isKindOfClass:[NSNumber class]]){
        return [findJson description];
    }else{
        return findJson;
    }
}
