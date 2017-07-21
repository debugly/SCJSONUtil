SCJSONUtil 
============

# Installation with CocoaPods

在你的 `Podfile` 文件里添加:

```
target 'TargetName' do
	pod 'SCJSONUtil', '~> 2.4.0'
end
```

# 特性
1. 小巧（仅300余行），快速，方便
2. 支持自定义属性名（比如服务器返回的是id，我们的model里可定义为uid）
3. 支持类型自动匹配（比如服务器返回的是Number，model里定义的是String，那么会解析为 String）

> 在 2.1 之前该框架会将服务器返回的字段统统转为 NSString 类型，因此 model 的头文件里定义的全都是 NSString 类型，这对于使用者来说是个恶心的限制，有用户还有我的团队都给我反馈过这个问题，因此我决定支持下类型自动匹配的功能，因此更加完美了呢！

# 使用说明

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
假设responseJSON是服务器返回的json数据，那么正规的写法是先判断 code 是否等于 0，然后再取出 gallery 对应的json，然后交给 JSONUtil ！JSONUtil提供了便捷的方法能够方便将它取出来：

//1.根据 keypath 取出目标json
    id findedJSON = SCFindJSONwithKeyPath(@"content/gallery", responseJSON); 
//2.使用 JSONUtil 解析
    NSArray *models = SCJSON2Model(findedJSON, @"GalleryModel");

//models 就是你想要的GalleryModel数组了！
	
```

其他的用法，可以参考demo。

---
	
# 核心思想

1. 递归，JSON 是可以嵌套的，因此这是一个递归的问题；
2. 遍历 JSON，而不是遍历model
3. 适当的地方进行 ValueTransfer，做到类型自动匹配
4. 通过 kvc 给 model 赋值

核心的思想应该是一样的，不过具体实现差别还真的挺大的！

### 主流 JSON 转 Model 流程
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
	- 查到了，说明model里定义了该属性，就通过 Runtime 取出属性的类型，解析继续往下走
	- 查不到，说明model里不关心该属性，开始下次遍历
- 如果值是数组或者字典则开始递归
- 通过第二步获取的属性类型和json值类型比较
	- 类型一致，则直接 kvc 赋值
	- 类型不一致，则先进行转换，然后再 kvc 赋值

### JSONUtil 与主流转换框架的区别

可以看出： **JSONUtil 遍历的是服务器返回的 JSON 而不是model的全部属性，并且没做 cache ！这是与其他框架有很大区别！**

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


# Versions

* 1.0 必须继承 QLBaseModel 父类;
* 1.0.1 在属性命名上有限制，对于子model必须故意制造出"冲突 key";
* 1.0.2 去掉了必须制造冲突 key 的限制,使用起来友好了许多;
* 2.0 则去掉了必须继承父类的限制，可谓更贴合实际了; QLJSON2Model 改名为 JSONUtil ！
* 2.1 自动匹配类型，比如服务器返回了一个Number，客户端model属性是String，那么框架会帮你自动转为String！
* 2.2 公司项目也使用这个库，因此遵循内部的命名规范，统一加上sl(SL)前缀！
* 2.3 公司内部工程重构，将该库提取到了通用库中，因此修改了类名将 SL 改为了 SC ，方便日后及时更新该库!
* 2.4 支持 CocoaPods 安装；demo使用pods！