//
//  QLBaseModel.m
//  PengBei
//
//  Created by xuqianlong on 15/3/5.
//  Copyright (c) 2015年 夕阳栗子. All rights reserved.
//

#import "QLBaseModel.h"

static bool isTransferNumber2String = true;    //？将数字转为字符串

@implementation QLBaseModel

- (void)handleValue:(id)obj thenAssign:(NSString *)key
{
    NSString *modleName = [[self collideKeyModelMap]objectForKey:key];
    //    没有配置model就直接赋值；
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
    
    NSString *newKey = [[self collideKeysMap]objectForKey:key];
//    model 指定了新的key了；
    if (newKey) {
        key = newKey;
    }
    
    //        stirng、字典、model直接塞值；
    if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[QLBaseModel class]])
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
        NSLog(@"key is [%@],value无法解析的类型！",key);
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
    QLBaseModel *obj = [[self alloc]init];
    [obj assembleDataFormDic:dic];
    [obj valueNeedTransfer];
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

//- (void)autoSetValue:(id)value forUndefinedKey:(NSString *)key
//{
//    NSString *propertyKey = [[self collideKeysMap]objectForKey:key];
//    
//    if (!propertyKey || propertyKey.length == 0) {
//        return;
//    }
//    
//    NSString *modleName = [[self collideKeyModelMap]objectForKey:key];
//    id finalValue = value;
//    
//    if ([value isKindOfClass:[NSArray class]]) {
//        if (modleName && modleName.length > 0) {
//            Class clazz = NSClassFromString(modleName);
//            finalValue = [clazz instanceArrFormArray:value];
//        }
//    }else if ([value isKindOfClass:[NSDictionary class]]){
//        Class clazz = NSClassFromString(modleName);
//        finalValue = [clazz instanceFormDic:value];
//    }
//    
//    [self handleValue:finalValue thenAssign:propertyKey];
//}
//
- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
//    [self autoSetValue:value forUndefinedKey:key];
    NSLog(@"没有解析的key is [%@],value is %@",key,value);
}

#pragma mark -AnalyzeJSON2ModelProtocol

- (void)valueNeedTransfer {}

- (NSDictionary *)collideKeyModelMap {return nil;}

- (NSDictionary *)collideKeysMap {return nil;}

@end
