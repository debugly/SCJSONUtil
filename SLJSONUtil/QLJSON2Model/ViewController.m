//
//  ViewController.m
//  QLJSON2Model
//
//  Created by xuqianlong on 15/7/14.
//  Copyright (c) 2015年 xuqianlong. All rights reserved.
//

#import "ViewController.h"
#import "UserInfoModel.h"
#import "FavModel.h"
#import "SCJSONUtil.h"
#import "NSObject+DebugDescription.h"
#import "NSArray+DebugDescription.h"
#import "NSObject+PrintProperties.h"
#import "Car.h"
#import "objc/runtime.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *txv;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ///测试5层嵌套性能
    [self testModelFromDictionary];
    ///数组
    NSString *result = [self testModelsFromJSONArr];
    /*指定 keypath；我的项目里在 JSON 解析这块思路是这样的：
        服务器返回的有 code，首先验证下 code 是否正确；
            如果正确然后根据传入的 keypath 找到对应的json，再根据传入的 model 类名解析成 model，接着把 model 实例通过 block 回调给业务层处理;
            如果code不正确，那么无需 json 解析，此时包装一个 Error 出来，然后通过 block 回调给业务层处理;
    */
   NSString *result2 = [self testKeyPath];
    
    NSString *text = [result stringByAppendingString:result2];
    self.txv.text = text;
    
//    NSDictionary *carJSON =  [self readCarInfo];
//    Car *car = JSON2Model(carJSON, @"Car");
//    NSLog(@"%@",[car description]);
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
- (void)testModelFromDictionary
{
    NSDictionary *userInfoDic = [self readUserInfo];

    [self testCount:10000 work:^{
        UserInfoModel *uModel = [UserInfoModel sc_instanceFormDic:userInfoDic];
    }];
//    10000 次转换耗时:0.51412
//    100000 次转换耗时:4.61152
}

///json数组转model数组
- (NSString *)testModelsFromJSONArr
{
    NSArray *favArr = [self readFavConcern];
    NSArray *favModels = [FavModel sc_instanceArrFormArray:favArr];
    return [favModels DEBUGDescrption];
}

///指定解析的路径，找到指定 json；
- (NSString *)testKeyPath
{
    NSDictionary *newMainPageInfo = [self readNewMainPageFirst];
    
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
    id findedJSON = SCFindJSONwithKeyPath(@"content/gallery", newMainPageInfo);
    //自动根据类型解析；
    NSArray *models = SCJSON2Model(findedJSON, @"GalleryModel");
    //这完全可以封装到我们的网络请求里！
    return [models DEBUGDescrption];
}

#pragma mark - private and util methods

- (NSString *)jsonFilePath:(NSString *)fName
{
    return [[NSBundle mainBundle]pathForResource:fName ofType:@"json"];
}

- (id)readBundleJSONFile:(NSString *)fName
{
    NSData *data = [NSData dataWithContentsOfFile:[self jsonFilePath:fName]];
    NSError *err = nil;
    id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
    if (err) {
        return nil;
    }
    return json;
}

- (NSDictionary *)readCarInfo
{
    return [self readBundleJSONFile:@"Car"];
}

- (NSDictionary *)readUserInfo
{
    return [self readBundleJSONFile:@"Userinfo"];
}

- (NSArray *)readFavConcern
{
    return [self readBundleJSONFile:@"FavConcern"];
}

- (NSDictionary *)readNewMainPageFirst
{
    return [self readBundleJSONFile:@"newMainPageFirst"];
}

@end
