//
//  StoreModel.h
//  SCJSONUtilDemo
//
//  Created by Matt Reach on 2020/11/13.
//  Copyright © 2020 xuqianlong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCJSONUtil.h"

NS_ASSUME_NONNULL_BEGIN

@interface StoreModel : NSObject<SCJSON2ModelProtocol>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSArray *order;
@property (nonatomic, strong) NSArray *category;
@property (nonatomic, strong) NSArray *weight;

@end

NS_ASSUME_NONNULL_END
