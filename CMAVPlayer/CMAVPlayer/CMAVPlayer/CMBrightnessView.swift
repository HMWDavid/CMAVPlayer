//
//  CMBrightnessView.swift
//  testSwiftAVPlayer
//
//  Created by 洪绵卫 on 2018/5/4.
//  Copyright © 2018年 洪绵卫. All rights reserved.
//

import UIKit

let _SCREEN_W = UIScreen.main.bounds.size.width
let _SCREEN_H = UIScreen.main.bounds.size.height

class CMBrightnessView: UIView {
    
    var backImage:UIImageView?
    var title:UILabel?
    var brightnessLevelView:UIView?
    var tipArray:[UIImageView]?
    var timer:Timer?
    
    deinit {
        UIScreen.main.removeObserver(self, forKeyPath: "brightness")
        NotificationCenter.default.removeObserver(self)
    }
    static let share = CMBrightnessView.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = CGRect(x: _SCREEN_W * 0.5, y: _SCREEN_H * 0.5 - 20, width: 155, height: 155)
        self.layer.cornerRadius  = 10
        self.layer.masksToBounds = true
        
        //毛玻璃效果
        let toolbar:UIToolbar = UIToolbar.init(frame: self.bounds)
        
        self.addSubview(toolbar)
        
        self.setupView()
        
        self.createTips()
        
        self.addStatusBarNotification()
        
        self.addKVOObserver()
        
        self.alpha = 0.0
        
        UIApplication.shared.windows.first?.addSubview(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createTips()  {
        
        self.tipArray = [UIImageView]()
        
        let tipW:CGFloat  = (self.brightnessLevelView!.bounds.size.width - 17) / 16
        
        let tipH:CGFloat  = 5
        
        let tipY:CGFloat  = 1
        
        for i in 0...15 {
            
            let tipX:CGFloat = CGFloat(i) * ( tipW + 1) + 1
            
            let temp:UIImageView = UIImageView()
            
            temp.backgroundColor = UIColor.white
            
            temp.frame = CGRect(x: tipX, y: tipY, width: tipW, height: tipH)
            
            self.brightnessLevelView!.addSubview(temp)
            
            self.tipArray!.append(temp)
        }
        
        self.updateBrightnessLevel(UIScreen.main.brightness)
    }
    
    ///MARK: 更新亮度值
    /// 更新亮度值
    ///
    /// - Parameter brightnessLevel: 亮度值
    func updateBrightnessLevel(_ brightnessLevel:CGFloat)  {
        
        let stage:CGFloat  = 1 / 15.0
        
        let level:NSInteger  = NSInteger(brightnessLevel / stage)
        
        for item in self.tipArray! {
            
            let index = self.tipArray!.index(of: item)
            
            let isHidden = index! <= level
            
            item.isHidden = !isHidden
        }
    }
    
    //状态栏方向改变通知
    func addStatusBarNotification()  {
//        NotificationCenter.default.addObserver(self, selector: #selector(statusBarOrientationNotification), name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(statusBarOrientationNotification), name:NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    @objc func statusBarOrientationNotification() {
        self.setNeedsLayout()
    }
    
    func addKVOObserver() {
        UIScreen.main.addObserver(self, forKeyPath: "brightness", options: [.new,.old], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "brightness"{
            
            let  levelValue = change![NSKeyValueChangeKey.newKey] as! CGFloat
            self.appearBrightnessView()
            self.updateBrightnessLevel(levelValue)
        }
    }
    
    //添加定时器
    func addTime() {
        
        if self.timer != nil {
            return
        }
        
        self.timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(disAppearBrightnessView), userInfo: nil, repeats: false)
        
        RunLoop.main.add(self.timer!, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    //移除定时器
    func  removeTimer()  {
        if self.timer != nil {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    // Brightness 显示
    func appearBrightnessView(){
        
        UIView.animate(withDuration: 0.5, animations: {
            
            self.alpha = 1.0
            
        }) { (finished) in
            //添加定时器
            self.addTime()
        }
    }
    
    // Brightness 隐藏
    @objc func disAppearBrightnessView() {
        if self.alpha == 1.0 {
            UIView.animate(withDuration: 0.5, animations: {
                self.alpha = 0.0
            }) { (finished) in
                //移除定时器
                self.removeTimer()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let orientation:UIDeviceOrientation = UIDevice.current.orientation
        
        switch orientation {
        case .portraitUpsideDown,.portrait:
            self.center = CGPoint(x: _SCREEN_W * 0.5, y: (_SCREEN_H - 10) * 0.5)
            break
        case .landscapeLeft,.landscapeRight:
            self.center = CGPoint(x: _SCREEN_H * 0.5, y: (_SCREEN_W) * 0.5)

            break
        default: break
        }
        self.backImage?.center = CGPoint(x: 155 * 0.5, y: 155 * 0.5)
        self.superview?.bringSubview(toFront: self)
    }
    
    func setupView() {
        
        self.backImage = {
           
            let temp = UIImageView.init(frame: CGRect(x: 0, y: 0, width: 79, height: 76))
            
            temp.image = UIImage.init(named: "brightness")
            self.addSubview(temp)

            return temp
        }()
        
        self.title = {
           let temp = UILabel()
            temp.font = UIFont.systemFont(ofSize: 16.0)
            temp.frame = CGRect(x: 0, y: 5, width: self.bounds.size.width, height: 30)
            temp.textColor = UIColor(red: 0.25, green: 0.22, blue: 0.21, alpha: 1)
            temp.textAlignment = .center
            temp.text = "亮度"
            self.addSubview(temp)

           return temp
        }()
        
        self.brightnessLevelView = {
            let temp = UIView()
            temp.frame = CGRect(x: 13, y: 132, width: self.bounds.size.width - 26, height: 7)
            temp.backgroundColor = UIColor(red: 0.25, green: 0.22, blue: 0.21, alpha: 1)
            self.addSubview(temp)
            return temp
        }()
    }
}
