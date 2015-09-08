//
//  JSONUtil.m
//  BeautyLore
//
//  Created by xuqianlong on 15/9/3.
//  Copyright (c) 2015年 Mac. All rights reserved.
//

#import "JSONUtil.h"

static bool isTransferNumber2String = 1;    //？将数字转为字符串
static bool isTransferNull2EmptyString = 0; //？将null或者nil转为@""

@implementation NSObject (AnalyzeJSON2Model)

- (void)handleValue:(id)obj thenAssign:(NSString *)key
{
    NSString *modleName = nil;
    if ([self respondsToSelector:@selector(collideKeyModelMap)]) {
        modleName = [[self collideKeyModelMap]objectForKey:key];
    }
    
    if ([self respondsToSelector:@selector(collideKeysMap)]) {
        key = [[self collideKeysMap]objectForKey:key] ?: key;
    }

    if (modleName) {
        
        if ([obj isKindOfClass:[NSArray class]]) {
            if (modleName && modleName.length > 0) {
                Class clazz = NSClassFromString(modleName);
                obj = [clazz instanceArrFormArray:obj];
            }
        }else if ([obj isKindOfClass:[NSDictionary class]]){
            Class clazz = NSClassFromString(modleName);
            obj = [clazz instanceFormDic:obj];
        }
    }
    
    //        stirng、字典
    if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSDictionary class]])
    {
        [self setValue:obj forKeyPath:key];
        
    }else if ([obj isKindOfClass:[NSNumber class]]){
        if (isTransferNumber2String) {
            //            NSNumber -> String;
            [self setValue:[obj description] forKey:key];
        }else{
            [self setValue:obj forKeyPath:key];
        }
    }else if([obj isKindOfClass:[NSArray class]]){
        NSArray *valueArr = obj;
        if (valueArr.count > 0) {
            if (isTransferNumber2String) {
                NSMutableArray *valueMul = [[NSMutableArray alloc]init];
                for (NSObject *o in valueArr){
                    if ([o isKindOfClass:[NSNumber class]]) {
                        [valueMul addObject:[o description]];
                    }
                }
                if (valueMul.count > 0) {
                    [self setValue:[NSArray arrayWithArray:valueMul] forKeyPath:key];
                }else{
                    [self setValue:obj forKeyPath:key];
                }
            }else{
                [self setValue:obj forKeyPath:key];
            }
        }
    }else if(!obj || [obj isKindOfClass:[NSNull class]]){
        NSLog(@"key is [%@],value is nil！",key);
    }else{
//        应该是instance
        [self setValue:obj forKeyPath:key];
    }
}

- (void)assembleDataFormDic:(NSDictionary *)dic
{
    [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self handleValue:obj thenAssign:key];
    }];
}

+ (instancetype)instanceFormDic:(NSDictionary *)dic
{
    NSObject *obj = [[self alloc]init];
    [obj assembleDataFormDic:dic];
    [obj respondsToSelector:@selector(valueNeedTransfer)]?[obj valueNeedTransfer]:(nil);
    return obj;
}

+ (NSArray *)instanceArrFormArray:(NSArray *)valueArr
{
    if(!valueArr || valueArr.count == 0) return nil;
    
    NSMutableArray *modelArr = [[NSMutableArray alloc]initWithCapacity:3];
    [valueArr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            [modelArr addObject:[self instanceFormDic:obj]];
        }
    }];
    return [NSArray arrayWithArray:modelArr];
}

+ (id)instanceFormJSON:(id)json
{
    if([json isKindOfClass:[NSArray class]]){
       return [self instanceArrFormArray:json];
    }else if([json isKindOfClass:[NSDictionary class]]){
        return [self instanceFormDic:json];
    }else{
#ifdef DEBUG
        NSParameterAssert(NO);
#endif
        return nil;
    }
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    NSLog(@"没有解析的key is [%@],value is %@",key,value);
}

@end


#pragma mark - JOSNUtil methods

static inline id findJSONwithKeyPathArr(NSArray *pathArr,NSDictionary *JSON)
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
        return findJSONwithKeyPathArr(pathArr2, JSON);
    }else{
        return JSON;
    }
}

id findJSONwithKeyPath(NSString *keyPath,NSDictionary *JSON)
{
    if (!keyPath || keyPath.length == 0) {
        return JSON;
    }
    NSArray *pathArr = [keyPath componentsSeparatedByString:@"/"];
    
    return findJSONwithKeyPathArr(pathArr, JSON);
}

id JSON2Model(id findJson,NSString *modelName)
{
    Class clazz = NSClassFromString(modelName);
    id model = nil;
    if ([findJson isKindOfClass:[NSDictionary class]]) {
        model = [clazz instanceFormDic:findJson];
    }else if([findJson isKindOfClass:[NSArray class]]){
        model = [clazz instanceArrFormArray:findJson];
    }
    return model;
}
