//
//  ViewController.m
//  QLJSON2Model
//
//  Created by xuqianlong on 15/7/14.
//  Copyright (c) 2015年 xuqianlong. All rights reserved.
//

#import "ViewController.h"
#import "UserInfoModel.h"
#import "ManageConcern.h"
#import "JSONUtil.h"
#import "NSObject+DebugDescription.h"
#import "NSArray+DebugDescription.h"
#import "NSObject+PrintProperties.h"

@interface ViewController ()

@end

@implementation ViewController

- (NSString *)jsonFilePath:(NSString *)fName
{
    return [[NSBundle mainBundle]pathForResource:fName ofType:@"json"];
}

- (NSDictionary *)readBundleJSONFile:(NSString *)fName
{
    NSData *data = [NSData dataWithContentsOfFile:[self jsonFilePath:fName]];
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
}

- (NSDictionary *)readUserInfo
{
    return [NSDictionary dictionaryWithContentsOfFile:[self jsonFilePath:@"Userinfo"]];
}

- (NSDictionary *)readManageConcern
{
    return [self readBundleJSONFile:@"ManageConcern"];
}

- (NSDictionary *)readNewMainPageFirst
{
    return [self readBundleJSONFile:@"newMainPageFirst"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSDictionary *userInfoDic = [self readUserInfo];
    
    UserInfoModel *uModel = [UserInfoModel instanceFormDic:userInfoDic];
    
    NSLog(@"----%@",[uModel DEBUGDescrption]);
    
    NSDictionary *mConInfoDic = [self readManageConcern];
    ManageConcern *mConModel = [ManageConcern instanceFormDic:mConInfoDic];
    NSLog(@"----%@",[mConModel DEBUGDescrption]);
//    使用JSONUtil解析；
    
//    假如这就是网络请求返回的数据
    NSDictionary *newMainPageInfo = [self readNewMainPageFirst];
    //    那么我的model名字叫GalleryModel；对应的 JOSN keypath 是 @"content/gallery" ;
//    {
//    "code": "0", 
//    "content": {
//        "gallery": [
    
//    所以解析就是：
    id findedJSON = findJSONwithKeyPath(@"content/gallery", newMainPageInfo); //根据keypath找到目标JOSN
    NSArray *models = JSON2Model(findedJSON, @"GalleryModel");
//    这完全可以封装到我们的网络请求里！
    
//    NSArray *arr = [models objectArray2JSONArray];
//    NSLog(@"----%@",arr);

     NSLog(@"----%@",[models DEBUGDescrption]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
