//
//  SCModelUtil.h
//  SCJSONUtil
//
//  Created by qianlongxu on 2020/11/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject(SCModel2JSON)

/**
 *  @brief:将 model 对象转成 json 对象
 */
- (id)sc_toJSON;

/**
 *  @brief:将 model 对象转成 json 对象，字典key值有所不同
 *
 *  @param printProperyType
 *      YES:字典key值会带上Modle里定义的类型，用于debug时查看，不适合发送给服务器等场景！
 *      NO:等同于 sc_toJSON;
 */
- (id)sc_toJSONWithProperyType:(BOOL)printProperyType;

@end

NS_ASSUME_NONNULL_END
