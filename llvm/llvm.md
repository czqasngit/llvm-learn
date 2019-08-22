# LLVM & Clang 导航
![](https://ws3.sinaimg.cn/large/006tNc79gy1g2j8a0ij5kj31jk0dwkjl.jpg)
### LLVM
- 是一个模块化可重用的编译器工具链集合
- 不是首字母的缩写,它就是一个项目的完整名称
- 核心库围绕一种良好的代码表示语言(`IR`)提供了优化器与目标CPU代码生成器(包括一些不常见的CPU)

-
#### Clang
- 是LLVM的前端编译器(语法,语意分析,生成`IR`代码)
- 在调试模式下编译`Objective-C`代码比`GCC`快3倍
- 提供精准的错误与警告信息

-
### LLDB
- 构建在`LLVM`与`Clang`提供的库之上
- 使用`Clang AST`与表达式,`LLVM JIT`, `LLVM` 反汇编程序
- 加载符号表与GDB快且内存使用率更高


