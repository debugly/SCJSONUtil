//
//  GalleryModel.h
//  QLJSON2Model
//
//  Created by xuqianlong on 15/9/8.
//  Copyright © 2015年 xuqianlong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GalleryModel : NSObject

@property (nonatomic, copy) NSString *isFlagship;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *pic;
@property (nonatomic, copy) NSString *refContent;
@property (nonatomic, copy) NSString *type;

@end

/*
 "isFlagship": "0",
 "name": "白色情人节 与浪漫牵手",
 "pic": "http://pic16.shangpin.com/e/s/15/03/06/20150306174649601525-10-10.jpg",
 "refContent": "http://m.shangpin.com/meet/189",
 "type": "5"

 */