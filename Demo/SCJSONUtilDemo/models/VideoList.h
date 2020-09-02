//
//  VideoList.h
//  SCJSONUtilDemo
//
//  Created by Matt Reach on 2019/1/16.
//  Copyright © 2019 xuqianlong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoItem : NSObject

@property (nonatomic,assign) long no;
@property (nonatomic,copy) NSString *showName;
@property (nonatomic,copy) NSString *title;
@property (nonatomic,copy) NSString *domain;
@property (nonatomic,strong) NSNumber *type;
@property (nonatomic,strong) NSNumber * rid;
@property (nonatomic,copy) NSMutableString * rSwfurl;
@property (nonatomic,copy) NSMutableString * url;
@property (nonatomic,strong) NSNumber * uid;

@end

@interface VideoList : NSObject

@property (nonatomic,copy) NSString *area;
@property (nonatomic,assign) long playlistid;
@property (nonatomic,strong) NSArray<VideoItem *> *videos;
///没有指定model，原值输出！
@property (nonatomic,strong) NSArray *wps;
///不能解析！
@property (nonatomic,assign) int array;
@property (nonatomic,assign) BOOL activity;
@property (nonatomic,copy) NSMutableString * smallVerPicUrl;
@property (nonatomic,copy) NSMutableString * showAlbumName;

@end

NS_ASSUME_NONNULL_END
