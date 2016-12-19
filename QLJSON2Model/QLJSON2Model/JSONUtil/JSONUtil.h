//
//  JSONUtil.h
//  BeautyLore
//
//  Created by xuqianlong on 15/9/3.
//  Copyright (c) 2015年 Mac. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JSONUtilProtocol <NSObject>

@optional;
/**
 *  brief:  存放冲突key映射的字典 @{@"id":@"Newsid"}
 */
- (NSDictionary *)collideKeysMap;

/**
 *  brief:  存放冲突key映射Model的字典，@{@"courses":@"CourseModel"}
 */
- (NSDictionary *)collideKeyModelMap;

/**
 *  brief:  Value 转换
 */
- (void)valueNeedTransfer;

@end


@interface NSObject (AnalyzeJSON2Model)<JSONUtilProtocol>

- (void)assembleDataFormDic:(NSDictionary *)dic;

/**
 *
 *  创建一个已经赋过值的model对像
 *
 *  @param dic 与 modle 属性对应的字典
 *  brief:  if JSON is nil or empty return nil;
 */
+ (instancetype)instanceFormDic:(NSDictionary *)dic;

/**
 *  brief:  JSON数组--》model数组,if JSON is nil or empty return nil;
 */
+ (NSArray *)instanceArrFormArray:(NSArray *)arr;

/**
 *  自动判断JOSN类型进行解析
 *  brief:  JSON is array --> a model instances array,if JSON is nil or empty return nil;
 *          JSON is dictionary --> a model instance,if JSON is nil or empty return nil;
 */
+ (id)instanceFormJSON:(id)json;

@end


#pragma mark - JOSNUtil methods

/**
 *  @brief  很方便的一个c方法，将 JSON 转为 Model，可用于网络请求返回数据的解析！
 *  @return model or models
 */
FOUNDATION_EXPORT id JSON2Model(id Json,NSString *modelName);
/**
 *  @brief 根据 keyPath 找到目标 JSON，可辅助 JSON2Model 函数使用，先找到 JOSN 在解析；
 *  @param keyPath JSON里的一个路径；一个以 / 分割的字符串；例如：@"data" , @"data/list";
 */
FOUNDATION_EXPORT id FindJSONwithKeyPath(NSString *keyPath,NSDictionary *JSON);

