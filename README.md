# CTNetWork
A network framework based on AFNetWorking 


##CTNetwork是什么？
CTNetwork是一个基于**AFNetworking**封装的一个网络框架，它主要由**CTNetworkManager**、**CTBaseRequest**、**CTNetworkConfiguration**、**CTNetworkCache**组成。它的工作流程是先将每个网络请求封装成一个Request对象，然后交给CTNetworkManager发送请求，最后使用block调用回来。

##有哪些功能？
* 支持统一设置baseURL
* 提供对HTTP请求头的统一配置以及对特殊请求头配置
* 支持对网络请求的数据进行缓存以及配置不同的缓存策略
* 提供对Response解密的配置
* 支持不同的缓存策略请求以及缓存有效期的设置
* 扩展了批量发送请求
* 提供成功、失败block回调

##类的介绍
####CTBAseRequest
网络请求类，当发起一个网络请求的时候，需要子类化这个类。CTBaseRequest提供了跟业务相关的设置，例如设置是GET请求还是POST请求、请求的方法名、请求的业务参数、缓存策略、请求头等等。当需要发起一个请求时，使用startRequestWithSuccess发起请求，使用cancelRequest类方法取消请求。

####CTNetworkConfiguration
这是一个整个网络的配置类，它提供的功能有：

* 配置baseURL
* 对CTNetworkRequest进行预处理
* 对请求统一设置请求头
* 对请求设置query string
* 组装POST请求的请求体
* 对Response进行解密
* 配置对某个请求是否缓存


####CTNetworkManager
它是一个单例，协调着CTBaseRequest、CTNetworkCache和CTNetworkConfiguration三者进行工作。

####CTNetworkCache
一个以写文件的形式进行缓存的类。


##如何使用？

首先，子类化一个CTNetworkConfiguration类，实现CTNetworkConfiguration协议，对网络进行配置，在Appdelegate.m文件中将它设置给CTNetworkManager。   
```objective-c
    [[CTNetworkManager sharedManager] setNetworkConfiguration:[CTNetworkConfiguration configurationWithBaseURL:@"http://.......com/"]];```

    CTBaseRequest * request = [[CTBaseRequest alloc] initWithInterface:@"api/index/appdata.json"];
    [request startRequestWithSuccess:^(CTBaseRequest * _Nonnull request, id  _Nullable response) {
      NSLog(@" %@ %@ ", request, response);
    } failure:^(CTBaseRequest * _Nonnull request, NSError * _Nullable error) {
      NSLog(@"%@ ", error);
    }];
```

##Podfile
```
 platform :ios, '7.0'
 pod "CTNetWork"
 ```

##感谢
####本类库是在BGNetwork基础上进行的改造，大部分功能与BGNetwork类似，只根据自己需要进行适当改造，再次对BGNetwork的作者提出感谢
原文主页地址 https://github.com/chunguiLiu/BGNetwork
