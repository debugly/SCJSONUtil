//
//  VideoList.m
//  SCJSONUtilDemo
//
//  Created by Matt Reach on 2019/1/16.
//  Copyright © 2019 xuqianlong. All rights reserved.
//

#import "VideoList.h"

@implementation VideoItem

@end

@implementation VideoList

- (NSDictionary *)sc_collideKeysMap
{
    return @{@"wp" : @"wps"};
}

- (NSDictionary *)sc_collideKeyModelMap
{
    return @{@"videos":@"VideoItem"};
}

- (BOOL)sc_unDefinedKey:(NSString **)keyPtr forValue:(id *)valuePtr refObj:(id)refObj
{
    NSDictionary *refDic = refObj;
    NSString *key = *keyPtr;
    NSString *mapedKey = [refDic objectForKey:key];
    if (mapedKey) {
        *keyPtr = mapedKey; 
        NSDictionary *value = *valuePtr;
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSArray *videos = value[@"videos"];
            *valuePtr = videos;
        }
        return YES;
    }
    return NO;
}
@end
