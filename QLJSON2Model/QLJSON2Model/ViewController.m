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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSDictionary *userInfoDic = [self readUserInfo];
    
    UserInfoModel *uModel = [UserInfoModel instanceFormDic:userInfoDic];
    
    NSDictionary *mConInfoDic = [self readManageConcern];
    ManageConcern *mConModel = [ManageConcern instanceFormDic:mConInfoDic];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
