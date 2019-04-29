## clang plugin using AST Matcher

```
#include "clang/Frontend/FrontendPluginRegistry.h"
#include "clang/Frontend/FrontendAction.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/AST/ASTConsumer.h"
#include "clang/AST/DeclObjC.h"
#include "clang/ASTMatchers/ASTMatchFinder.h"
#include "clang/Basic/Diagnostic.h"

using namespace clang;
using namespace ast_matchers;

namespace XTPlugin {
    
    class XTMatchCallback: public MatchFinder::MatchCallback {
    private:
        /// 编译器实例
        CompilerInstance &ci;
        /// 诊断实例
        DiagnosticsEngine &de;
    public:
        XTMatchCallback(CompilerInstance &ci): ci(ci),de(ci.getDiagnostics()) {

        }
        /// 当我们绑定的查找节点被找到后,调用此方法
        void run(const MatchFinder::MatchResult &Result) {
            /// 通过节点查找到我们绑定的ID(可以同时绑定多个)
            const ObjCInterfaceDecl *decl = Result.Nodes.getNodeAs<ObjCInterfaceDecl>("ObjCInterfaceDecl");
            if(!decl) return ;
            /// 获取绑定信息:类名
            const StringRef _objcName = decl->getName();
            /// 得到第一个字符
            char firstChar = _objcName.data()[0];
            /// 得到类的位置信息
            SourceLocation loc = decl->getLocation();
            /// 查找类名中是否有下划线
            size_t pos = _objcName.find('_');
            /// 判断位置是否找到
            if(pos != StringRef::npos) {
                /// 报告错误信息
                de.Report(loc.getLocWithOffset(pos), de.getCustomDiagID(DiagnosticsEngine::Error, "类名中不能包含下划线"));
            } else if(firstChar >= 97 && firstChar <= 97 + 26) {
                /// 报告错误信息
                de.Report(loc, de.getCustomDiagID(DiagnosticsEngine::Error, "类名首字母不能是小写"));
            }
        }
    };
    
    /// 插件消费者
    /// 通过多个编译周期的回调来编写业务逻辑
    class XTASTConsumer: public ASTConsumer {
        /// 允许在clang AST上查找对应的节点信息
        MatchFinder matcherFinder;
        /// 查找到对应的节点信息时的回调处理类
        XTMatchCallback handler;
    public:
        /// 初始化
        XTASTConsumer(CompilerInstance &ci): handler(ci) {
            /// 通过
            /// 第一个参数是DeclarationMatcher,这里有多个重载版本
            /// DeclarationMatcher=internal::Matcher<Decl>
            /// Matcher要求传入一个MatcherInterface,来实现具体的匹配逻辑
            /// DeclarationMatcher同文件下已经帮我们定义了多个实现不同节点的仿函数
            /// objcInterfaceDecl被定义为返回BindableMatcher匹配ObjCInterfaceDecl节点的仿函数实例
            /// 通过调用BindableMatcher的bind方法,定义了我们需要查找的节点的名称
            /// 第二个参数则是我们查找匹配到bind的节点后的回调对象
            matcherFinder.addMatcher(objcInterfaceDecl().bind("ObjCInterfaceDecl"), &handler);
            
        }
        /// 当一个AST单元编译完成后回调
        void HandleTranslationUnit(ASTContext &Ctx) {
//            llvm::outs() << ".........\n" ;
            matcherFinder.matchAST(Ctx);
        }
    };
    
    /// 编写继承至PluginASTAction的插件
    class XTPluginASTAction: public PluginASTAction {
        /// 创建并返回消费者
        /// 在Compile之前，创建ASTConsumer。在建立AST的过程中，ASTConsumer提供了众多的Hooks
        std::unique_ptr<ASTConsumer> CreateASTConsumer(CompilerInstance &CI,
                                                       StringRef InFile) {
            return std::unique_ptr<XTASTConsumer>(new XTASTConsumer(CI));
        }
        /// Parse the given plugin command line arguments.
        /// 解析编译时的参数,通过参数决定是否要在编译完AST时响应插件
        /// 返回true即响应
        /// 返回false即不响应
        /// 不论返回true还是false都可以通过CompilerInstance提供警告信息,同时也可以报告,并中断编译过程
        bool ParseArgs(const CompilerInstance &CI,
                       const std::vector<std::string> &arg) {
//            DiagnosticsEngine &D = CI.getDiagnostics();
//            D.Report(D.getCustomDiagID(DiagnosticsEngine::Warning, "解析参数报错..."));
            return true;
        }
    };
}

/// 注册插件
/// 通过FrontendPluginRegistry的类Add实例化同时将插件信息添加到链表
static FrontendPluginRegistry::Add<XTPlugin::XTPluginASTAction> X("XTPlugin", "XTPlugin description");
```

