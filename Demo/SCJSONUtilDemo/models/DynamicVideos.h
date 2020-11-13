//
//  DynamicVideos.h
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
@property (nonatomic,strong) NSNumber *rid;
@property (nonatomic,strong) NSNumber *uid;
@property (nonatomic,copy) NSMutableString *rSwfurl;
@property (nonatomic,copy) NSURL *url;

@end

@interface DynamicVideos : NSObject

@property (nonatomic,copy) NSString *area;
@property (nonatomic,assign) long playlistid;
@property (nonatomic,strong) NSArray<VideoItem *> *videos;
///没有指定model，原值输出！
@property (nonatomic,strong) NSArray *wps;
///与服务器返回类型不同，也不能自动转换，因此不能解析！
@property (nonatomic,assign) int array;
@property (nonatomic,assign) BOOL activity;
@property (nonatomic,copy) NSURL * smallVerPicUrl;
@property (nonatomic,copy) NSMutableString * showAlbumName;

@end

NS_ASSUME_NONNULL_END
