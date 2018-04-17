//
//  CMAVPlayer.swift
//  TEST_SwiftAVPlayer
//
//  Created by 洪绵卫 on 2018/3/13.
//  Copyright © 2018年 洪绵卫. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import SnapKit

/*
 0.锁定屏幕(完成)
 1.播放页(完成)
 2.暂停/开始(完成)
 3.手势(完成)
 4.快进/块退(完成)
 5.播放进度(滑块带缓冲)(完成)
 6.全屏/转屏(完成)
 7.返回、标题(完成)
 8.当前播放时长、总时长(完成)
 9.缓冲加载中...(中心HUD 未完成,slider上HUD已完成)
 10.亮度调节(未完成)
 11.音量调节(未完成)
 */

let kheight = 250.0///播放视图的高度
let kfloatingWH = 200.0///浮动窗口大小

typealias gesture = (_ drag:UIGestureRecognizer)->()

/// 手势类型
///
/// - panGesture: 拖拽
/// - tapGesture: 单击
/// - doubleTapGesture: 双击
enum gestureRecognizerType:UInt {
    case panGesture
    case tapGesture
    case doubleTapGesture
}

/// 滑动手势
///
/// - PanDirectionHorizontalMoved: 横向移动
/// - PanDirectionVerticalMoved: 纵向移动
enum PanDirection{
    case HorizontalMoved
    
    case VerticalMoved
}

/// 播放窗口模式(全屏/小屏/浮动窗口模式)
///
/// - smallScreen: 小屏模式
/// - FullScreen: 全屏模式
/// - floatingScreen: 浮动窗口模式
@objc enum playerScreen:UInt
{
    case defultScreen
    case fullScreen
    case floatingScreen
}

//MARK: - CMAVPlayerDelegate 代理
@objc protocol CMAVPlayerDelegate {
    
    /// 各手势事件回调
    ///
    /// - Parameter gesture: 当前触发的手势
    /// - Returns: void
    @objc optional func gestureAction(_ gesture:UIGestureRecognizer)->Void
    
    /// 播放窗口大小发生改变
    ///
    /// - Parameter to: 改变为什么类型(playerScreen 枚举)
    /// - Returns: void
    @objc optional func playerScreenChanges(to:playerScreen)->Void
    
    /// 将要退出全屏模式
    ///
    /// - Parameter playerView: 播放视图View
    /// - Returns: void
    @objc optional func willExitFullScreenMode(_ playerView:CMAVPlayer)->Void
    
    /// 将要进入出全屏模式进入小窗口模式
    ///
    /// - Parameter playerView: 播放视图View
    /// - Returns: void
    @objc optional func willEntranceFullScreenMode(_ playerView:CMAVPlayer)->Void
    
    /// 将要进入悬浮窗口模式
    ///
    /// - Parameter playerView: 播放视图View
    /// - Returns: void
    @objc optional func willEntranceFloatingScreenMode(_ playerView:CMAVPlayer)->Void
}

//MARK: - CMAVPlayer 播放视图
class CMAVPlayer: UIView {
    
    deinit {
        self.isAllowDeviceOrientation(false)
        self.playerItem.removeObserver(self, forKeyPath: "status")
        NotificationCenter.default.removeObserver(self)
        self.playerItem.removeObserver(self, forKeyPath: "loadedTimeRanges")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    ///父视图
    var superV:UIView
    
    ///初始化
    public init(frame:CGRect,Url:NSURL,addToView superV:UIView) {
        self.Url = Url;
        self.isPlayer = false
        self.isLocked = false;
        self.superV = superV

        super.init(frame: frame)
        self.addGestureRecognizers()
        self.listening()
        self.isAllowDeviceOrientation(true)
        self.superV.addSubview(self)
        self.snp.makeConstraints { (make) in
            make.left.equalTo(self.superV)
            make.right.equalTo(self.superV)
            make.top.equalTo(self.superV)
            make.height.equalTo(kheight)
        }
    }
    
    //MARK:------ 初始化函数
    public init(Url:NSURL,addToView superV:UIView) {
        self.Url = Url
        self.isPlayer = false
        self.isLocked = false
        self.superV = superV
        super.init(frame:CGRect(x:0,y:0,width:0,height:0))
        self.addGestureRecognizers()
        self.listening()
        self.isAllowDeviceOrientation(true)
        self.superV.addSubview(self)
        self.snp.makeConstraints { (make) in
            make.left.equalTo(self.superV)
            make.right.equalTo(self.superV)
            make.top.equalTo(self.superV)
            make.height.equalTo(kheight)
        }
    }
    
    ///MARK:设置子视图坐标
    override func layoutSubviews() {
        super.layoutSubviews()
        self.playerLayer.frame = self.bounds;
        self.bringSubview(toFront: self.footerView)
        self.bringSubview(toFront: self.headerView)
        self.bringSubview(toFront: self.centerPlayOrPauseBtn)
        self.bringSubview(toFront: self.speed)
        self.bringSubview(toFront: self.lockedBtn)
        
        //放在footerView的懒加载中没有设置到代理,初步设想是因为 sliderView是懒加载的,又是在updateConstraints中才加载导致的. 原因:sliderView还没有值,就已经设置代理了
        //目前暂时在这里做以下处理:
        if self.footerView.sliderView?.delegate == nil {
            self.footerView.sliderView?.delegate = self as CMSliderViewDelegate
        }
    }
    
    //约束
    override func updateConstraints() {
        super.updateConstraints()
    }
    
    //MARK: - 属性
    weak var delegate: CMAVPlayerDelegate?
    
    ///资源地址
    let Url:NSURL!
    
    ///播放窗口类型
    var playScreenType:playerScreen = .defultScreen{
        didSet{
            if oldValue == .floatingScreen {
                self.isHiddenHeaderView(false)
                self.isHiddenFooterView(false)
            }
        }
        
        willSet{
            //
            self.delegate?.playerScreenChanges?(to: newValue)
            
            if newValue == .fullScreen {
                self.snp.remakeConstraints({ (make) in
                    make.edges.equalTo(self.superV)
                })
            }else if newValue == .defultScreen{
                self.snp.remakeConstraints { (make) in
                    make.left.equalTo(self.superV)
                    make.right.equalTo(self.superV)
                    make.top.equalTo(self.superV)
                    make.height.equalTo(kheight)
                }
            }else{
                self.lockedBtn.isSelected = false
                self.isLocked = self.lockedBtn.isSelected
                //避免切换为全屏锁定后,转动屏幕,再转为HOME键在下,切换为小屏会不成功
//                UIDevice.current.setValue(NSNumber(value: Int8(UIDeviceOrientation.landscapeLeft.rawValue)), forKeyPath: "orientation")
                
                UIDevice.current.setValue(NSNumber(value: Int8(UIDeviceOrientation.portrait.rawValue)), forKeyPath: "orientation")
                
                self.snp.remakeConstraints { (make) in
                    make.bottom.equalTo(self.superV).offset(-20)
                    make.right.equalTo(self.superV).offset(-20)
                    make.width.height.equalTo(kfloatingWH)
                }
                
                UIView.animate(withDuration: 0.5, animations: {
                    self.superV.layoutIfNeeded()
                }, completion: { (finish) in
                    self.isHiddenHeaderView(true)
                    self.isHiddenFooterView(true)
                })
            }
        }
    }
    
    ///是否正在播放
    private var isPlayer:Bool!
    
    ///是否在调节音量
    private var isVolume : Bool = false
    
    ///是否锁定屏幕
    var isLocked:Bool{
        willSet{
            //关闭屏幕自动旋转
            self.isAllowDeviceOrientation(!newValue)
            
            //悬浮窗口模式下隐藏顶/底部视图
            if self.playScreenType != .floatingScreen {
                self.isHiddenFooterView(newValue)
                self.isHiddenHeaderView(newValue)
            }else{
                self.isHiddenFooterView(true)
                self.isHiddenHeaderView(true)
            }
        }
    }
    
    /// 是否锁定屏幕Btn
   lazy var lockedBtn:UIButton = {
      ()-> UIButton in
        let locked = UIButton.init(type: .custom)
        locked.backgroundColor = UIColor.clear
        locked.setImage(MIMAGE("Player_lock-nor"), for: .selected)
        locked.setImage(MIMAGE("Player_unlock-nor"), for: .normal)
        self.addSubview(locked)
        locked.addTarget(self, action: #selector(lockedBtnClick(_:)), for: UIControlEvents.touchUpInside)
        
        locked.snp.makeConstraints({ (make) in
            make.left.equalTo(self).offset(5.0)
            make.centerY.equalTo(self)
            make.size.equalTo(CGSize.init(width: 40, height: 40))
        })
        return locked
    }()
    
    /** *手势方向,枚举 */
    private var panDirection : PanDirection?
    
    ///手势事件闭包回调属性
    var gestureActionBlock:gesture?
        
    /// CGD定时器,用于更新当前播放时间
    var GCDTime:DispatchSourceTimer?

    ///播放的资源
    lazy var playerItem:AVPlayerItem = {
        ()-> AVPlayerItem in
        let tempVar = AVPlayerItem(url:self.Url as URL)
        tempVar.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        tempVar.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
        return tempVar;
    }()
    
    ///播放视图
    lazy var player:AVPlayer = {
        ()->AVPlayer in
        let tempVar = AVPlayer(playerItem: self.playerItem)
        //设置播放的默认音量值
        tempVar.volume = 1.0
        return tempVar
    }()
    
    lazy var playerLayer:AVPlayerLayer = {()-> AVPlayerLayer in
        let tempVar = AVPlayerLayer.init(player: self.player);
        //自适应当前视图
        tempVar.videoGravity = AVLayerVideoGravity.resizeAspectFill;
        //加入到播放视图
        self.layer.addSublayer(tempVar)
        return tempVar;
    }()
    
    /// 顶部视图
    lazy var headerView = {
        ()->CMAVPlayerHeaderView in
        let tempH = CMAVPlayerHeaderView()
        tempH.backgroundColor = UIColor.black
        tempH.alpha = 0.35
        tempH.delegate = self
        self.addSubview(tempH)
        tempH.snp.makeConstraints { (make) in
            make.left.right.top.equalTo(self)
            make.height.equalTo(40)
        }
        return tempH
    }()
    
    /// 底部视图
    lazy var footerView:CMAVPlayerFooterView = {
        ()->CMAVPlayerFooterView in
        let tempF = CMAVPlayerFooterView()
        tempF.delegate = self
        tempF.backgroundColor = UIColor.black
        tempF.alpha = 0.35
        self.addSubview(tempF)
        tempF.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(self)
            make.height.equalTo(40)
        }
        return tempF
    }()
    
    /// 中间的播放/暂停按钮
    lazy var centerPlayOrPauseBtn:UIButton  = {
        ()->UIButton in
        let centerBtn = UIButton.init(type: .custom)
        centerBtn.backgroundColor = UIColor.clear
        centerBtn.setImage(MIMAGE("Player_play_btn_small"), for: .normal)
        self.addSubview(centerBtn)
        centerBtn.addTarget(self, action: #selector(centerPlayOrPauseBtnClick(_:)), for: UIControlEvents.touchUpInside)
        
        centerBtn.snp.makeConstraints({ (make) in
            make.center.equalTo(self)
            make.size.equalTo(CGSize.init(width: 50, height: 50))
        })
        
        return centerBtn
    }()
    
    /** *用来保存快进的总时长 */
    private var sumTime : CMTime?
    
    /// 快进.块退
    lazy var speed:UILabel = {
        ()->UILabel in
        let temp = UILabel()
        temp.backgroundColor = UIColor.black
        temp.alpha = 0.5
        temp.font = FONT(15)
        temp.textColor = UIColor.white
        temp.isHidden = true
        temp.textAlignment = NSTextAlignment.center
        temp.clipsToBounds = true
        temp.layer.cornerRadius = 10.0;
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.center.equalTo(self)
            make.height.equalTo(40)
            make.width.equalTo(150)
        })
        return temp
    }()
    
    /**
     *  通知监听
     */
    private func listening()  {
        //监听屏幕旋转
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(onDeviceOrientationDidChange(_:)), name:NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        //监听播放结束
        NotificationCenter.default.addObserver(self, selector: #selector(didPlayEndTime), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    /// MARK: 手势集
    func addGestureRecognizers() {
        
        //单指点击手势
        let tap:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(gestureRecognizerAction(_:)))
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        tap.delegate = self
        tap.type = gestureRecognizerType.tapGesture;
        
        //双指点击
        let doubleTap:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(gestureRecognizerAction(_:)))
        doubleTap.numberOfTapsRequired = 2;
        doubleTap.numberOfTouchesRequired = 1;
        doubleTap.cancelsTouchesInView = false;
        doubleTap.delaysTouchesBegan   = false;
        doubleTap.delaysTouchesEnded   = false;
        doubleTap.delegate = self
        doubleTap.type = gestureRecognizerType.doubleTapGesture;
        tap.require(toFail: doubleTap)

        //拖拽手势
        let panGest:UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(gestureRecognizerAction(_:)))
        panGest.minimumNumberOfTouches = 1
        panGest.maximumNumberOfTouches = 1
        panGest.type = gestureRecognizerType.panGesture;
        panGest.delegate = self
        
        self.addGestureRecognizer(tap)
        self.addGestureRecognizer(doubleTap)
        self.addGestureRecognizer(panGest)
    }
    //显示/隐藏(标题,播放进度等)
    var isHiddenOutlineView = false
    
    //手指是否在接触滑块
    var isSliderTouch = false
}

// MARK: - 播放器 CMAVPlayer 功能实现
extension CMAVPlayer:UIGestureRecognizerDelegate,CMAVPlayerFooterViewDelegate,CMAVPlayerHeaderViewDelegate,CMSliderViewDelegate
{
    /// 开始播放资源
    func startPlayer() {
        if !self.isPlayer {
            self.centerPlayOrPauseBtn.isHidden = true
            //改为正在播放
            self.isPlayer = true
            //开始播放
            self.player.play()
            
            self.footerView.playOrPauseBtn?.isSelected = false
            
            //定时器
            if self.GCDTime == nil{
                self.GCDTime = self.DispatchTimer(0.1)
            }else{
                self.GCDTime?.resume()
            }
        }
    }
    
    ///暂停播放
    func suspendPlayer()  {
        if self.isPlayer {
            self.centerPlayOrPauseBtn.isHidden = false
            self.isPlayer = false
            self.player.pause()
            self.footerView.playOrPauseBtn?.isSelected = true
            self.GCDTime?.suspend()
        }
    }
    
    /// 是否锁定屏幕
    ///
    /// - Parameter sender: 按钮
    @objc func lockedBtnClick(_ sender:UIButton){
        sender.isSelected = !sender.isSelected
        self.isLocked = sender.isSelected
    }
    
    /// 已经播放结束
    @objc func didPlayEndTime(){
        self.isPlayer = false
        self.GCDTime?.suspend()
        self.footerView.playOrPauseBtn?.isSelected = true
        self.centerPlayOrPauseBtn.isHidden = false
        self.player.seek(to: kCMTimeZero)

    }
    
    /// GCD定时器循环操作
    ///   - timeInterval: 循环间隔时间
    public func DispatchTimer(_ timeInterval: Double)->(DispatchSourceTimer)
    {
        let time:DispatchSourceTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        time.schedule(deadline: .now(), repeating: timeInterval)
        time.setEventHandler {
            DispatchQueue.main.async {
                //定时器循环事件
                let currentTiem:Float64 = CMTimeGetSeconds(self.player.currentItem!.currentTime())
                
                self.footerView.currentTimeLab?.text = self.formatPlayTime(secounds: currentTiem)
                
                if !self.isSliderTouch{
                    /// 总时间
                    let totalTime = self.playerItem.duration
                    
                    let totalMovieDuration = CMTimeMake((totalTime.value), (totalTime.timescale))
                    
                    //滑杆的值
                    let sliderTime = currentTiem/CMTimeGetSeconds(totalMovieDuration)
                    
                    //设置滑杆
                    self.footerView.sliderView?.value = Float.init(sliderTime)
                }
            }
        }
        time.resume()
        return time
    }
    
    @objc func centerPlayOrPauseBtnClick(_ sender:UIButton){
         self.startPlayer()
    }
    
    /// 底部footerView上的 开始暂停按钮事件回调
    ///
    /// - Parameter sender: 按钮
    func playOrPauseBtnDidClick(_ sender: UIButton) {
        sender.isSelected ? self.suspendPlayer() : self.startPlayer()
    }
    
    /// 切换为悬浮窗口模式按钮被点击
    ///
    /// - Parameter sender: 点击的按钮
    func changeModeToFloating(_ sender: UIButton) {
        if self.isLocked {return}
        self.entranceFloatingScreenUIConfig()
    }
    
    /// (进入/退出)全屏按钮事件
    ///
    /// - Parameter sender: 按钮
    func fullScreenBtnDidClick(_ sender:UIButton) {
        self.playScreenType == .fullScreen ? self.exitFullScreen() : self.entranceFullScreen()
    }
    
    /// 进入全屏模式
    func entranceFullScreen() {
        if self.isLocked {return}
        
        self.entranceFullScreenUIConfig()

        UIDevice.current.setValue(NSNumber(value: Int8(UIDeviceOrientation.landscapeLeft.rawValue)), forKeyPath: "orientation")
    }
    
    /// 退出全屏模式
    func exitFullScreen(){
        if self.isLocked {return}
        
        self.exitFullScreenUIConfig()

        //避免切换为全屏锁定后,转动屏幕,再转为HOME键在下,切换为小屏会不成功
        UIDevice.current.setValue(NSNumber(value: Int8(UIDeviceOrientation.landscapeLeft.rawValue)), forKeyPath: "orientation")
        
        UIDevice.current.setValue(NSNumber(value: Int8(UIDeviceOrientation.portrait.rawValue)), forKeyPath: "orientation")
    }
    
    /// 进入悬浮窗口模式
    func entranceFloatingScreenUIConfig() {
        self.playScreenType = .floatingScreen
        self.footerView.fullScreenBtn?.isSelected = false
        self.delegate?.willEntranceFloatingScreenMode?(self)
    }
    
    /// 切换为全屏模式UI配置
    func entranceFullScreenUIConfig() {
        self.playScreenType = .fullScreen
        self.footerView.fullScreenBtn?.isSelected = true
        self.delegate?.willEntranceFullScreenMode?(self)
    }
    
    /// 退出全屏模式UI配置
    func exitFullScreenUIConfig() {
        self.playScreenType = .defultScreen
        self.footerView.fullScreenBtn?.isSelected = false
        self.delegate?.willExitFullScreenMode?(self)
    }
    
    /// 是否开启屏幕自动跟随旋转
    ///
    /// - Parameter isAllow: true 开启  false 关闭
    func isAllowDeviceOrientation(_ isAllow:Bool) {
        let appde = UIApplication.shared.delegate as! AppDelegate
        appde.allowRotation = isAllow
    }
    
    /// (通知)屏幕已经旋转
    ///
    /// - Parameter notification: 通知
    @objc private func onDeviceOrientationDidChange(_ notification:Notification)  {
        if isLocked {
            return
        }
        CMLog("------ 设置其他方向时候布局 ------")
        let orientation:UIDeviceOrientation = UIDevice.current.orientation
        switch orientation {
        case .landscapeLeft,.landscapeRight:
             self.entranceFullScreenUIConfig()
            break
        case .portrait:
             self.exitFullScreenUIConfig()
            break
        default:
            break
        }
    }
    
    /// 避免子视图的事件发生时候会触发父视图的事件
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view!.isKind(of: CMAVPlayer.self)) {
            return true
        }
        return false
    }
    
    /// 手势事件
    ///
    /// - Parameter gesture: 手势
    @objc func gestureRecognizerAction(_ gesture:UIGestureRecognizer){
        if self.isLocked {
            return
        }
        
        /// 获取手指点在屏幕上的位置
        let locationPoint = gesture.location(in: self)
        
        self.gestureActionBlock?(gesture)
        
        self.delegate?.gestureAction?(gesture)
        
        switch gesture.type {
        case .tapGesture://显示/隐藏(标题,播放进度等)
            if self.playScreenType != .floatingScreen{
                self.isHiddenOutlineView = !self.isHiddenOutlineView
                
                self.isHiddenHeaderView(self.isHiddenOutlineView)
                
                self.isHiddenFooterView(self.isHiddenOutlineView)
            }else{
                //进入全屏
                self.entranceFullScreen()
            }
            
            break
        case .doubleTapGesture://实现播放/暂停
            
            self.isPlayer ? self.suspendPlayer() : self.startPlayer()
            break
        case .panGesture:
            
            ///根据上次和本次移动的位置，算出一个速率的point
            let veloctyPoint = (gesture as! UIPanGestureRecognizer).velocity(in: self)

            switch self.playScreenType{
            case .defultScreen://小窗口模式下无任何操作
                break
            case .fullScreen://快进/块退/音量调节
                
                //根据拖动手势状态处理快进后退的值
                self.fullScreenModePanGestureStatus(gesture as! UIPanGestureRecognizer, veloctyPoint)
                break
            case .floatingScreen://更改浮动窗口位置(在浮动窗口模式下)
                
                let locationToSuperView = self.convert(locationPoint, to: superview)
                
                CMLog("父视图上\(locationToSuperView)")
                
                let dx:CGFloat  = locationToSuperView.x - self.center.x;
                let dy:CGFloat = locationToSuperView.y - self.center.y;
                
                //计算移动后的view中心点
                var newcenter:CGPoint  = CGPoint(x:(self.center.x + dx),y:(self.center.y + dy))
                
                /* 限制用户不可将视图托出屏幕 */
                let  halfx:CGFloat = self.bounds.midX
                //x坐标左边界
                newcenter.x = max(halfx, newcenter.x)
                //x坐标右边界
                newcenter.x = min(self.superV.bounds.size.width - halfx, newcenter.x )
                
                //y坐标同理
                let halfy:CGFloat = self.bounds.minY
                newcenter.y = max(halfy, newcenter.y)
                newcenter.y = min(self.superV.bounds.size.height - halfy, newcenter.y);

                //移动view
                self.center = newcenter;
                
                break
            }
            break
        }
    }
    
    /// 根据拖动手势状态处理快进后退的值
    ///
    /// - Parameters:
    ///   - gesture: 拖动手势
    ///   - veloctyPoint: 根据上次和本次移动的位置，算出一个速率的point
    func fullScreenModePanGestureStatus(_ gesture:UIPanGestureRecognizer,_ veloctyPoint:CGPoint)  {
        /// 使用绝对值来判断移动的方向
        let x = fabs(veloctyPoint.x)
        
        let y = fabs(veloctyPoint.y)
        
        switch gesture.state {
        case .began:
            if x > y {
                self.speed.isHidden = false
                
                self.panDirection = PanDirection.HorizontalMoved
                
                /// 给sumTime初值
                let time = self.player.currentTime()
                
                self.sumTime = CMTimeMake((time.value), (time.timescale))
                
                ///暂停定时器
                self.GCDTime?.suspend()
            }else if x < y {
                
                self.panDirection = .VerticalMoved
                
                /// 开始滑动的时候,状态改为正在控制音量
                if gesture.location(in: self).x > self.bounds.size.width/2.0 {
                    self.isVolume = true
                }else{
                    self.isVolume = false
                }
            }
            break
        case.changed:
            switch self.panDirection! {
            case .HorizontalMoved:
                
                /// 移动中一直显示快进label
                self.speed.isHidden = false
                
                /// 水平移动的方法只要x方向的值
                self.fastforwardAndFastReverse(value: veloctyPoint.x)
                break
            case .VerticalMoved:
                CMLog("设置声音大小")
                ///垂直移动方法只要y方向的值
                //self.verticalMoved(value: veloctyPoint.y)
                break
            }
            break
        case.ended:
            switch self.panDirection! {
            case .HorizontalMoved:
                
                self.speed.isHidden = true
                
                ///快进、快退时候把开始播放按钮改为播放状态
                self.seekTime(dragedTime: self.sumTime!)
                
                self.sumTime = CMTime.init(seconds: 0.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                
                ///暂停定时器
                self.GCDTime?.resume()
                
                break
            case.VerticalMoved:
                self.isVolume = false
                self.speed.isHidden = true
                break
            }
            break
        default:
            break
        }
    }
    
    /// 快进/快退
    func fastforwardAndFastReverse(value:CGFloat) {
        
        var style = String()
        if value < 0 {
            style = "<<"
        }
        if value > 0 {
            style = ">>"
        }
        if value == 0 {
            return
        }
        /// 将平移距离转成CMTime格式
        let addend = CMTime.init(seconds: Double.init(value/200), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        self.sumTime = CMTimeAdd(self.sumTime!, addend)
        /// 总时间
        let totalTime = self.playerItem.duration
        
        let totalMovieDuration = CMTimeMake((totalTime.value), (totalTime.timescale))
        
        if self.sumTime! > totalMovieDuration {
            self.sumTime = totalMovieDuration
        }
        ///最小时间0
        let small = CMTime.init(seconds: 0.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        if self.sumTime! < small {
            self.sumTime = small
        }
        
        let nowTime = self.formatPlayTime(secounds: CMTimeGetSeconds(self.sumTime!))
        
        let durationTime = self.formatPlayTime(secounds: CMTimeGetSeconds(totalMovieDuration))
        
        //设置快进/快退lab显示文字
        self.speed.text = String.init(format: "%@ %@ / %@",style, nowTime, durationTime)
        
        //滑杆的值
        let sliderTime = CMTimeGetSeconds(self.sumTime!)/CMTimeGetSeconds(totalMovieDuration)
        
        //设置滑杆
        self.footerView.sliderView?.value = Float.init(sliderTime)
        
        //设置当前播放时间
        self.footerView.currentTimeLab?.text = nowTime
    }
    
    /*
     * 从XXX秒开始播放视频
     */
    private func seekTime(dragedTime:CMTime){
        
        if self.player.currentItem?.status == .readyToPlay {
            self.player.seek(to: dragedTime, completionHandler: { (finished) in
                self.startPlayer()
            })
        }
    }
    
    /// 是否隐藏顶部视图
    ///
    /// - Parameter isHidden: true 隐藏  false 不隐藏
    func isHiddenHeaderView(_ isHidden:Bool) {
        
        self.headerView.snp.updateConstraints { (make) in
            make.height.equalTo((isHidden) ? (0) :(40))
        }
        
        UIView.animate(withDuration: 0.5) {
            self.headerView.alpha = isHidden ? 0 : 0.35
            self.layoutIfNeeded()
        }
    }
    
    /// 是否隐藏底部视图
    ///
    /// - Parameter isHidden: true 隐藏  false 不隐藏
    func isHiddenFooterView(_ isHidden:Bool) {
        self.footerView.snp.updateConstraints { (make) in
            make.height.equalTo((isHidden) ? (0) :(40))
        }
        
        UIView.animate(withDuration: 0.5) {
            self.footerView.alpha = isHidden ? 0 : 0.35
            self.layoutIfNeeded()
        }
    }
    
    /// 转换当前播放视频时间显示格式
    ///
    /// - Parameter secounds: 秒数
    /// - Returns: (格式:[00:00:00]或者[00:00])
    func formatPlayTime(secounds:TimeInterval)->String{
        if secounds.isNaN{
            return "00:00"
        }
        var Min  = Int(secounds / 60)
        let Sec  = Int(secounds.truncatingRemainder(dividingBy: 60))
        var Hour = 0
        if Min >= 60 {
            Hour = Int(Min / 60)
            Min = Min - Hour*60
            return String(format: "%02d:%02d:%02d", Hour, Min, Sec)
        }
        return String(format: "%02d:%02d", Min, Sec)
    }
    
    /// 滑块滑动开始
    func sliderTouchBegan(_ value:Float)->Void{
        CMLog("滑块滑动开始123")
        self.isSliderTouch = true
    }
    
    /// 滑块滑动中
    func sliderValueChanged(_ value:Float)->Void{
        CMLog("滑块滑动中456")
    }
    
    /// 滑块滑动结束
    func sliderTouchEnded(_ value:Float)->Void{
        CMLog("滑块滑动结束789")
        self.isSliderTouch = false
        let duration = CMTimeGetSeconds(playerItem.duration)
        self.seekTime(dragedTime: CMTimeMake(Int64(Float64(value) * duration) , 1))
    }
    
    /// 滑杆点击
    func sliderTapped(_ value:Float)->Void{
        CMLog("滑杆点击101112")
        let duration = CMTimeGetSeconds(playerItem.duration)
        self.seekTime(dragedTime: CMTimeMake(Int64(Float64(value) * duration) , 1))
    }
    
    /// 通过KVO监控播放器状态
    ///
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if (keyPath == "status")&&((object as AnyObject).isKind(of: AVPlayerItem.self)) {
            
            let playerItem:AVPlayerItem  = object as! AVPlayerItem
            
            let status:NSNumber = change![NSKeyValueChangeKey.newKey]! as! NSNumber
            
            let sta:AVPlayerItemStatus = AVPlayerItemStatus(rawValue: status.intValue)!;
            
            switch sta {
            case .readyToPlay://播放
                CMLog("视频正在播放已播放")
                let durationTiem:Float64 = CMTimeGetSeconds(playerItem.duration)
                self.footerView.totalTimeLab?.text = self.formatPlayTime(secounds: durationTiem)
                break
            case .unknown://未知错误
                CMLog("视频播放未知错误")
                break
            case .failed://失败
                CMLog("视频播放失败")
                break
            }
        }else if (keyPath == "loadedTimeRanges")&&((object as AnyObject).isKind(of: AVPlayerItem.self)){//加载中
            
            self.footerView.sliderView?.sliderBtn.showActivityAnim()
            let playerItem:AVPlayerItem  = object as! AVPlayerItem
            
            let timeRange = playerItem.loadedTimeRanges.first?.timeRangeValue
            
            let startSeconds = CMTimeGetSeconds((timeRange?.start)!)
            
            let durationSeconds = CMTimeGetSeconds((timeRange?.duration)!)
            
            let cacheTotalSeconds = startSeconds + durationSeconds;
            
            let buffer = Float.init(cacheTotalSeconds) / Float(CMTimeGetSeconds(playerItem.duration))
            
            //设置滑杆缓存进度
            self.footerView.sliderView?.bufferValue = buffer
            
            if buffer >= 1.0{
                self.footerView.sliderView?.sliderBtn.hideActivityAnim()

            }
        }
    }
}

//MARK: 为系统的UIGestureRecognizer扩展一个type属性
private var CMGestureKey: String = "CMGestureRecognizerType"
extension UIGestureRecognizer
{
    //利用RunTime特性,为扩展添加属性
    var type:gestureRecognizerType{
        get {
            return (objc_getAssociatedObject(self, &CMGestureKey) as? gestureRecognizerType)!
        }
        set(newValue) {
            objc_setAssociatedObject(self, &CMGestureKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}







