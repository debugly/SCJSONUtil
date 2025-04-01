//
//  ViewController.m
//  SCJSONUtilDemo
//
//  Created by xuqianlong on 2017/7/21.
//  Copyright © 2017年 xuqianlong. All rights reserved.
//

#import "ViewController.h"
#import "Test.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *txv;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    [Test testPerformance];
    [Test printTypeEncodings];
    
    self.txv.text = [Test testAll];
//    self.txv.text = [Test testOCTypes];
//    self.txv.text = [Test testKeyPathFromDictionary];
//    self.txv.text = [Test testModelFromDictionary];
//    self.txv.text = [Test testModelsFromJSONArr];
//    self.txv.text = [Test testKeyPath];
//    self.txv.text = [Test testDynamicConvertFromDictionary];
//    self.txv.text = [Test testCustomConvertFromDictionary];
}

@end
