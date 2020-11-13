//
//  Util.h
//  SCJSONUtilDemo
//
//  Created by Matt Reach on 2020/11/13.
//  Copyright © 2020 xuqianlong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Util : NSObject

+ (NSDictionary *)readOCTypes;

+ (NSDictionary *)readCarInfo;

+ (NSDictionary *)readUserInfo;

+ (NSArray *)readFavConcern;

+ (NSDictionary *)readGalleryList;

+ (NSDictionary *)readVideoList;

+ (NSDictionary *)readVideoInfo;

+ (NSDictionary *)readStore;

@end

NS_ASSUME_NONNULL_END
