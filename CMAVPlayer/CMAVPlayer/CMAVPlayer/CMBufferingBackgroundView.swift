//
//  CMBufferingView.swift
//  RxLocaServer
//
//  Created by 洪绵卫 on 2018/5/10.
//  Copyright © 2018年 洪绵卫. All rights reserved.
//

import UIKit

class CMBufferingBackgroundView: UIView {
    
    /// 背景图片
    lazy var backImageView:UIImageView = {
        
       let temp = UIImageView()
        temp.backgroundColor = UIColor.clear
        temp.contentMode = .scaleAspectFit
        temp.image = UIImage(named: "dl_bg_ptSSS@3x.png")
        self.addSubview(temp)
        return temp
    }()
    
    override func updateConstraints() {
        self.backImageView.snp.makeConstraints({ (make) in
            make.edges.equalTo(self)
        })
        super.updateConstraints()
    }
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
