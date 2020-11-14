//
//  ViewController.m
//  SCJSONUtilDemo
//
//  Created by xuqianlong on 2017/7/21.
//  Copyright © 2017年 xuqianlong. All rights reserved.
//

#import "ViewController.h"
#import <SCJSONUtil/SCJSONUtil.h>
#import "UserInfoModel.h"
#import "FavModel.h"
#import "OCTypes.h"
#import "NSObject+PrintProperties.h"
#import "Car.h"
#import "DynamicVideos.h"
#import "VideoInfo.h"
#import "StoreModel.h"
#import "Util.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *txv;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
        
    //[self printTypeEncodings];
    
    SCJSONUtilLog(YES);
    NSString *result = [NSString stringWithFormat:@"\n=======日志开关=======\n%d\n\n",isSCJSONUtilLogOn()];
    
    result = [result stringByAppendingString:@"\n=======Objc 基础数据类型解析=======\n\n"];

    result = [result stringByAppendingString:[self testOCTypes]];

    result = [result stringByAppendingString:@"\n=======通过keypath查找简化解析=======\n\n"];

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
    
    self.txv.text = result;
 
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        ///测试嵌套model解析性能
//        [self testPerformance];
//    });
}

- (void)printTypeEncodings
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

- (NSString *)testOCTypes
{
    NSDictionary *typesDic = [Util readOCTypes];
    OCTypes *model = [OCTypes sc_instanceFormDic:typesDic];
    return [model sc_printAllProperties];
}

- (NSString *)testKeyPathFromDictionary
{
    NSDictionary *json = [Util readStore];
    StoreModel *store = SCJSON2Model(json, @"StoreModel");
    return [store sc_printAllProperties];
}

- (void)testCount:(long)count work:(dispatch_block_t)block
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

///字典转model
- (NSString *)testModelFromDictionary
{
    NSDictionary *userInfoDic = [Util readUserInfo];
    UserInfoModel *uModel = [UserInfoModel sc_instanceFormDic:userInfoDic];
    return [uModel sc_printAllProperties];
}

///json数组转model数组
- (NSString *)testModelsFromJSONArr
{
    NSArray *favArr = [Util readFavConcern];
    NSArray *favModels = [FavModel sc_instanceArrFormArray:favArr];
    return [favModels sc_printAllProperties];
}

///指定解析的路径，找到指定 json；
- (NSString *)testKeyPath
{
    
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
    return [models sc_printAllProperties];
}

- (NSString *)testDynamicConvertFromDictionary
{
    NSDictionary *videoListJson = [Util readVideoList];
    /**
     // 动态映射 key 的映射关系
     !! 这里模拟一个场景，我们需要请求这样一个接口，参数值可以是[qq,iqiyi]，响应结果里会包含所有渠道的视频信息(详见Video.json)，我们客户端定义了一个 video 数组来存放目标渠道的剧集，但是这种情况下，我们不知道怎么确定 video 字段跟服务器字段的映射关系！所以为了满足这种需求，就提供了V2版本的函数，她的第三个参数就是用来存放额外信息的，这个信息会在解析过程中，通过(sc_unDefinedKey:forValue:refObj:)方法传递过来；然后根据 refObj 提供的映射关系，去动态修改 key (value)！
     这样就解决了编译时无法确定映射关系问题，有点像 OC 的运行时哈，代码运行起来后，可以动态的解决！
     */
    
    DynamicVideos *videoList = SCJSON2ModelV2(videoListJson, @"DynamicVideos",@{@"qq":@"videos"});//这里的qq,可以换成iqiyi；具体是业务决定的
    return [videoList sc_printAllProperties];
}

- (NSString *)testCustomConvertFromDictionary
{
    NSDictionary *videoInfoJson = [Util readVideoInfo];
    /**
     // 自定义解析过程
     !! 当解析过程过于复杂时，可在
        - (id)sc_willFinishConvert:(id)data refObj:(id)refObj
     方法中编写解析过程！
     */
    
    VideoInfo *videoInfo = SCJSON2ModelV2(videoInfoJson, @"VideoInfo",@{@"test":@"RefObj"});//额外业务参数
    return [videoInfo sc_printAllProperties];
}

- (void)testPerformance
{
    ///!! 测试的时候要关闭日志，NSLog 很耗时！
    NSDictionary *userInfoDic = [Util readUserInfo];
    
    [self testCount:10000 work:^{
        [UserInfoModel sc_instanceFormDic:userInfoDic];
    }];
    //    10000 次转换耗时:0.51412
    //    100000 次转换耗时:4.61152
}

@end
