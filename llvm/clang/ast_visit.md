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
    class TIMRecursiveASTVisitor: public RecursiveASTVisitor<TIMRecursiveASTVisitor> {
    private:
        CompilerInstance &ci;
    public:
        TIMRecursiveASTVisitor(CompilerInstance &ci): ci(ci) {
            
        }
        bool VisitorObjCImplementationDecl(ObjCImplementationDecl *decl) {
            DiagnosticsEngine &D = ci.getDiagnostics();
            DiagnosticBuilder builder = D.Report(D.getCustomDiagID(DiagnosticsEngine::Warning, "---ObjCImplementationDecl: %0"));
            builder.AddString(decl->getName());
            return true;
        }
        bool VisitObjCImplDecl(ObjCImplDecl *decl) {
            //            cout << "ObjCImplDecl: " << decl->getName().data() << endl;
            DiagnosticsEngine &D = ci.getDiagnostics();
            DiagnosticBuilder builder = D.Report(D.getCustomDiagID(DiagnosticsEngine::Warning, "---ObjCImplDecl: %0"));
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

