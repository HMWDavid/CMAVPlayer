//
//  CMAVPlayerHeaderView.swift
//  testSwiftAVPlayer
//
//  Created by 洪绵卫 on 2018/3/16.
//  Copyright © 2018年 洪绵卫. All rights reserved.
//

import UIKit

@objc protocol CMAVPlayerHeaderViewDelegate {
    
    /// 切换为悬浮窗口模式按钮被点击
    ///
    /// - Parameter sender: 按钮
    @objc optional func changeModeToFloating(_ sender:UIButton)->Void

    
    /// 返回按钮被点击
    ///
    /// - Parameter sender: 按钮
    @objc optional func gobackBtnClick(_ sender:UIButton)->Void
}

class CMAVPlayerHeaderView: UIView {

    //返回按钮
    var goback:UIButton?

    //标题
    var titleLab:UILabel?
    
    /// 转换窗口模式
    var floatingModeBtn:UIButton?
    
    //代理
    weak var delegate: CMAVPlayerHeaderViewDelegate?

    
    /// 返回按钮事件
    ///
    /// - Parameter sender: 按钮
    @objc func gobackBtnClick(_ sender:UIButton) {
        self.delegate?.gobackBtnClick?(sender)
    }
    
    /// 切换为悬浮窗口模式
    ///
    /// - Parameter sender: 按钮
    @objc func changeToFloatingModeBtnClick(_ sender:UIButton){
        self.delegate?.changeModeToFloating?(sender)
    }
    
    override func updateConstraints() {
        self.setSubViewConstraint()
        
        super.updateConstraints()
    }
    
    /// 设置子视图
    private func setSubViewConstraint(){
        
        self.goback = {
            ()->UIButton in
            let tempBtn = UIButton.init(type: .custom)
            tempBtn.backgroundColor = UIColor.clear
            tempBtn.setImage(UIImage.init(named:"Player_back_full"), for: .normal)
            self.addSubview(tempBtn)
            tempBtn.addTarget(self, action: #selector(gobackBtnClick(_:)), for: UIControlEvents.touchUpInside)
            tempBtn.snp.makeConstraints({ (make) in
                make.left.equalTo(self)
                make.centerY.equalTo(self)
                make.size.equalTo(CGSize.init(width: 40, height: 40))
            })
            
            return tempBtn
        }()
        
        self.titleLab = {
            ()-> UILabel in
            let templab = UILabel.init()
            templab.textColor = UIColor.white
            templab.text = "海南省海口市美兰区国兴大道房多多买多房了哦~"
            templab.font = UIFont .systemFont(ofSize:15)
            templab.textAlignment = NSTextAlignment.left
            self.addSubview(templab)
            
            templab.snp.makeConstraints({ (make) in
                make.left.equalTo(self.goback!.snp.right)
                make.centerY.equalTo(self)
                make.height.equalTo(40)
                make.right.equalTo(self).offset(-100)
            })
            return templab
        }()
        
        self.floatingModeBtn = {
           ()->UIButton in
            let tempBtn = UIButton.init(type: .custom)
            tempBtn.backgroundColor = UIColor.clear
            tempBtn.setTitle("悬浮窗口", for: .normal)
            tempBtn.titleLabel?.font = UIFont .systemFont(ofSize:15)
            self.addSubview(tempBtn)
            tempBtn.addTarget(self, action: #selector(changeToFloatingModeBtnClick(_:)), for: UIControlEvents.touchUpInside)
            
            tempBtn.snp.makeConstraints({ (make) in
                make.right.equalTo(self)
                make.centerY.equalTo(self)
                make.size.equalTo(CGSize.init(width: 80, height: 40))
            })
            
            return tempBtn
        }()
    }
}




