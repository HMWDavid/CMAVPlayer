//
//  CMCommonTool.swift
//  testSwiftAVPlayer
//
//  Created by 洪绵卫 on 2018/3/15.
//  Copyright © 2018年 洪绵卫. All rights reserved.
//

import Foundation
import UIKit

public func MIMAGE(_ imageName:String)->UIImage{
    
    return UIImage.init(named: imageName)!
}

public func FONT(_ int:CGFloat) ->UIFont {
    return UIFont .systemFont(ofSize: int)
}

func CMLog(file: String = #file, line: Int = #line, function: String = #function,_ items: Any) {
    
    #if DEBUG
        
        print("文件: \((file as NSString).lastPathComponent), 行数: \(line), 函数: \(function): => \(items) \n")
        
    #endif
    
}

