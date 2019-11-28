//
//  OCTypes.h
//  SCJSONUtilDemo
//
//  Created by qianlongxu on 2019/11/26.
//  Copyright © 2019 xuqianlong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OCClassA : NSObject

@property (nonatomic, copy) NSString * name;

@end

@interface OCTypes : NSObject

@property (nonatomic, assign) bool boolType;
@property (nonatomic, assign) BOOL BOOLType;
@property (nonatomic, assign) char charType;
@property (nonatomic, assign) unsigned char uCharType;
@property (nonatomic, assign) short shortType;
@property (nonatomic, assign) unsigned short uShortType;
@property (nonatomic, assign) int intType;
@property (nonatomic, assign) unsigned int uIntType;
@property (nonatomic, assign) long longType;
@property (nonatomic, assign) unsigned long uLongType;
@property (nonatomic, assign) long long longlongType;
@property (nonatomic, assign) unsigned long long uLongLongType;
@property (nonatomic, assign) float floatType;
@property (nonatomic, assign) double doubleType;

@property (nonatomic, copy) NSString * stringType;
@property (nonatomic, copy) NSMutableString * mutableStringType;
@property (nonatomic, strong) NSNumber * numberType;
@property (nonatomic, strong) NSURL * urlType;
@property (nonatomic, strong) NSURL * fileURLType;
@property (nonatomic, strong) OCClassA * classAType;

@end

