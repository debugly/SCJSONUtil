//
//  Test.h
//  JSONUtilDemo
//
//  Created by Reach Matt on 2025/4/1.
//

#import <Foundation/Foundation.h>

@interface Test : NSObject

+ (NSString *)testAll;
+ (void)printTypeEncodings;
+ (NSString *)testOCTypes;
+ (NSString *)testKeyPathFromDictionary;
+ (NSString *)testModelFromDictionary;
+ (NSString *)testModelsFromJSONArr;
+ (NSString *)testKeyPath;
+ (NSString *)testDynamicConvertFromDictionary;
+ (NSString *)testCustomConvertFromDictionary;
+ (void)testPerformance;

@end
