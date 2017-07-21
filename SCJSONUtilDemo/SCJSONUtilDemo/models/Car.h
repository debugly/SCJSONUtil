//
//  Car.h
//  QLJSON2Model
//
//  Created by xuqianlong on 2016/12/18.
//  Copyright © 2016年 xuqianlong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FavModel.h"
#import "objc/runtime.h"
@interface Car : NSObject

@property (nonatomic, strong) FavModel *pStorng;
@property (nonatomic, weak) NSNumber *pWeak;
@property (nonatomic, retain) NSMutableArray *pRetain;
@property (nonatomic, copy) NSString *pCopy;
@property (nonatomic, assign) NSArray *pAssign;
@property (nonatomic, readonly) NSArray *pReadonly;
@property (nonatomic, readonly,getter=isReadonly) NSArray *pReadonlyGetter;
@property (atomic, assign) NSDictionary *pAutomicAssign;
@property (atomic, retain) NSDictionary *pAutomicRetain;
@property (nonatomic, retain) NSMutableArray <NSObject * > * pFanXing;

@property (nonatomic, strong) id pID;
@property (nonatomic, strong) dispatch_block_t pBlock;
@property (nonatomic, strong) Class pClass;
@property (nonatomic, assign) SEL pSEL;
@property (nonatomic, assign) Method pMethod;

@property (nonatomic, assign) float pFloat;
@property (nonatomic, assign) double pDouble;

@property (nonatomic, assign) Byte pByte;
@property (nonatomic, assign) char pChar;
@property (nonatomic, assign) short pShort;
@property (nonatomic, assign) int pInt;
@property (nonatomic, assign) long pLong;
@property (nonatomic, assign) long long pLongLong;
@property (nonatomic, assign) BOOL pBool;
@property (nonatomic, assign) bool pbool;

@property (nonatomic, assign) bool b;
@property (nonatomic, assign) bool b1;
@property (nonatomic, assign) bool b2;

@end
/*
 T@"FavModel",&,N,V_pStorng
 T@"NSNumber",W,N,V_pWeak
 T@"NSMutableArray",&,N,V_pRetain
 T@"NSString",C,N,V_pCopy
 T@"NSArray",N,V_pAssign
 T@"NSArray",R,N,V_pReadonly
 T@"NSArray",R,N,GisReadonly,V_pReadonlyGetter
 T@"NSDictionary",V_pAutomicAssign
 T@"NSDictionary",&,V_pAutomicRetain
 T@,&,N,V_pID
 T@?,C,N,V_pBlock
 T#,&,N,V_pClass
 T:,N,V_pSEL
 T^{objc_method=},N,V_pMethod
 Tf,N,V_pFloat
 Td,N,V_pDouble
 TC,N,V_pByte
 Tc,N,V_pChar
 Ts,N,V_pShort
 Ti,N,V_pInt
 Tq,N,V_pLong
 Tq,N,V_pLongLong
 TB,N,V_pBool
 TB,N,V_pbool
 */
