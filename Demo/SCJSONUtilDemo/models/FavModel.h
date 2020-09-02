//
//  FavModel.h
//  QLJSON2Model
//
//  Created by xuqianlong on 15/7/16.
//  Copyright (c) 2015年 xuqianlong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FavModel : NSObject

@property (nonatomic, copy) NSString *refContent;
@property (nonatomic, copy) NSString *nameEN;
@property (nonatomic, copy) NSString *nameCN;
@property (nonatomic, copy) NSURL *pic; //这个需要手动transfer
@property (nonatomic, copy) NSString *desc;

@end
