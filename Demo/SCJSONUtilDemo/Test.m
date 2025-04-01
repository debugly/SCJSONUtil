//
//  Test.h
//  JSONUtilDemo
//
//  Created by Reach Matt on 2025/4/1.
//

#import "Test.h"
#import "Util.h"
#import "UserInfoModel.h"
#import "FavModel.h"
#import "OCTypes.h"
#import "Car.h"
#import "DynamicVideos.h"
#import "VideoInfo.h"
#import "StoreModel.h"
#import <SCJSONUtil/SCJSONUtil.h>
#import <SCJSONUtil/SCModelUtil.h>

@implementation NSObject (print)

- (NSString *)sc_calssName
{
    NSString *clazz = NSStringFromClass([self class]);
    if ([clazz hasPrefix:@"__"]) {
        clazz = NSStringFromClass([self superclass]);
    }
    if ([clazz isEqualToString:@"NSTaggedPointerString"]) {
        clazz = NSStringFromClass([[self superclass]superclass]);
    }
    return clazz;
}

- (NSString *)sc_toJSONString:(BOOL)prettyPrinted
{
    return [self sc_toJSONString:prettyPrinted printProperyType:NO];
}

- (NSString *)sc_toJSONString:(BOOL)prettyPrinted printProperyType:(BOOL)printProperyType
{
    NSDictionary *dic = [self sc_toJSONWithProperyType:printProperyType];
    NSString *jsonStr = JSON2String(dic, prettyPrinted);
    return [NSString stringWithFormat:@"%@* %p:\n%@",[self sc_calssName],self,jsonStr];
}

@end

@implementation Test

+ (NSString *)testAll
{
    SCJSONUtilLog(YES);
    
    NSString *result = [NSString stringWithFormat:@"\n=======日志开关=======\n%d\n\n",isSCJSONUtilLogOn()];
    
    result = [result stringByAppendingString:@"\n=======Objc 基础数据类型解析=======\n\n"];

    result = [result stringByAppendingString:[self testOCTypes]];

    result = [result stringByAppendingString:@"\n\n=======通过keypath查找简化解析=======\n\n"];

    result = [result stringByAppendingString:[self testKeyPathFromDictionary]];

    result = [result stringByAppendingString:@"\n\n=======json数组转model数组============\n\n"];

    result = [result stringByAppendingString:[self testModelsFromJSONArr]];

    result = [result stringByAppendingString:@"\n\n=========指定解析的路径，找到指定 json；==========\n\n"];

    result = [result stringByAppendingString:[self testKeyPath]];

    result = [result stringByAppendingString:@"\n\n=========多层嵌套字典转嵌套model==========\n\n"];

    result = [result stringByAppendingString:[self testModelFromDictionary]];

    result = [result stringByAppendingString:@"\n\n=========动态参照解析==========\n\n"];

    result = [result stringByAppendingString:[self testDynamicConvertFromDictionary]];

    result = [result stringByAppendingString:@"\n\n=========自定义解析==========\n\n"];

    result = [result stringByAppendingString:[self testCustomConvertFromDictionary]];

    result = [result stringByAppendingString:@"\n\n===================\n"];
    
    return result;
}

+ (NSString *)testOCTypes
{
    SCJSONUtilLog(YES);
    
    NSDictionary *typesDic = [Util readOCTypes];
    OCTypes *model = [OCTypes sc_instanceFormDic:typesDic];
    //美化打印
    return [model sc_toJSONString:YES];
}

+ (NSString *)testKeyPathFromDictionary
{
    SCJSONUtilLog(YES);
    
    NSDictionary *json = [Util readStore];
    StoreModel *store = SCJSON2Model(json, @"StoreModel");
    //美化打印，并且json的key值里包含定义属性的类型
    return [store sc_toJSONString:YES printProperyType:YES];
}

+ (void)testCount:(long)count work:(dispatch_block_t)block
{
    if (!block) {
        return;
    }
    CFAbsoluteTime begin = CFAbsoluteTimeGetCurrent();
    for (int i = 0; i<count; i++) {
        block();
    }
    CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
    NSLog(@"%ld 次转换耗时:%g",count,end-begin);
}

#pragma mark - test json 2 model

//字典转model
+ (NSString *)testModelFromDictionary
{
    SCJSONUtilLog(YES);
    
    NSDictionary *userInfoDic = [Util readUserInfo];
    UserInfoModel *uModel = [UserInfoModel sc_instanceFormDic:userInfoDic];
    return [uModel sc_toJSONString:NO];
}

//json数组转model数组
+ (NSString *)testModelsFromJSONArr
{
    SCJSONUtilLog(YES);
    
    NSArray *favArr = [Util readFavConcern];
    NSArray *favModels = [FavModel sc_instanceArrFormArray:favArr];
    return [favModels sc_toJSONString:NO];
}

//指定解析的路径，找到指定 json；
+ (NSString *)testKeyPath
{
    SCJSONUtilLog(YES);
    
    /*指定 keypath；我的项目里在 JSON 解析这块思路是这样的：
     服务器返回的有 code，首先验证下 code 是否正确；
     如果正确然后根据传入的 keypath 找到对应的json，再根据传入的 model 类名解析成 model，接着把 model 实例通过 block 回调给业务层处理;
     如果code不正确，那么无需 json 解析，此时包装一个 Error 出来，然后通过 block 回调给业务层处理;
     */
    
    NSDictionary *json = [Util readGalleryList];
    
    /* 假如网络请求返回的数据格式如下：
     
     //    {
     //    "code": "0",
     //    "content": {
     //        "gallery": [
     //{...}
     //{...}
     ]
     }}
     
     这里仅仅想要解析gallery数组的话就可以指定keypath：
     */
    //  model名字叫GalleryModel；对应的 JOSN keypath 是 @"content/gallery" ;
    
    //根据keypath找到目标JOSN
    id findedJSON = SCFindJSONwithKeyPath(@"content/gallery", json);
    //自动根据类型解析；
    NSArray *models = SCJSON2Model(findedJSON, @"GalleryModel");
    //这完全可以封装到我们的网络请求里！
    return [models sc_toJSONString:NO];
}

+ (NSString *)testDynamicConvertFromDictionary
{
    SCJSONUtilLog(YES);
    
    NSDictionary *videoListJson = [Util readVideoList];
    /**
     // 动态映射 key 的映射关系
     !! 这里模拟一个场景，我们需要请求这样一个接口，参数值可以是[qq,iqiyi]，响应结果里会包含所有渠道的视频信息(详见Video.json)，我们客户端定义了一个 video 数组来存放目标渠道的剧集，但是这种情况下，我们不知道怎么确定 video 字段跟服务器字段的映射关系！所以为了满足这种需求，就提供了V2版本的函数，她的第三个参数就是用来存放额外信息的，这个信息会在解析过程中，通过(sc_unDefinedKey:forValue:refObj:)方法传递过来；然后根据 refObj 提供的映射关系，去动态修改 key (value)！
     这样就解决了编译时无法确定映射关系问题，有点像 OC 的运行时哈，代码运行起来后，可以动态的解决！
     */
    
    DynamicVideos *videoList = SCJSON2ModelV2(videoListJson, @"DynamicVideos",@{@"qq":@"videos"});//这里的qq,可以换成iqiyi；具体是业务决定的
    return [videoList sc_toJSONString:NO];
}

+ (NSString *)testCustomConvertFromDictionary
{
    SCJSONUtilLog(YES);
    
    NSDictionary *videoInfoJson = [Util readVideoInfo];
    /**
     // 自定义解析过程
     !! 当解析过程过于复杂时，可在
        - (id)sc_willFinishConvert:(id)data refObj:(id)refObj
     方法中编写解析过程！
     */
    
    VideoInfo *videoInfo = SCJSON2ModelV2(videoInfoJson, @"VideoInfo",@{@"test":@"RefObj"});//额外业务参数
    return [videoInfo sc_toJSONString:NO];
}

+ (void)printTypeEncodings
{
    NSLog(@"bool     : %s, %lu", @encode(bool), sizeof(bool));
    NSLog(@"BOOL     : %s, %lu", @encode(BOOL), sizeof(BOOL));
    NSLog(@"char     : %s, %lu", @encode(char), sizeof(char));
    NSLog(@"unsigned char     : %s, %lu", @encode(unsigned char), sizeof(unsigned char));
    NSLog(@"short    : %s, %lu", @encode(short), sizeof(short));
    NSLog(@"unsigned short    : %s, %lu", @encode(unsigned short), sizeof(unsigned short));
    NSLog(@"int      : %s, %lu", @encode(int), sizeof(int));
    NSLog(@"unsigned int      : %s, %lu", @encode(unsigned int), sizeof(unsigned int));
    NSLog(@"long     : %s, %lu", @encode(long), sizeof(long));
    NSLog(@"unsigned long     : %s, %lu", @encode(unsigned long), sizeof(unsigned long));
    NSLog(@"long long: %s, %lu", @encode(long long), sizeof(long long));
    NSLog(@"unsigned long long: %s, %lu", @encode(unsigned long long), sizeof(unsigned long long));
    NSLog(@"float    : %s, %lu", @encode(float), sizeof(float));
    NSLog(@"double   : %s, %lu", @encode(double), sizeof(double));
    
    NSLog(@"int8_t  : %s, %lu", @encode(int8_t), sizeof(int8_t));
    NSLog(@"uint8_t  : %s, %lu", @encode(uint8_t), sizeof(uint8_t));
    NSLog(@"int16_t  : %s, %lu", @encode(int16_t), sizeof(int16_t));
    NSLog(@"uint16_t  : %s, %lu", @encode(uint16_t), sizeof(uint16_t));
    NSLog(@"int32_t  : %s, %lu", @encode(int32_t), sizeof(int32_t));
    NSLog(@"uint32_t  : %s, %lu", @encode(uint32_t), sizeof(uint32_t));
    NSLog(@"int64_t  : %s, %lu", @encode(int64_t), sizeof(int64_t));
    NSLog(@"uint64_t  : %s, %lu", @encode(uint64_t), sizeof(uint64_t));
}

+ (void)testPerformance
{
    SCJSONUtilLog(YES);
    
    //!! 测试的时候要关闭日志，NSLog 很耗时！
    NSDictionary *userInfoDic = [Util readUserInfo];
    
    [self testCount:10000 work:^{
        [UserInfoModel sc_instanceFormDic:userInfoDic];
    }];
    //    10000 次转换耗时:0.51412
    //    100000 次转换耗时:4.61152
}

@end

