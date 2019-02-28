//
//  VideoInfo.m
//  SCJSONUtilDemo
//
//  Created by Matt Reach on 2019/2/28.
//  Copyright © 2019 xuqianlong. All rights reserved.
//

#import "VideoInfo.h"

@implementation VideoSection

@end

@implementation VideoInfo

- (void)sc_willFinishConvert:(id)data refObj:(id)refObj
{
    if([data isKindOfClass:[NSDictionary class]]){
        NSDictionary *dic = (NSDictionary *)data;
        NSDictionary *sectionData = dic[@"data"];
        if (sectionData) {
            NSArray *cks = sectionData[@"cks"];
            NSArray *hcs = sectionData[@"hcs"];
            NSArray *dus = sectionData[@"dus"];
            if ([cks isKindOfClass:[NSArray class]] && [hcs isKindOfClass:[NSArray class]] && [dus isKindOfClass:[NSArray class]]) {
                
                if ([cks count] == [hcs count] && [hcs count] == [dus count]) {
                    NSMutableArray *secArr = [NSMutableArray arrayWithCapacity:3];
                    for (int i = 0 ; i < [cks count]; i++) {
                        id ck = cks[i];
                        id hc = hcs[i];
                        id du = dus[i];
                        [secArr addObject:@{
                                            @"ck":ck,
                                            @"hc":hc,
                                            @"du":du
                                            }];
                    }
                    
                    NSArray <VideoSection *>* videoSecs = [VideoSection sc_instanceArrFormArray:secArr];
                    self.sections = videoSecs;
                }
            }
        }
    }
}

@end
