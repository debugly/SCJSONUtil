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
#import "JSONUtil.h"
#import "NSObject+DebugDescription.h"
#import "NSArray+DebugDescription.h"
#import "NSObject+PrintProperties.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ///多层嵌套的；
    [self testModelFromDictionary];
    ///数组
    [self testModelsFromJSONArr];
    /*指定 keypath；我的项目里在 JSON 解析这块思路是这样的：
        服务器返回的有 code，首先验证下 code 是否正确；
            如果正确然后根据传入的 keypath 找到对应的json，再根据传入的 model 类名解析成 model，接着把 model 实例通过 block 回调给业务层处理;
            如果code不正确，那么无需 json 解析，此时包装一个 Error 出来，然后通过 block 回调给业务层处理;
    */
    [self testKeyPath];
}

#pragma mark - test json 2 model

///字典转model
- (void)testModelFromDictionary
{
    NSDictionary *userInfoDic = [self readUserInfo];
    
    UserInfoModel *uModel = [UserInfoModel instanceFormDic:userInfoDic];
    
    NSLog(@"----%@",[uModel DEBUGDescrption]);
}

///json数组转model数组
- (void)testModelsFromJSONArr
{
    NSArray *favArr = [self readFavConcern];
    NSArray *favModels = [FavModel instanceArrFormArray:favArr];
    NSLog(@"----%@",[favModels DEBUGDescrption]);
}

///指定解析的路径，找到指定 json；
- (void)testKeyPath
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
    id findedJSON = findJSONwithKeyPath(@"content/gallery", newMainPageInfo);
    //自动根据类型解析；
    NSArray *models = JSON2Model(findedJSON, @"GalleryModel");
    //这完全可以封装到我们的网络请求里！
    
    NSLog(@"----%@",[models DEBUGDescrption]);
}

#pragma mark - private and util methods

- (NSString *)jsonFilePath:(NSString *)fName
{
    return [[NSBundle mainBundle]pathForResource:fName ofType:@"json"];
}

- (id)readBundleJSONFile:(NSString *)fName
{
    NSData *data = [NSData dataWithContentsOfFile:[self jsonFilePath:fName]];
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
}

- (NSDictionary *)readUserInfo
{
    return [NSDictionary dictionaryWithContentsOfFile:[self jsonFilePath:@"Userinfo"]];
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
