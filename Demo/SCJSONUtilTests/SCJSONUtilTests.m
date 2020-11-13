//
//  SCJSONUtilTests.m
//  SCJSONUtilTests
//
//  Created by Matt Reach on 2020/4/22.
//  Copyright © 2020 xuqianlong. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <SCJSONUtil/SCJSONUtil.h>
#import "UserInfoModel.h"
#import "FavModel.h"
#import "OCTypes.h"
#import "NSObject+DebugDescription.h"
#import "NSArray+DebugDescription.h"
#import "NSObject+PrintProperties.h"
#import "Car.h"
#import "DynamicVideos.h"
#import "VideoInfo.h"
#import "GalleryModel.h"
#import "StoreModel.h"
#import "Util.h"

@interface SCJSONUtilTests : XCTestCase

@end

@implementation SCJSONUtilTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testLogSwitch
{
    SCJSONUtilLog(YES);
    XCTAssert(isSCJSONUtilLogOn() == YES);
    SCJSONUtilLog(NO);
    XCTAssert(isSCJSONUtilLogOn() == NO);
}

- (void)testOCTypes
{
    NSDictionary *typesDic = [Util readOCTypes];
    OCTypes *model = [OCTypes sc_instanceFormDic:typesDic];
    XCTAssert(model.boolType == YES);
    XCTAssert(model.BOOLType == YES);
    XCTAssert(model.charType == 32);
    XCTAssert(model.uCharType == 97);
    XCTAssert(model.shortType == 123);
    XCTAssert(model.uShortType == 234);
    XCTAssert(model.intType == 345);
    XCTAssert(model.uIntType == 456);
    XCTAssert(model.longType == 567);
    XCTAssert(model.uLongType == 789);
    XCTAssert(model.longlongType == 5677);
    XCTAssert(model.uLongLongType == 7899);
    XCTAssert((int)(model.floatType * 1000) == (int)(345.123 * 1000));
    XCTAssert((long)(model.doubleType * 100000) == (long)(456.12345 * 100000));
    XCTAssert([model.stringType isEqualToString:@"I'm a string."]);
    XCTAssert([model.mutableStringType isEqualToString:@"I'm a mutable string."]);
    XCTAssert([model.mutableStringType isKindOfClass:[NSMutableString class]]);
    XCTAssert([[model.numberType description] isEqualToString:@"7982"]);
    XCTAssert([model.numberType isKindOfClass:[NSNumber class]]);
    XCTAssert([[model.urlType absoluteString] isEqualToString:@"https://debugly.cn"]);
    XCTAssert([model.urlType isKindOfClass:[NSURL class]]);
    XCTAssert([[model.fileURLType absoluteString] isEqualToString:@"file:///Users/qianlongxu/Desktop/Caption.zip"]);
    XCTAssert([model.fileURLType isFileURL]);
    XCTAssert([model.fileURLType isKindOfClass:[NSURL class]]);
    XCTAssert([model.classAType isKindOfClass:[OCClassA class]]);
    XCTAssert([model.classAType.name isEqualToString:@"I'm a classA instance."]);
}

- (void)performance:(long)count work:(dispatch_block_t)block
{
    [self measureBlock:^{
        for (int i = 0; i<count; i++) {
            block();
        }
    }];
}

#pragma mark - test json 2 model

///字典转model
- (void)testModelFromDictionary
{
    NSDictionary *userInfoDic = [Util readUserInfo];
    UserInfoModel *uModel = [UserInfoModel sc_instanceFormDic:userInfoDic];
    XCTAssert([uModel.code isEqualToString:@"10000"]);
    
    DataInfoModel *data = uModel.data;
    XCTAssert([data.basicInfo isKindOfClass:[BasicInfoModel class]]);
    
    BasicInfoModel *basicInfo = data.basicInfo;
    XCTAssert([basicInfo.gender isEqualToString:@"男"]);
    XCTAssert(basicInfo.uid == 209849);
    XCTAssert([basicInfo.name isEqualToString:@"芒果"]);
    XCTAssert([basicInfo.phone_number isEqualToString:@"999198838229"]);
    
    AvatarInfoModel *avatarInfo = basicInfo.avatarInfo;
    XCTAssert([avatarInfo.original_url isEqualToString:@"http://original/e/s/15/04/01/20150401185027193594-10-10.jpg"]);
    XCTAssert([avatarInfo.thumbnail_url isEqualToString:@"http://thumbnail/e/s/15/04/01/20150401185027193594-10-10.jpg"]);
    XCTAssert([[avatarInfo.raw_url absoluteString] isEqualToString:@"http://raw/e/s/15/04/01/20150401185027193594-10-10.jpg"]);
    
    XCTAssert([data.carInfoArr isKindOfClass:[NSMutableArray class]]);
    
    for (CarInfoModel *car in data.carInfoArr) {
        XCTAssert([car.bought_time isEqualToString:@"2002"]);
        XCTAssert([car.brand isEqualToString:@"werty"]);
        XCTAssert([car.brandImg isKindOfClass:[AvatarInfoModel class]]);
        AvatarInfoModel *brandImg = car.brandImg;
        XCTAssert([brandImg.original_url isEqualToString:@"http://original/e/s/15/04/01/20150401185027193594-10-10.jpg"]);
        XCTAssert([brandImg.thumbnail_url isEqualToString:@"http://thumbnail/e/s/15/04/01/20150401185027193594-10-10.jpg"]);
        XCTAssert([[brandImg.raw_url absoluteString] isEqualToString:@"http://raw/e/s/15/04/01/20150401185027193594-10-10.jpg"]);
    }
}

///json数组转model数组
- (void)testModelsFromJSONArr
{
    NSArray *favArr = [Util readFavConcern];
    NSArray *favModels = [FavModel sc_instanceArrFormArray:favArr];
    int i = 1;
    for (FavModel *fav in favModels) {
        XCTAssert(fav.refContent == i * 111111111);
        NSString *en = [NSString stringWithFormat:@"TopShopEN%d",i];
        XCTAssert([fav.nameEN isEqualToString:en]);
        NSString *cn = [NSString stringWithFormat:@"TopShopCN%d",i];
        XCTAssert([fav.nameCN isEqualToString:cn]);
        NSString *pic = [NSString stringWithFormat:@"http://pic.shangpin.com/%d.jpg",i];
        XCTAssert([[fav.pic absoluteString] isEqualToString:pic]);
        i++;
    }
}

///指定解析的路径，找到指定 json；
- (void)testKeyPath
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
    id findedJSON2 = SCFindJSONwithKeyPathV2(@"content/gallery", json,@"/");
    id findedJSON3 = SCFindJSONwithKeyPathArr(@[@"content",@"gallery"], json);
    
    NSData *data1 = [NSJSONSerialization dataWithJSONObject:findedJSON options:0 error:nil];
    NSData *data2 = [NSJSONSerialization dataWithJSONObject:findedJSON2 options:0 error:nil];
    NSData *data3 = [NSJSONSerialization dataWithJSONObject:findedJSON3 options:0 error:nil];
    
    XCTAssert(0 == strcmp(data1.bytes, data2.bytes));
    XCTAssert(0 == strcmp(data1.bytes, data3.bytes));
    int i = 0;
    //自动根据类型解析；
    NSArray *models = SCJSON2Model(findedJSON, @"GalleryModel");
    for (GalleryModel *gallery in models) {
        XCTAssert(gallery.isFlagship == i % 2);
        XCTAssert([gallery.pic isKindOfClass:[NSURL class]]);
        NSString *type = [NSString stringWithFormat:@"%d",i+1];
        XCTAssert([gallery.type isEqualToString:type]);
        i++;
    }
}

- (void)testDynamicConvertFromDictionary
{
    NSDictionary *videoListJson = [Util readVideoList];
    /**
     // 动态映射 key 的映射关系
     !! 这里模拟一个场景，我们需要请求这样一个接口，参数值可以是[qq,iqiyi]，响应结果里会包含所有渠道的视频信息(详见Video.json)，我们客户端定义了一个 video 数组来存放目标渠道的剧集，但是这种情况下，我们不知道怎么确定 video 字段跟服务器字段的映射关系！所以为了满足这种需求，就提供了V2版本的函数，她的第三个参数就是用来存放额外信息的，这个信息会在解析过程中，通过(sc_unDefinedKey:forValue:refObj:)方法传递过来；然后根据 refObj 提供的映射关系，去动态修改 key (value)！
     这样就解决了编译时无法确定映射关系问题，有点像 OC 的运行时哈，代码运行起来后，可以动态的解决！
     */
    
    DynamicVideos *video = SCJSON2ModelV2(videoListJson, @"DynamicVideos",@{@"qq":@"videos"});//这里的qq,可以换成iqiyi；具体是业务决定的
    
    XCTAssert([video.area isEqualToString:@"内地"]);
    XCTAssert(video.playlistid == 5828854);
    XCTAssert([video.wps count] == 4);
    XCTAssert(video.array == 0);
    XCTAssert(video.activity == 1);
    XCTAssert([video.smallVerPicUrl isKindOfClass:[NSURL class]]);
    XCTAssert([video.showAlbumName isKindOfClass:[NSMutableString class]]);
    for (int i = 0; i < [video.videos count]; i++) {
        VideoItem *item = video.videos[i];
        XCTAssert(item.no == i + 1);
        XCTAssert([item.showName isKindOfClass:[NSString class]]);
        XCTAssert([item.title isKindOfClass:[NSString class]]);
        XCTAssert([item.domain isKindOfClass:[NSString class]]);
        XCTAssert([item.showName isKindOfClass:[NSString class]]);
        XCTAssert([item.type isKindOfClass:[NSNumber class]]);
        XCTAssert([item.rid isKindOfClass:[NSNumber class]]);
        XCTAssert([item.uid isKindOfClass:[NSNumber class]]);
        XCTAssert([item.rSwfurl isKindOfClass:[NSMutableString class]]);
        XCTAssert([item.url isKindOfClass:[NSURL class]]);
    }
}

- (void)testCustomConvertFromDictionary
{
    NSDictionary *videoInfoJson = [Util readVideoInfo];
    /**
     // 自定义解析过程
     !! 当解析过程过于复杂时，可在
        - (id)sc_willFinishConvert:(id)data refObj:(id)refObj
     方法中编写解析过程！
     */
    
    VideoInfo *videoInfo = SCJSON2ModelV2(videoInfoJson, @"VideoInfo",@{@"test":@"RefObj"});//额外业务参数
    XCTAssert([videoInfo.name isEqualToString:@"欢乐颂"]);
    for (int i = 0; i < 3; i++) {
        VideoSection *section = videoInfo.sections[i];
        XCTAssert(section.ck == i+1);
        NSString *du = section.du;
        NSString *hc = section.hc;
        NSString *result = [NSString stringWithFormat:@"%d",15+i];
        XCTAssert([hc isKindOfClass:[NSString class]]);
        XCTAssert([du isEqualToString:result]);
    }
}

- (void)testKeyPathFromDictionary
{
    NSDictionary *json = [Util readStore];
    StoreModel *store = SCJSON2Model(json, @"StoreModel");
    XCTAssert([store.name isEqualToString:@"测试下KeyPath"]);
    for (int i = 0; i < 3; i++) {
        NSNumber *order = store.order[i];
        XCTAssert([order intValue] == i+1);
        NSString *category = store.category[i];
        NSString *weight = store.weight[i];
        NSString *result = [NSString stringWithFormat:@"%d",15+i];
        XCTAssert([category isKindOfClass:[NSString class]]);
        XCTAssert([result isEqualToString:weight]);
    }
}

- (void)testPerformance
{
    ///!! 测试的时候要关闭日志，NSLog 很耗时！
    NSDictionary *userInfoDic = [Util readUserInfo];
    [self performance:1000 work:^{
        [UserInfoModel sc_instanceFormDic:userInfoDic];
    }];
    //    10000 次转换耗时:0.51412
    //    100000 次转换耗时:4.61152
}

@end
