# QLJSON2Model 1.0.2

> 很放便把 JSON 转为 Model，主要使用了 KVC，如果属性名和服务返回 JSON 的 key 不同就配置下 collideKeysMap，如果嵌套了子 Model 就要配置下 collideKeyModelMap；特点是实现简单，性能也很好；当然业内也有功能更加强大的框架，比如： Mentle，ModelJSON，MJExtention 等，他们往往利用 runtime 获取类的属性，然后缓存，这些毕竟要消耗时间和更多的内存,使用系统提供的 KVC 机制或许要好些 ...
> 1.0.1版本在属性命名上有限制，所谓的"故意制造冲突 key"这个版本去掉了这个限制,更加友好了！

### 简介

> QLBaseModel 类中的提供的方法：

	
```
	/**
	*
	*  创建一个已经赋过值的 model 对像
	*
	*  @param dic 与 modle 属性对应的字典
	*
	*/
	+ (instancetype)instanceFormDic:(NSDictionary *)dic;
	
	/**
	*  brief:  JSON 数组--》model 数组,if JSON is nil or empty return nil;
	*/
	+ (NSArray *)instanceArrFormArray:(NSArray *)arr;
	
	//创建实例后用这个方法可以把字典里的值塞到 model 中，这个方法不会触发 valueNeedTransfer 方法；
	- (void)assembleDataFormDic:(NSDictionary *)dic;
	
```

> QLBaseModel 类遵循了 AnalyzeJSON2ModelProtocol 协议，并实现了这些方法：

```
	/**
	*  brief:  存放冲突 key 映射的字典 @{@"id":@"Newsid"}
	*/
	- (NSDictionary *)collideKeysMap;
	
	/**
	*  brief:  存放冲突 key 映射 Model 的字典，@{@"courses":@"CourseModel"}
	*/
	- (NSDictionary *)collideKeyModelMap;
	
	//如果需要进行值的转化，可以实现这个方法；比如：你想把一个 String 转为 URL 等
	- (void)valueNeedTransfer;
```

> QLBaseModel 默认把 number 转为 string：

```
const bool isTransferNumber2String = true;    //？将数字转为字符串
```

### 使用方法：

> 建立与 JSON 对应的 Model，必须继承 QLBaseModel，字段名字一一对应即可；
比如现在要解析 ManageConcern 文件里的 JSON，那么步骤如下：

> 1. 建立一个名为 ManageConcern 的类,类名没有限制，可以随便起名字；
> 2. 把 JSON 的第一层级的 key 作为 ManageConcern 的属性，如果遇到字典就重复步骤（1）然后把新建的类作为属性的类型，属性名和 key 一样即可，（不一样就进行步骤（5），上个版本是必须 **不一样** 的，感觉没必要），然后进行步骤（4）；如果遇见数组就进行步骤(3)；
> 3. 数组属性名和 key 一样即可（不一样就进行步骤（5），上个版本，是必须不一样，感觉没必要），然后在.m 配置 key 对应的 model；
> 4. 在.m 配置 key 对应的 model；实现collideKeyModelMap方法；
> 5. 在.m 配置 key 对应的 属性名；实现collideKeysMap方法；

按照上面的步骤，我先处理建立model：

```
	@interface FavModel : QLBaseModel
	
	@property (nonatomic, copy) NSString *refContent;
	@property (nonatomic, copy) NSString *nameEN;
	@property (nonatomic, copy) NSString *nameCN;
	@property (nonatomic, copy) NSURL *pic; //这个需要手动transfer
	
	@end
	
	@interface ContenModel : QLBaseModel
	
	@property (nonatomic, strong) NSMutableArray *favArr;//这个属性名和JOSN的key不一样
	
	@end
	
	@interface ManageConcern : QLBaseModel
	
	@property (nonatomic, copy) NSString *code;//默认都是字符串，不存在Number；
	@property (nonatomic, copy) NSString *msg;
	@property (nonatomic, strong)ContenModel *contenModel;//这个属性名和JOSN的key不一样	
	@end
	
```

>  接下来需要在 .m 中配置了，因为存在和 JSON 不同的 key，也存在 子 model，所以要做下面的配置：

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
> 按照上述的注释很容易返回一个字典，类似的 ContenModel 也需要配置下：

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
> 最后处理下 FavModel，这个类有个属性 value 需要转化：

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
现在是第二个版本了，在第一个版本中凡是配置子model字典的都要求 **属性名和 JSON 的 key 不一样 **，并且配置collideKeysMap，考虑到这样工作量大了一倍，所以这个版本就把这个限制去掉了! 编写Model 类更加省事了！如果属性名 都和 JSON 的 key 一样，那么你建立 model 的工作就只是配置下collideKeyModelMap 而已，完全不用去理会 collideKeysMap 了！

### 解析的结果：

<img src="https://github.com/SummerHanada/QLJSON2Model/blob/master/Snip20150716_2.png" width="392" height="453">

