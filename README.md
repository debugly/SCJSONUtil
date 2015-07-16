# QLJSON2Model

> 很放便把JSON转为Model,主要使用了KVC，充分利用KVC赋值时key不存在情况的处理；

### 简介

* QLBaseModel类中的提供的方法：

```
/**
 *
 *  创建一个已经赋过值的model对像
 *
 *  @param dic 与 modle 属性对应的字典
 *
 */
+ (instancetype)instanceFormDic:(NSDictionary *)dic;

/**
 *  brief:  JSON数组--》model数组,if JSON is nil or empty return nil;
 */
+ (NSArray *)instanceArrFormArray:(NSArray *)arr;

//创建实例后用这个方法可以把字典里的值塞到model中，这个方法不会触发valueNeedTransfer方法；
- (void)assembleDataFormDic:(NSDictionary *)dic;

```
* QLBaseModel类遵循了AnalyzeJSON2ModelProtocol协议，并实现了这些方法：

```
/**
 *  brief:  存放冲突key映射的字典 @{@"id":@"Newsid"}
 */
- (NSDictionary *)collideKeysMap;

/**
 *  brief:  存放冲突key映射Model的字典，@{@"courses":@"CourseModel"}
 */
- (NSDictionary *)collideKeyModelMap;

//如果需要进行值的转化，可以实现这个方法；比如：你想把一个String转为URL等
- (void)valueNeedTransfer;
```

* QLBaseModel默认把number转为字符串：
```
const bool isTransferNumber2String = true;    //？将数字转为字符串
```

### 使用方法：

>建立与JSON对应的Model，必须继承QLBaseModel，字段名字一一对应即可；
比如现在要解析ManageConcern文件里的JSON，那么步骤如下：

* 1 建立一个名为ManageConcern的类,类名没有限制，可以随便起名字；
* 2 把JSON的第一层级的key作为ManageConcern的属性，如果遇到字典就重复步骤（1）然后把新建的类作为属性，key一定不要和JOSN的key对应；如果遇见数组就进行步骤(3)；
* 3 数组的key一定不要和JOSN的key对应！！

经过上面3步之后，应该是这样的：

```
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

```
* 4 接下来需要在 .m 中配置，或者叫解决我们上述步骤中故意制造的“冲突”：

```
@implementation ManageConcern

- (NSDictionary *)collideKeysMap
{
    return @{@"content":@"contenModel"}; //字典的key：json的key，字典的value：model的属性名
}

- (NSDictionary *)collideKeyModelMap
{
    return @{@"content":@"ContenModel"}; //字典的key：json的key，字典的value：model的类名
}
@end
```
按照上述的注释很容易返回一个字典，类似的ContenModel也需要配置下：

```
@implementation ContenModel

- (NSDictionary *)collideKeysMap
{
    return @{@"favList":@"favArr"};
}

- (NSDictionary *)collideKeyModelMap
{
    return @{@"favList":@"FavModel"};
}

@end
```
* 5 最后处理下FavModel，这个类有个属性value需要转化：

```
@implementation FavModel
//处理就好了
- (void)valueNeedTransfer
{
    if (self.pic) {
        self.pic = [NSURL URLWithString:(NSString *)self.pic];
    }
}

@end
```
* 解析的结果：

<img src="https://github.com/SummerHanada/QLJSON2Model/blob/master/Snip20150716_2.png" width="392" height="453">

