//
//  CMAVPlayerFooterView.swift
//  testSwiftAVPlayer
//
//  Created by 洪绵卫 on 2018/3/15.
//  Copyright © 2018年 洪绵卫. All rights reserved.
//

import UIKit

@objc protocol CMAVPlayerFooterViewDelegate{
    /// 播放暂停代理回调
    ///
    /// - Parameter sender: UIButton
    func playOrPauseBtnDidClick(_ sender:UIButton)
    
    /// 全屏/小屏
    ///
    /// - Parameter sender: UIButton
    func fullScreenBtnDidClick(_ sender:UIButton)
}

class CMAVPlayerFooterView: UIView {
    
    /// 全屏/半屏
    var fullScreenBtn:UIButton?
    
    /// 播放/暂停
    var playOrPauseBtn:UIButton?
    
    /// 当前播放时间
    var currentTimeLab:UILabel?
    
    /// 总时长
    var totalTimeLab:UILabel?
    
    var sliderView:CMSliderView?
    
    //代理
    weak var delegate: CMAVPlayerFooterViewDelegate?
    
    override func updateConstraints() {
        self.setSubViewConstraint()
        super.updateConstraints()
    }
    
    /// 播放暂停按钮被点击
    ///
    /// - Parameter sender:UIButton
    @objc func playOrPauseBtnClick(_ sender:UIButton) {
        sender.isSelected = !sender.isSelected
        self.delegate?.playOrPauseBtnDidClick(sender)
    }
    
    @objc func fullScreenBtnClick(_ sender:UIButton){
        self.delegate?.fullScreenBtnDidClick(sender)
    }
    
    /// 设置子视图
    private func setSubViewConstraint(){
        ///全屏退出全屏按钮
        self.fullScreenBtn = {
            ()-> UIButton in
            let fullBtn = UIButton.init(type: .custom)
            fullBtn.backgroundColor = UIColor.clear
            fullBtn.setImage(MIMAGE("Player_fullscreen"), for: .normal)
            fullBtn.setImage(MIMAGE("Player_shrinkscreen"), for: .selected)
            self.addSubview(fullBtn)
            fullBtn.addTarget(self, action: #selector(fullScreenBtnClick(_:)), for: UIControlEvents.touchUpInside)

            fullBtn.snp.makeConstraints({ (make) in
                make.right.equalTo(self)
                make.centerY.equalTo(self)
                make.size.equalTo(CGSize.init(width: 40, height: 40))
            })
            return fullBtn
        }()
        
        self.totalTimeLab = {
            ()-> UILabel in
            let tempLabel = UILabel()
            tempLabel.backgroundColor = UIColor.clear
            tempLabel.font = FONT(12)
            tempLabel.textColor = UIColor.white
            tempLabel.text = "00:00:00"
            tempLabel.textAlignment = NSTextAlignment.center
            self.addSubview(tempLabel)
            
            tempLabel.snp.makeConstraints({ (make) in
                make.right.equalTo(self.fullScreenBtn!.snp.left)
                make.centerY.equalTo(self)
                make.size.equalTo(CGSize.init(width: 60, height: 40))
            })
            return tempLabel
        }()
        
        //播放/暂停
        self.playOrPauseBtn = {
            ()-> UIButton in
            let tempPlayBtn = UIButton()
            tempPlayBtn.backgroundColor = UIColor.clear
            tempPlayBtn.setImage(MIMAGE("Player_pause"), for: .normal)
            tempPlayBtn.setImage(MIMAGE("Player_play"), for: .selected)
            self.addSubview(tempPlayBtn)
            tempPlayBtn.addTarget(self, action: #selector(playOrPauseBtnClick(_:)), for: UIControlEvents.touchUpInside)

            tempPlayBtn.snp.makeConstraints({ (make) in
                make.left.equalTo(self)
                make.centerY.equalTo(self)
                make.size.equalTo(CGSize.init(width: 40, height: 40))
            })
            
            return tempPlayBtn
        }()
        
        //当前播放时间
        self.currentTimeLab = {
            ()-> UILabel in
            let tempLabel = UILabel()
            tempLabel.backgroundColor = UIColor.clear
            tempLabel.font = FONT(12)
            tempLabel.textColor = UIColor.white
            tempLabel.text = "00:00:00"
            tempLabel.textAlignment = NSTextAlignment.center
            self.addSubview(tempLabel)
            
            tempLabel.snp.makeConstraints({ (make) in
                make.left.equalTo(self.playOrPauseBtn!.snp.right)
                make.centerY.equalTo(self)
                make.size.equalTo(CGSize.init(width: 60, height: 40))
            })
            return tempLabel
        }()
        
        //滑杆
        self.sliderView = {
            ()-> CMSliderView in
            let temp = CMSliderView()
            temp.bufferTrackTintColor  = .darkGray
            temp.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.75)
            temp.minimumTrackTintColor = UIColor.green
            temp.setBackgroundImage(UIImage(named: "sliderBtnImage")!, state: .normal)
            self.addSubview(temp)
            
            temp.snp.makeConstraints({ (make) in
                make.left.equalTo(self.currentTimeLab!.snp.right).offset(10)
                make.right.equalTo(self.totalTimeLab!.snp.left).offset(-10)
                make.top.bottom.equalTo(self)
            })
            temp.value = 0.0
            return temp
        }()
    }
}







