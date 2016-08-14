
//
//  FavModel.m
//  QLJSON2Model
//
//  Created by xuqianlong on 15/7/16.
//  Copyright (c) 2015年 xuqianlong. All rights reserved.
//

#import "FavModel.h"

@implementation FavModel
//处理就好了
- (void)valueNeedTransfer
{
    if (self.pic) {
        self.pic = [NSURL URLWithString:(NSString *)self.pic];
    }
}

@end
