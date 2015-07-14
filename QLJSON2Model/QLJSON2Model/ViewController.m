//
//  ViewController.m
//  QLJSON2Model
//
//  Created by xuqianlong on 15/7/14.
//  Copyright (c) 2015年 xuqianlong. All rights reserved.
//

#import "ViewController.h"
#import "UserInfoModel.h"

@interface ViewController ()

@end

@implementation ViewController

- (NSDictionary *)readUserInfo
{
    //==Json文件路径
    NSString *paths= [[NSBundle mainBundle]pathForResource:@"Userinfo" ofType:@"json"];
    //==Json数据
    NSDictionary *data = [NSDictionary dictionaryWithContentsOfFile:paths];
    //==JsonObject
    return data;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSDictionary *userInfoDic = [self readUserInfo];
    
    UserInfoModel *uModel = [UserInfoModel instanceFormDic:userInfoDic];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
