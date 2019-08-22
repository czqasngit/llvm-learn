## Create clang plugin using visit

```
#include "clang/Frontend/FrontendPluginRegistry.h"
#include "clang/Frontend/FrontendAction.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/AST/ASTConsumer.h"
#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/AST/DeclGroup.h"
#include "clang/AST/DeclObjC.h"
#include "clang/Basic/Diagnostic.h"
#include "clang/Tooling/Tooling.h"
#include <iostream>

using namespace clang;
using namespace std;
namespace TIM {
    
    /// 继承RecursiveASTVisitor
    /// 递归访问AST
    /// 1.当调用Traverse(Decl/Stmt/Type/Function)时进行,
    /// 这是切入点用于遍历以传入节点为根节点的AST
    /// 分发调用WalkUpFrom(Foo),然后再遍历子节点
    /// 2.WalkUpFrom(Bar)首先调用,其中Bar是Foo的直接父类,除非Foo没有父类
    /// 3.最后调用VisitFoo
    /// 注: 在这个例子中,我们调用visit.TraverseDecl(decl)
    ///     通过VisitObjCImplDecl得到对应ObjCImplDecl(ObjCImplementationDecl)的回调
    ///     bool VisitObjCImplDecl(ObjCImplDecl *decl)在对应的实现方法中判断我们的逻辑
    class TIMRecursiveASTVisitor: public RecursiveASTVisitor<TIMRecursiveASTVisitor> {
    private:
        CompilerInstance &ci;
    public:
        TIMRecursiveASTVisitor(CompilerInstance &ci): ci(ci) {
            
        }
        bool VisitObjCImplDecl(ObjCImplDecl *decl) {
            //            cout << "ObjCImplDecl: " << decl->getName().data() << endl;
            DiagnosticsEngine &D = ci.getDiagnostics();
            DiagnosticBuilder builder = D.Report(D.getCustomDiagID(DiagnosticsEngine::Warning, "---ObjCImplDecl: %0"));
            builder.AddString(decl->getName());
            return true;
        }
        bool VisitFunctionDecl(FunctionDecl *decl) {
            DiagnosticsEngine &D = ci.getDiagnostics();
            DiagnosticBuilder builder = D.Report(D.getCustomDiagID(DiagnosticsEngine::Warning, "---FunctionDecl: %0"));
            builder.AddString(decl->getName());
            return true;
        }
        
    };
    class TIMASTConsumer: public ASTConsumer {
    private:
        CompilerInstance &ci;
        TIMRecursiveASTVisitor visitor;
    public:
        TIMASTConsumer(CompilerInstance &ci): ci(ci), visitor(ci) {
            
        }
        bool HandleTopLevelDecl(DeclGroupRef D) {
            for(Decl *decl : D) {
                visitor.TraverseDecl(decl);
            }
            return true;
        }
        void HandleInlineFunctionDefinition(FunctionDecl *D) {
            visitor.TraverseFunctionDecl(D);
        }
    };
    class TIMASTPluginAction: public PluginASTAction {
        
        std::unique_ptr<ASTConsumer> CreateASTConsumer(CompilerInstance &CI,
                                                       StringRef InFile) override {
            return unique_ptr<TIMASTConsumer>(new TIMASTConsumer(CI));
        }
        
        /// Parse the given plugin command line arguments.
        ///
        /// \param CI - The compiler instance, for use in reporting diagnostics.
        /// \return True if the parsing succeeded; otherwise the plugin will be
        /// destroyed and no action run. The plugin is responsible for using the
        /// CompilerInstance's Diagnostic object to report errors.
        virtual bool ParseArgs(const CompilerInstance &CI,
                               const std::vector<std::string> &arg) override {
            return true;
        }
        
    };
}
static FrontendPluginRegistry::Add<TIM::TIMASTPluginAction> X("TIMASTPluginAction", "TIMASTPluginAction desc");

```

