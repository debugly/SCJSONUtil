//
//  UserInfoModel.h
//  QLJSON2Model
//
//  Created by xuqianlong on 15/7/14.
//  Copyright (c) 2015年 xuqianlong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AvatarInfoModel : NSObject

@property (nonatomic,copy) NSString *original_url;
@property (nonatomic,copy) NSString *thumbnail_url;
@property (nonatomic,copy) NSURL *raw_url;

@end

@interface CarInfoModel : NSObject

@property (nonatomic,copy) NSString *bought_time;
@property (nonatomic,copy) NSString *brand;
@property (nonatomic,retain) AvatarInfoModel *brandImg;

@end

@interface BasicInfoModel : NSObject

@property (nonatomic,retain) AvatarInfoModel *avatarInfo;
@property (nonatomic,copy)   NSString *gender;
@property (nonatomic,assign) long uid;
@property (nonatomic,copy)   NSString *name;
@property (nonatomic,copy)   NSString *phone_number;

@end

@interface DataInfoModel : NSObject

@property (nonatomic,retain) BasicInfoModel *basicInfo;
@property (nonatomic,retain) NSMutableArray *carInfoArr;

@end

@interface UserInfoModel : NSObject

@property (nonatomic,copy) NSString *code;
@property (nonatomic,retain) DataInfoModel *data; 
@property (nonatomic,copy) NSString *test;

@end

