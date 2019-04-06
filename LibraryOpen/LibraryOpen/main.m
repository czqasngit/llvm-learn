//
//  main.m
//  LibraryOpen
//
//  Created by legendry on 2019/4/6.
//  Copyright © 2019 legendry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import <dlfcn.h>

typedef void (*_printf_func)(const char *, ...);

int main(int argc, char * argv[]) {
    /// 动态库地址
    char *dylib_path = "/usr/lib/libSystem.dylib";
    /// 动态库操作句柄
    void *handle = dlopen(dylib_path, RTLD_GLOBAL | RTLD_NOW);
    if (handle) {
        /// 通过符号表找到对应的函数
        _printf_func _printf = dlsym(handle, "printf");
        /// 调用函数
        if (_printf) {
            _printf("你好,_printf \n");
        }
        dlclose(handle);
    } else {
        printf("未找到动态库: %s \n", dylib_path);
    }
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
