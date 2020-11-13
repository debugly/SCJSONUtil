//
//  Util.m
//  SCJSONUtilDemo
//
//  Created by Matt Reach on 2020/11/13.
//  Copyright © 2020 xuqianlong. All rights reserved.
//

#import "Util.h"

@implementation Util

+ (NSString *)jsonFilePath:(NSString *)fName
{
    return [[NSBundle mainBundle]pathForResource:fName ofType:@"json"];
}

+ (id)readBundleJSONFile:(NSString *)fName
{
    NSData *data = [NSData dataWithContentsOfFile:[self jsonFilePath:fName]];
    NSError *err = nil;
    id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
    if (err) {
        return nil;
    }
    return json;
}

+ (NSDictionary *)readOCTypes
{
    return [self readBundleJSONFile:@"OCTypes"];
}

+ (NSDictionary *)readCarInfo
{
    return [self readBundleJSONFile:@"Car"];
}

+ (NSDictionary *)readUserInfo
{
    return [self readBundleJSONFile:@"Userinfo"];
}

+ (NSArray *)readFavConcern
{
    return [self readBundleJSONFile:@"FavConcern"];
}

+ (NSDictionary *)readGalleryList
{
    return [self readBundleJSONFile:@"GalleryList"];
}

+ (NSDictionary *)readVideoList
{
    return [self readBundleJSONFile:@"DynamicVideos"];
}

+ (NSDictionary *)readVideoInfo
{
    return [self readBundleJSONFile:@"VideoInfo"];
}

+ (NSDictionary *)readStore
{
    return [self readBundleJSONFile:@"Store"];
}

@end
