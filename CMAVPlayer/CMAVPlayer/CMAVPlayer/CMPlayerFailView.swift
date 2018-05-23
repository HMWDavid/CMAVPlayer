//
//  CMPlayerFailView.swift
//  RxLocaServer
//
//  Created by 洪绵卫 on 2018/5/10.
//  Copyright © 2018年 洪绵卫. All rights reserved.
//

import UIKit

@objc protocol CMPlayerFailViewDelegate {
    
  /// 重新设置播放资源
  ///
  /// - Returns: Void
  @objc optional func resetResouce()->Void
}

class CMPlayerFailView: UIImageView {
    
    lazy var failTitleLab:UILabel = {
        let temp = UILabel()
        temp.textAlignment = .center
        temp.text = "播放失败"
        temp.textColor = .white
        temp.font = UIFont.systemFont(ofSize: 14.0)
        self.addSubview(temp)
        return temp
    }()
    
    lazy var resetBtn:UIButton = {
       let temp = UIButton()
        temp.setTitle("重试", for: .normal)
        temp.setTitleColor(UIColor.lightGray, for: .normal)
        temp.addTarget(self, action: #selector(resetBtnClick), for: .touchUpInside)
        self.addSubview(temp)
       return temp
    }()
    
    //代理
    weak var delegate: CMPlayerFailViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 设置子视图
    func setSubViews() {
        self.failTitleLab.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(self)
            make.bottom.equalTo(self.snp.centerY)
        }
        
        self.resetBtn.snp.makeConstraints { (make) in
            make.bottom.left.right.equalTo(self)
            make.top.equalTo(self.snp.centerY)
        }
    }
    
    @objc func resetBtnClick(){
        self.delegate?.resetResouce?()
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
}
