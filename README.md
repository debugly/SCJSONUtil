SCJSONUtil
============

[![Version](https://img.shields.io/cocoapods/v/SCJSONUtil.svg?style=flat)](https://cocoapods.org/pods/SCJSONUtil)
[![License](https://img.shields.io/cocoapods/l/SCJSONUtil.svg?style=flat)](https://cocoapods.org/pods/SCJSONUtil)
[![Platform](https://img.shields.io/cocoapods/p/SCJSONUtil.svg?style=flat)](https://cocoapods.org/pods/SCJSONUtil)

## 特性

1. 小巧方便，功能强大
2. 支持映射属性名（比如服务器返回的是id，我们的model里可定义为uid）
3. 类型自动匹配（比如服务器返回的是Number，model里定义的是String，那么就会解析为 String）

## 使用 CocoaPods 安装

在 `Podfile` 文件里添加:

```
target 'TargetName' do
    pod 'SCJSONUtil'
end
```

## 使用说明

《一看二建三解析》，直接看代码比较直观：

* 先看 JOSN ，毕竟我们是要把 JSON 转为 Model 嘛

```
{
    "code": "0",
    "content": {
        "gallery": [
                    {
                    "isFlagship": "0",
                    "name": "白色情人节 与浪漫牵手",
                    "pic": "http://pic16.shangpin.com/e/s/15/03/06/20150306174649601525-10-10.jpg",
                    "refContent": "http://m.shangpin.com/meet/189",
                    "type": "5"
                    },
                    ...
                    ]
      }
}
```

* 根据服务器的json(嵌套关系)建立 model (子model)；

```
@interface GalleryModel : NSObject

@property (nonatomic, copy) NSString *isFlagship;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *pic;
@property (nonatomic, copy) NSString *refContent;
@property (nonatomic, copy) NSString *type;

@end
```

* 使用JSONUtil解析

```
假设responseJSON是服务器返回的json数据，常规的写法是先判断 code 是否等于 0，然后再取出 gallery 对应的json 转成 model; 然而 SCJSONUtil 
提供了更加便捷的方法完成这些步骤：

//1.根据 keypath 取出目标json
id findedJSON = SCFindJSONwithKeyPath(@"content/gallery", responseJSON); 
//2.使用 JSONUtil 解析
NSArray *models = SCJSON2Model(findedJSON, @"GalleryModel");
//models 就是你想要的GalleryModel数组了！
```

其他的用法，可以参考demo。

---

## 核心思想

1. 递归：JSON 是可以嵌套的，因此这是一个递归的问题；
2. 遍历 JSON，根据遍历出的 json 里的key，去 model 里查找对应的映射名或者属性名
3. 适当的地方进行 ValueTransfer，做到类型自动匹配
4. 通过 kvc 给 model 赋值

### 其他 JSON 转 Model 框架的大致流程

这里要解释下第二点，因为这里我和其他的 JSON 转 Model 框架的实现大不相同！先来看下其他的主流思想：

- 使用 Runtime 获取目标Model类的全部属性！
  - 注意这里只能获取到自身的属性，父类的则无法获取到！考虑到继承是我们的一大特性，不应该去限制 Model 类不能有父类（除了NSObject这个基类外），因此需要通过 superClass 去向上遍历，并且遍历到系统类为止，否则的话，可能会获取到一些不是你想要的属性来，可能会为后续工作带来不必要的麻烦。
- 将上一步获取到的**全部属性**缓存到一个全局的区域里，保证下次能够走缓存！
  - 因为解析的时候，往往都是给出一个类，而不是给个对象，因此缓存需要跟类挂钩，比如定义一个字典，将类名作为key值，value 则是需要缓存的属性；具体做法也很简单，我曾经写过一篇剖析关联引用底层的文章，系统的做法跟这个类似，其实就是通过静态变量来做，然后可以提供类方法访问，类似于Java的类变量。
  - 这里说的属性，一般包括属性名，属性类型等字段。
- 拿到Model类的全部属性后开始遍历
  - 在遍历的时候，判断一些全局的忽略设置，值的转化处理等。
  - 如果值是字典或者数组，则会递归。

### JSONUtil 转 Model 流程

- 遍历服务器返回的JSON
- 根据遍历的key，去model里查询该属性
  - 先看看是否做了属性名映射，没映射就用key当作属性名
  - 查到了，说明model里定义了该属性，就通过 Runtime 取出属性的类型，解析继续往下走
  - 查不到，说明model里不关心该属性，继续遍历
- 如果值是数组或者字典则创建一个数组或者字典对应的Model开始递归
- 通过第二步获取的属性类型和json值类型比较
  - 类型一致，则直接 kvc 赋值
  - 类型不一致，则先进行转换，然后再 kvc 赋值

### JSONUtil 不做 cache 的原因

知道了主流做法后，再来看下 JSONUtil 是如何处理的吧，你会发现 JSONUtil 有很有特色，因为随大流地的去模仿做 cache ，遍历 model 的全部属性，之所以没有这么做，是因为我觉得 **没有必要**！

- 做 cache 是为了**下次**解析更快，你知道将一个json转换出一个model需要多久吗？对于普通JSON其实不用担心的，如果真的担心，何不使用 GCD 去异步线程里做呢？试问你愿意多看1秒钟（异步GCD解析）的loading还是愿意让App卡顿0.5秒钟（主线程解析）？

- 举个不太恰当的例子哈：如果model是个3G开关，该开关只会在App启动时请求一次，那么cache反而没什么卵用，说不定还会更耗时！

- 再比如我的解析框架做了cache，解析的速度非常之快，是不是你就敢大胆的在主线程进行所有的JSON解析？你就不怕有大个的JOSN吗？

- 如果做了cache，并且在异步线程解析，岂不是更快？是的，的确会快一些，那个差别你是感受不到的，**为了你感受不到的快感而去浪费很长的时间层层遍历属性做个cache**，这是不值得的，不知道你是否同意？

这是我的做的测试：

```
    NSDictionary *userInfoDic = [self readUserInfo];

    [self testCount:100000 work:^{
        UserInfoModel *uModel = [UserInfoModel instanceFormDic:userInfoDic];
    }];
    // 10000 次转换耗时:0.51412s
    // 100000 次转换耗时:4.61152s
```

也就是说使用 JSONUtil 转换一个嵌套4层（里面也有数组）的 model ，转换一次需要: **0.0514ms**.

### 为什么 JSONUtil 选择遍历服务器返回的 JSON ？

遍历终究是要做的，有两种做法，一种是遍历 model的所有属性，另一种是遍历 服务器返回的json；究竟如何选择，困扰了我许久，最后我选择了后者，因为前者的代价较高，需要层层向上遍历，最可恶的是**递归的出口不好把握**，因此选择了后者规避了这个问题！

另一方面选择后者是因为，根据我解析的习惯是，服务器定义的字段我都会解析，但是有的字段服务器可能不返回，如果按照前者的遍历方式，会增加几次多余的遍历；当然我否定使用后者不会出现多余的遍历，这个定义model的习惯和服务器返回json的空值都有关系！

## 版本

* 1.0 必须继承 QLBaseModel 父类

* 1.0.1 在属性命名上有限制，对于子model必须自定义属性名才行

* 1.0.2 去掉了必须自定义属性名的限制

* 2.0 则去掉了必须继承父类的限制，改名为 JSONUtil

* 2.1 增加匹配自动类型功能，比如服务器返回的 Number，客户端定义的是 String，那么会帮你自动转为 String

* 2.2 公司项目也使用这个库，命名规范需要，统一加上 sl(SL)前缀

* 2.3 项目重构，将该库提取到了通用库中，SL 前缀改为 SC

* 2.4 支持 CocoaPods 集成

* 2.4.1 清理没用的方法

* 2.4.2 当服务器返回数据不能转化为 Number 时，不使用 KVC 赋值

* 2.4.3 开始在 OS X 平台测试使用

* 2.4.4 增删类别方法，增加警告信息，创建Model更加省心
  
  ```
  做了类型自动映射后，sc_valueNeedTransfer 显得鸡肋，因此去掉了
  - (void)sc_valueNeedTransfer; 方法。
  新增
  - (id)sc_key:(NSString *)key beforeAssignedValue:(id)value;
  //增加警告信息
  2018-11-27 18:30:17.844219+0800 SCJSONUtilDemo[91682:1947248] ⚠️ UserInfoModel 类没有解析 test 属性;如果客户端和服务端key不相同可通过sc_collideKeysMap 做映射！value:testValue
  2018-11-27 18:30:17.844351+0800 SCJSONUtilDemo[91682:1947248] ⚠️⚠️ DataInfoModel 类的 cars 属性没有指定model类名，这会导致解析后数组里的值是原始值，并非model对象！可以通过 sc_collideKeyModelMap 指定 @{@"cars":@"XyzModel"}
  ```

* 2.4.5 增加类别方法，可动态做 key-value 映射

* 2.4.6 增加类别方法，可自定义解析过程

* 2.4.7 修复通过 KVC 给标量赋值为 nil 时导致的崩溃

* 2.4.8 修复没有配置 Model 名时，解析完毕后，属性值为nil问题

* 2.4.9 当服务器返回值是数组类型，而 Model 属性不是数组类型时，不进行解析

* 2.5.0 支持解析 long long 类型，丰富测试 case

* 2.5.1 支持 fileURL 类型，丰富测试 case

* 2.5.2 增加日志控制开关，更加灵活

* 2.5.3 重构解析过程，支持 keypath 映射

* 2.5.4 支持 Model 转 json；提供 JSON2String 工具方法

* 2.5.5 修复服务端返回字段是 description，hash 等只读属性字段时的崩溃

* 2.5.6 解决 Xcode14 找不到 libarclite_iphoneos.a 问题

* 2.5.7 支持 tvos 平台
