//
//  SCJSONUtil.h
//
//  Created by xuqianlong on 15/9/3.
//  Copyright (c) 2015年 Mac. All rights reserved.
//
//https://github.com/debugly/SCJSONUtil

#import <Foundation/Foundation.h>

///日志开关，默认关闭
void SCJSONUtilLog(BOOL on);
BOOL isSCJSONUtilLogOn(void);

@protocol SCJSON2ModelProtocol <NSObject>

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
 用于解决映射关系不能确定，需要动态修改的情况

 @param keyPtr 服务器key(如果做了映射sc_collideKeysMap，则是映射之后的key);二级指针，可修改内容
 @param valuePtr 服务器value;二级指针，可修改内容
 @param refObj 客户端解析时传过来的额外信息
 @return
    YES: 动态解决了映射关系，可根据 *keyPtr 查找到属性信息！继续走解析流程；
    NO:  没有解决,放弃该key-value；中断解析流程，开始解析下一个key；
 */
- (BOOL)sc_unDefinedKey:(NSString **)keyPtr forValue:(id *)valuePtr refObj:(id)refObj;

/**
 *  @brief: 在给 key 赋值之前，将从字典里找到的 value 返回来，你可以修改这个值，然后返回新的值，从而达到处理业务逻辑的目的；
    @parameter key : 该model的属性名
    @parameter value :从字典里取出来的原始值，还未做自动映射
    框架会将返回值进行自动映射！
 */
- (id)sc_key:(NSString *)key beforeAssignedValue:(id)value refObj:(id)refObj;

/**
 * @brief: JOSN 转 Model即将完成，你可以在这里做最后的自定义解析，以完成复杂的转换！
   @parameter data : 服务器返回的原始JSON数据；
   @parameter refObj : 客户端解析时传过来的额外信息；
 */
- (void)sc_willFinishConvert:(id)data refObj:(id)refObj;

@end


@interface NSObject (SCJSON2Model)

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
 *            a、if value is array --> a model instances array,if JSON is nil or empty return nil;
 *            b、if value is dictionary --> a model instance,if JSON is nil or empty return nil;
 *            c、if caller's Class is NSNumber、NSString、NSURL or NSDecimalNumber ; auto convert value to (the caller's Class) instance.
 */
+ (id)sc_instanceFromValue:(id)value;

@end


#pragma mark - JOSNUtil methods

/**
 *
 *  @return model or models
 */

/**
 @brief  很方便的一个c方法，将 JSON 转为 Model，可用于网络请求返回数据的解析！

 @param Json 服务器返回的JSON
 @param modelName 客户端定义的Model类类名
 @return Model类的实例对象
 */
FOUNDATION_EXPORT id SCJSON2Model(id Json,NSString *modelName);

/**
 @brief  很方便的一个c方法，将 JSON 转为 Model，可用于网络请求返回数据的解析！
 
 @param Json 服务器返回的JSON
 @param modelName 客户端定义的Model类类名
 @param refObj  客户端传递的额外参数，辅助解析；具体参考 Video.json 解析成 VideoList 的例子！
 @return Model类的实例对象
 */
FOUNDATION_EXPORT id SCJSON2ModelV2(id Json,NSString *modelName,id refObj);

/**
 *  @brief 根据 keyPath 找到目标 JSON，可辅助 JSON2Model 函数使用，先找到 JOSN 在解析；
 *  @param keyPath JSON里的一个路径；一个以 / 分割的字符串；例如：@"data" , @"data/list";
 */
FOUNDATION_EXPORT id SCFindJSONwithKeyPath(NSString *keyPath,NSDictionary *JSON);

/**
 * @brief 如果没有使用SCJSON2Model方法，而是使用了findJSONwithKeyPath_SC方法，那么JOSN里面不全是String，可以通过该方法解决；
 */
FOUNDATION_EXPORT id SCJSON2StringValueJSON(id findJson);

