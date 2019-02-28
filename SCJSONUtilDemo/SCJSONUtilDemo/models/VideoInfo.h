//
//  VideoInfo.h
//  SCJSONUtilDemo
//
//  Created by Matt Reach on 2019/2/28.
//  Copyright © 2019 xuqianlong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCJSONUtil.h"

NS_ASSUME_NONNULL_BEGIN

@interface VideoSection : NSObject<SCJSON2ModelProtocol>

@property (nonatomic, assign) int ck;
@property (nonatomic, copy) NSString *hc;
@property (nonatomic, copy) NSString *du;

@end

@interface VideoInfo : NSObject<SCJSON2ModelProtocol>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSArray <VideoSection*>*sections;

@end

NS_ASSUME_NONNULL_END
