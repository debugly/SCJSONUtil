//
//  SCJSONUtil.h
//  SohuCoreFoundation
//
//  Created by xuqianlong on 15/9/3.
//  Copyright (c) 2015年 Mac. All rights reserved.
//
//https://github.com/debugly/SCJSONUtil

#import <Foundation/Foundation.h>

///日志开关
#define SCJSONLogON 1

@protocol SCAnalyzeJSON2ModelProtocol <NSObject>

@optional;
/**
 *  @brief:  存放冲突key映射的字典 @{@"server's key":@"model‘s property name"}
 *  遍历服务端返回数据，通过key去查找客户端model里定义的属性名
 */
- (NSDictionary *)sc_collideKeysMap;

/**
 *  @brief: 存放服务端key和映射Model的字典，@{@"server's key":@"your Model Name"}
 */
- (NSDictionary *)sc_collideKeyModelMap;

/**
 *  @brief: 在给 key 赋值之前，将从字典里找到的 value 返回来，你可以修改这个值，然后返回新的值，从而达到处理业务逻辑的目的；
    @parameter key : 该model的属性名
    @parameter value :从字典里取出来的原始值，还未做自动映射
    框架会将返回值进行自动映射！
 */
- (id)sc_key:(NSString *)key beforeAssignedValue:(id)value;

@end


@interface NSObject (SCAnalyzeJSON2Model)<SCAnalyzeJSON2ModelProtocol>

/**
 *  @brief:  创建好对象后调用此方法，将json赋值给该modle对象；
 *
 *  @param jsonDic 与model对应的json
 */
- (void)sc_assembleDataFormDic:(NSDictionary *)jsonDic;

/**
 *  @brief:  创建一个已经赋过值的model对像;
 *              if jsonDic is nil or empty return nil;
 *
 *  @param jsonDic 与 modle 属性对应的字典
 */
+ (instancetype)sc_instanceFormDic:(NSDictionary *)jsonDic;

/**
 *  @brief:  jsonArr数组--》model数组,if jsonArr is nil or empty return nil;
 */
+ (NSArray *)sc_instanceArrFormArray:(NSArray *)jsonArr;

/**
 *  @brief: 自动判断Value类型进行解析
 *            a.value is array --> a model instances array,if JSON is nil or empty return nil;
 *            b.value is dictionary --> a model instance,if JSON is nil or empty return nil;
 *            c.Class is NSNumber、NSString、NSURL or NSDecimalNumber ; auto convert value to instance.
 */
+ (instancetype)sc_instanceFromValue:(id)value;

@end


#pragma mark - JOSNUtil methods

/**
 *  @brief  很方便的一个c方法，将 JSON 转为 Model，可用于网络请求返回数据的解析！
 *  @return model or models
 */
FOUNDATION_EXPORT id SCJSON2Model(id Json,NSString *modelName);
/**
 *  @brief 根据 keyPath 找到目标 JSON，可辅助 JSON2Model 函数使用，先找到 JOSN 在解析；
 *  @param keyPath JSON里的一个路径；一个以 / 分割的字符串；例如：@"data" , @"data/list";
 */
FOUNDATION_EXPORT id SCFindJSONwithKeyPath(NSString *keyPath,NSDictionary *JSON);
