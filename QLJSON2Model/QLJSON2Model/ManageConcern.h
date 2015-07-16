//
//  ManageConcern.h
//  QLJSON2Model
//
//  Created by xuqianlong on 15/7/16.
//  Copyright (c) 2015年 xuqianlong. All rights reserved.
//

#import "QLBaseModel.h"

@interface FavModel : QLBaseModel

@property (nonatomic, copy) NSString *refContent;
@property (nonatomic, copy) NSString *nameEN;
@property (nonatomic, copy) NSString *nameCN;
@property (nonatomic, copy) NSURL *pic; //这个需要手动transfer

@end

@interface ContenModel : QLBaseModel

@property (nonatomic, strong) NSMutableArray *favArr;//这个需要注意属性名

@end

@interface ManageConcern : QLBaseModel

@property (nonatomic, copy) NSString *code;//默认都是字符串，不存在Number；
@property (nonatomic, copy) NSString *msg;
@property (nonatomic, strong)ContenModel *contenModel;//这个需要注意属性名,故意和json不一样

@end
