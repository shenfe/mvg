# mvg (modules via git)

> 方便起见，以下将项目开发时需要引入的外部代码、公共模块简称“包”。这类包通常是工具、辅助性质，而不是需要上线的服务。

极其简单的基于git的包管理器。不限语言和项目，只依赖shell和git。

## 基本思想

* 将git仓库视作包源，将branch或tag视作包版本，通过git将包的代码同步到项目本地
* 将包作为**项目代码的一部分**，且只从对应仓库更新
  * 有利于将公共模块抽离出去，作为git项目独立管理
  * 省去了“安装依赖包”这件事的麻烦（因为本质上是项目本地文件操作），便于部署

## 使用方法

在ini配置文件中定义依赖，执行sh脚本，即可将依赖同步至项目本地。

具体操作：

1. 将`mvg.sh`和`mvg.ini`拷贝至项目根目录下
2. 将`mvg.sh`脚本开头的`BASE_PATH`变量配置成自己想要的目录（默认为`./`），用于放置所有依赖包
3. 在`mvg.ini`中定义依赖
    1. 每个section相当于**包名**，git会在`BASE_PATH`目录下将对应的仓库clone到以该名字命名的子目录
    2. 为每个包定义`repo`（即git url；必填）、`checkout`（即branch或tag；选填）、`subpath`（在BASE_PATH下的子路径；选填）、`path`（在项目根路径下的子路径，不受BASE_PATH限制；选填）、`wrap`（包装形式，例如"py"则会将包放进名称带有包名hash的子文件夹中，再由与该子文件夹同级的__init__.py文件`import *`；选填）

    ```ini
    [a]
    repo=git@some.server.com:foo/mod_a.git

    [b]
    repo=git@some.server.com:foo/mod_b.git
    checkout=master

    [c]
    repo=git@some.server.com:foo/mod_c.git
    checkout=v1.0.0

    [d]
    repo=git@some.server.com:foo/mod_d.git
    subpath=d_pro

    [e]
    repo=git@some.server.com:foo/mod_e.git
    path=util/e

    [f]
    repo=git@some.server.com:foo/mod_f.git
    wrap=py
    ```
    
    3. 除了git方式外，还可以：定义`file`，可以通过curl将指定url的文件下载到指定路径；定义`cmd`，自定义下载过程。此外，可以自定义下载内容前后的过程：定义`cmd_before`，在下载包内容前执行；定义`cmd_after`，在下载包内容后执行

    ```ini
    [config]
    file=http://some.domain.com/path/to/config.py
    path=./static/

    [g]
    cmd_before=echo 'before'
    cmd=cd .. && git clone git@some.server.com:foo/mod_g.git
    cmd_after=echo 'after'
    ```

1. 执行`mvg.sh`，即可将配置定义的包一次同步到项目内；可以加参数，即指定（1个或多个）包名，脚本便只检查和更新指定的包

    ```bash
    $ ./mvg.sh # sync all
    $ ./mvg.sh mod_a mod_b # just sync `mod_a` and `mod_b`
    ```

## 注意事项

* 脚本内部执行git操作之后，会自动删除包的仓库中的.git目录
* 包的代码只从外部更新，而**不在项目开发过程中改动**，除非确定以后不再从外部更新这个包，或者愿意每次更新都合并改动
* 因为包的代码是项目代码的一部分，所以包的代码不用被git ignore，在依赖没有变动的情况下也不需要有一般包管理器的install操作

特别地，对于python模块，如果包含requirements.txt文件，建议在项目的requirements.txt中使用`-r vendor/mod_a/requirements.txt`的方式将模块的依赖引进项目的依赖。

## 相关工作

其实主流的包管理器如npm、pip都支持vcs。例如pip[对vcs的支持](https://pip.pypa.io/en/stable/reference/pip_install/#vcs-support)，但还不是最方便灵活。
