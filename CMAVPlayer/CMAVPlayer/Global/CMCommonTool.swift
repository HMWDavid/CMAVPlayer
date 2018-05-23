//
//  CMCommonTool.swift
//  testSwiftAVPlayer
//
//  Created by 洪绵卫 on 2018/3/15.
//  Copyright © 2018年 洪绵卫. All rights reserved.
//

import Foundation

func CMLog(file: String = #file, line: Int = #line, function: String = #function,_ items: Any) {
    #if DEBUG
        print("\n----- 文件: \((file as NSString).lastPathComponent), 行数: \(line), 函数: \(function): => \(items)----------\n")
    #endif
}

