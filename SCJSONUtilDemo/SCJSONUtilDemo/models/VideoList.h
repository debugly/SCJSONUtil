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

@end

@interface VideoList : NSObject

@property (nonatomic,copy) NSString *area;
@property (nonatomic,assign) long playlistid;
@property (nonatomic,strong) NSArray<VideoItem *> *videos;

@end

NS_ASSUME_NONNULL_END
