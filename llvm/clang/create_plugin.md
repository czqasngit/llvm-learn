# [精简详解]编写clang的插件并集成到Xcode

![](https://ws3.sinaimg.cn/large/006tNc79gy1g2j8qg918ej31jk0dw1kx.jpg)

### clang三大工具
- libClang
    - 稳定的C API,提供了AST较为基础的访问能力
    - 可在python/node.js/objective-c(ClangKit)下使用
    - 生成的工具可单独运行
- clang plugin
    - C++ 接口
    - 集成到clang编译器的插件中使用,可以在编译时提示警告与错误,可以中断编译过程
    - 完全的AST控制访问能力
- clang tooling
    - C++接口
    - 独立运行
    - 完成的AST控制访问能力
    - 与libClang相比,接口不稳定,版本更新时接口也更新
    - 能力
        - 改变代码: 基础clang生成的代码(IR)进行修改,也可以转换成其它语言
        - 语法检查: 由于可以访问完整的AST功能,所以可以进行语法、主意的检查
        - 分析&修改: 对源码做任何分析,增加删除代码,重写代码

##### AST详细解读请查看 [Clang之语法抽象语法树AST](https://www.cnblogs.com/zhangke007/p/4714245.html)
        
### 开始编写第一个clang plugin
- 进入到`llvm/tools/clang/examples`目录(clang提供的样例代码就在这里,我们也可以把插件放在其它目录,只要在上级CMakeLists.txt中注册就可以了)
- 新建一个插件目录: `xt-plugin`
- 将我们的插件注册到`examples`目录中的`CMakeLists.txt`,这样生成XCode模板的时候才会去编译添加`xt-plugin`

```
// 定义在llvm/tools/clang/cmake/modules/AddClang.cmake
add_clang_subdirectory(xt-plugin)
```
进入xt-plugin
创建XTPlugin.cpp文件
创建CMakeLists.txt文件,并添加如下代码

```
// add_llvm_library定义在llvm/cmake/modules/AddLLVM.cmake中
// macro(add_llvm_library name) 最终调用 function(llvm_add_library name)
// MODULE 会在内部添加插件名称与插件的具体实现代码
// 实现: add_library(${name} MODULE ${ALL_FILES})
// PLUGIN_TOOL The tool (i.e. cmake target) that this plugin will link against
// 插件要连接的cmake目标
add_llvm_library(XTPlugin MODULE XTPlugin.cpp PLUGIN_TOOL clang)
```
生成Xcode工程的时候会把xt-plugin/XTPlugin.cpp添加到工程目录树中

编写`XTPlugin.cpp`中的代码,如果我们单纯的直接编写XTPlugin.cpp会比较吃力,没有代码提示,编译每次都通过ninja后才知道错误
可喜的是cmake支持创建Xcode工程,`cmake`支持Xcode 3.0+ generate**(除了ninja我们也可以使用Xcode来编译完整的llvm源码并生成目标文件,但这个过程用时较长,所以我们使用ninja编译完一次之后,编译插件再使用Xcode来编译就会很方便,又能得到代码提示,查看相关源码也方便多了)**
首先,我们在llvm同级创建一个llvm-xcode用于存放llvm生成的Xcode工程
进入llvm-xcode,开始创建
命令如下:

```
// -G <generator-name>          = Specify a build system generator.
cmake -G Xcode ../llvm
```

生成好Xcode工程后,打开LLVM.xcodeproj
![](https://ws1.sinaimg.cn/large/006tNc79gy1g2ewxf862tj30v407agt9.jpg)
这里点击Automatically Create Schemes
然后在工程目录下找到XTPlugin
![](https://ws1.sinaimg.cn/large/006tNc79gy1g2ex04lmlqj30b80b4ag6.jpg)
到此,就可以开始编写clang plugin代码了😀

### 编译XTPlugin.cpp插件 [参考](https://clang.llvm.org/docs/ClangPlugins.html)
`Clang Plugins make it possible to run extra user defined actions during a compilation` 

1.编写PluginASTAction,从下图定义可以看出,继承后需要实现两个方法
![](https://ws2.sinaimg.cn/large/006tNc79gy1g2exi8tarsj313u0u0n6b.jpg)

```
// 解析编译插件时传递的命令行参数,来解决是否要响应这个PluginASTAction
// 返回true响应, false则不响应
// 这里可以通过CompilerInstance来实现一些动作,比如报警、报错
virtual bool ParseArgs(const CompilerInstance &CI, const std::vector<std::string> &arg) {
    return true;
}

// 上一个方法返回true后,就会通知我们创建一个ASTConsumer
// 返回继承至ASTConsumer的类
std::unique_ptr<ASTConsumer> CreateASTConsumer(CompilerInstance &CI,
                                                 StringRef InFile) {
    XTASTConsumer *consumer = new XTASTConsumer();
    return std::unique_ptr<XTASTConsumer>(consumer);
}
```
```
class XTASTConsumer: public ASTConsumer {
        
};
```
最后,我们还要注册插件

```
// A plugin is loaded from a dynamic library at runtime by the compiler. 
// To register a plugin in a library, use FrontendPluginRegistry::Add<>:
using namespace XTPlugin;
// 通过Add模板类的构造方法,将XTPluginASTAction与相关信息添加到node链表中
static FrontendPluginRegistry::Add<XTPluginASTAction> X("XTPlugin", "xt-plugin-description");

```
插件编写完成,选中XTPlugin Scheme编译一下,将会在llvm-xcode/Debug/lib中生成XTPlugin.dylib文件

到此我们的插件框架就编写完了,可以集成到Xcode中测试一下是否能正常工作了

首先新建一个工程,在Xcode的`Build Settings`中配置下面的参数

将我们编译好的动态库配置到Xcode `OTHER C FLAG`
通过使用`-Xclang`将参数传递给clang compiler
`-load` 后面跟上插件地址,此插件将被加载
`-add-plugin` 后面跟上参数名称, 即在AST生成完成后将自动调用插件

```
// -Xclang <arg>           Pass <arg> to the clang compiler
// https://clang.llvm.org/docs/ClangPlugins.html

-Xclang -load -Xclang /Volumes/Work/GitHub/llvm/llvm-xcode/Debug/lib/
XTPlugin.dylib -Xclang -add-plugin -Xclang XTPlugin
```

接下来配置clang编译器
![](https://ws4.sinaimg.cn/large/006tNc79gy1g2ezz27ajlj30m001g0sr.jpg)

在`Build Settings`的tool bar上面点击+按钮
![](https://ws1.sinaimg.cn/large/006tNc79gy1g2ezzrslwfj30bm0243z2.jpg)

添加User-Defined Setting
![](https://ws4.sinaimg.cn/large/006tNc79gy1g2f00k0fasj30zy026dg4.jpg)

配置的`clang`&`clang++`就是我们llvm-release目录中bin的两个替身,他们的真身都是`clang-9`
这样编译的时候会使用我们提供的编译器
![](https://ws3.sinaimg.cn/large/006tNc79gy1g2f0e19v3hj30me01gdfu.jpg)

Enable Index-While-Building Functionality设置为N0
Xcode 9+需要这样设置 
到此,编译一下测试工程,如果没有报错就表示编写的插件被正常加载了
接下来就是编写插件逻辑代码了

通过如下命令查看clang生成的AST信息

```
clang -Xclang -ast-dump -fsyntax-only ViewController.m
```

生成一个编译单元
![](https://ws2.sinaimg.cn/large/006tNc79gy1g2i2t7f6ukj316g01qwet.jpg)

从AST信息中可以得到完整的节点信息,我们想操作哪些节点都可以

![](https://ws2.sinaimg.cn/large/006tNc79gy1g2i2v1gwn0j31h606wmze.jpg)




