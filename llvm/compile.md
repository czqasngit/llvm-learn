# LLVM and Clang 编译精简完整过程

![](https://ws4.sinaimg.cn/large/006tNc79gy1g2j8pi7avxj31jk0dw4qp.jpg)

### 下载llvm源码
- 找一个空间有30G的硬盘分区新建目录`llvm`
- 进入到`llvm`,下载`llvm`源码
    
```
git clone https://git.llvm.org/git/llvm.git
```
### 下载clang源码 
- 进入到llvm/tools

```
git clone https://git.llvm.org/git/clang.git
```

### 安装cmake

```
brew install cmake
```

### 安装ninja
- Ninja是一个专注于构建速度的小型构建系统
    
```
brew install ninja
```

### 配置cmake & ninja   
- 在llvm项目同级创建llvm-build目录,用于配置ninja编译环境
- 进入到llvm-build,配置ninja
    
```
//cmake [options] <path-to-source>
//-G <generator-name>          = Specify a build system generator.
// 指定编译构建系统
// -D <var>[:<type>]=<value>    = Create or update a cmake cache entry.
// 创建或者更新cmake默认的数据
// CMAKE_INSTALL_PREFIX 指定了目标文件输出目录
// https://cmake.org/cmake/help/v3.14/variable/CMAKE_INSTALL_PREFIX.html
// ../llvm即下载好的llvm源码目录,clang也在llvm被一同编译
cmake -G Ninja ../llvm -D CMAKE_INSTALL_PREFIX=/Volumes/Software/llvm_release
```
    
    配置完成后llvm-build目录中将生成以Ninja为构建系统的编译环境,用于编译llvm项目
### 编译llvm
- 在llvm-build目录中执行

```
ninja
```
开始编译llvm源码,大概3501个源文件

编译完成后,使用如下命令将llvm安装输出到`CMAKE_INSTALL_PREFIX`指定的目录,这里是../llvm-release,得到最终的可执行命令工具
`ninja`命令已经编译好了
`ninja install`就是把生成的结果必要的文件输出到`CMAKE_INSTALL_PREFIX`指定的目录

```
ninja install
```

安装完成后,可以bin目录中找到clang与clang++两个替换,他们的真身都是clang-9
到此,编译llvm与clang就完成了





