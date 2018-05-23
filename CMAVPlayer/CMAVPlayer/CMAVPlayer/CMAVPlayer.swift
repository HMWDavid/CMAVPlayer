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
import MediaPlayer

/* 功能列表:
 0.锁定屏幕(完成)
 1.播放页(完成)
 2.暂停/开始(完成)
 3.手势(完成)
 4.快进/块退(完成)
 5.播放进度(滑块带菊花)(完成)
 6.全屏/转屏(完成)
 7.返回、标题(完成)
 8.当前播放时长、总时长(完成)
 9.缓冲加载中...(中心HUD 未完成,slider上HUD已完成)
 10.亮度调节(已完成)
 11.音量调节(已完成)
 */

//TODO: 注意悬浮模式只能从全屏模式进入,如果从默认的小窗口模式进入,会出现屏幕横向的情况出现
//TODO: 在小窗口模式下隐藏切换为悬浮模式窗口

let kheight     = 250.0///播放视图的高度 宽度为屏幕宽度
let kfloatingWH = 200.0///浮动窗口大小 正方形

typealias gesture = (_ drag:UIGestureRecognizer)->()


/// 悬浮窗口模式下被点击发出的通知
///
/// - NotificationName : 发出的通知名字
///
let CMAVPlayerNotification_floatingScreenTapGesture = "CMAVPlayerFloatingScreenTapGesture"

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

/// 播放器状态
///
/// - PlayerBuffering: 正在缓冲
/// - PlayerReadyToPlay: 准备播放
/// - PlayerPlaying: 正在播放状态
/// - PlayerPaused: 播放暂停状态
/// - PlayerComplete: 播放完成
/// - PlayerFaild: 播放失败
enum PlayerStatus {
    case PlayerBuffering
    case PlayerReadyToPlay
    case PlayerPlaying
    case PlayerPaused
    case PlayerComplete
    case PlayerFaild
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
    
    /// 将要从其他窗口模式进入默认模式
    ///
    /// - Parameter playerView: 播放视图View
    /// - Returns: void
    @objc optional func willEntranceDefultScreenMode(_ playerView:CMAVPlayer)->Void
    
    /// 将要从其他窗口模式进入出全屏模式
    ///
    /// - Parameter playerView: 播放视图View
    /// - Returns: void
    @objc optional func willEntranceFullScreenMode(_ playerView:CMAVPlayer)->Void
    
    /// 将要从其他窗口模式进入悬浮窗口模式
    ///
    /// - Parameter playerView: 播放视图View
    /// - Returns: void
    @objc optional func willEntranceFloatingScreenMode(_ playerView:CMAVPlayer)->Void
    
    /// 视频播放结束回调
    ///
    /// - Parameter view: 播放的视图
    /// - Returns: void
    @objc optional func didPlayEndTime(_ view:CMAVPlayer)->Void
}

//MARK: - CMAVPlayer 播放视图
class CMAVPlayer: UIView {
    
    deinit {
        CMLog("播放器已经释放")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    ///初始化
    public init(frame:CGRect,Url:NSURL) {
        self.Url = Url
        self.isPlayer = false
        self.isLocked = false
        super.init(frame: frame)
        self.backgroundColor = UIColor.black
        self.addGestureRecognizers()
        self.listening()
        self.isAllowDeviceOrientation(true)
        self.status = .PlayerBuffering
        //获取系统音量
        self.configureVolume()
        
        //屏幕亮度View
        self.configureBrightnessView()
        self.bufferingBackgroundView.isHidden = false
    }
    
    //MARK:------ 初始化函数
    public init(Url:NSURL) {
        self.Url = Url
        self.isPlayer = false
        self.isLocked = false
        super.init(frame:CGRect(x:0,y:0,width:0,height:0))
        self.backgroundColor = UIColor.black
        self.addGestureRecognizers()
        self.listening()
        self.isAllowDeviceOrientation(true)
        self.status = .PlayerBuffering

        //获取系统音量
        self.configureVolume()

        //屏幕亮度View
        self.configureBrightnessView()
        
        self.bufferingBackgroundView.isHidden = false
    }
    
    ///MARK:设置子视图坐标
    override func layoutSubviews() {
        super.layoutSubviews()
        self.playerLayer.frame = self.bounds
        self.bringSubview(toFront: self.footerView)
        self.bringSubview(toFront: self.headerView)
        self.bringSubview(toFront: self.centerPlayOrPauseBtn)
        self.bringSubview(toFront: self.speed)
        self.bringSubview(toFront: self.lockedBtn)
        self.bringSubview(toFront: self.bufferingBackgroundView)
        self.bringSubview(toFront: self.failView)
    }
    
    //约束
    override func updateConstraints() {
        super.updateConstraints()
    }
    
    //MARK: - 属性
    weak var delegate: CMAVPlayerDelegate?
    
    ///资源地址
    fileprivate var Url:NSURL!
    
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
            
            if newValue == .fullScreen {//全屏
                
                self.snp.remakeConstraints({ (make) in
                    make.edges.equalTo(self.superview!)
                })
                
            }else if newValue == .defultScreen{//默认
                
                self.snp.remakeConstraints { (make) in
                    make.left.equalTo(self.superview!)
                    make.right.equalTo(self.superview!)
                    make.top.equalTo(self.superview!)
                    make.height.equalTo(kheight)
                }
                
            }else if(newValue == .floatingScreen){//悬浮窗口
                
                self.lockedBtn.isSelected = false
                
                self.isLocked = self.lockedBtn.isSelected
                
                if UIDevice.current.orientation == .portrait{
                    //避免切换为全屏锁定后,转动屏幕,再转为HOME键在下,切换为小屏会不成功
                    UIDevice.current.setValue(NSNumber(value: Int8(UIDeviceOrientation.landscapeLeft.rawValue)), forKeyPath: "orientation")
                }
                
                UIDevice.current.setValue(NSNumber(value: Int8(UIDeviceOrientation.portrait.rawValue)), forKeyPath: "orientation")
                
                self.snp.remakeConstraints { (make) in
                    make.bottom.equalTo(self.superview!).offset(-20)
                    make.right.equalTo(self.superview!).offset(-20)
                    make.width.height.equalTo(kfloatingWH)
                }
                
                UIView.animate(withDuration: 0.5, animations: {
                    self.superview!.layoutIfNeeded()
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

    ///声音进度条
    private var volumeViewSlider : UISlider?
    
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
        locked.setImage(UIImage.init(named:"Player_lock-nor"), for: .selected)
        locked.setImage(UIImage.init(named:"Player_unlock-nor"), for: .normal)
        self.addSubview(locked)
        locked.addTarget(self, action: #selector(lockedBtnClick(_:)), for: UIControlEvents.touchUpInside)
        
        locked.snp.makeConstraints({ (make) in
            make.left.equalTo(self).offset(5.0)
            make.centerY.equalTo(self)
            make.size.equalTo(CGSize.init(width: 40, height: 40))
        })
        return locked
    }()
    
    ///手势方向,枚举
    private var panDirection : PanDirection?
    
    ///手势事件闭包回调属性
    var gestureActionBlock:gesture?
  
    ///播放的资源
    lazy var playerItem:AVPlayerItem = {
        ()-> AVPlayerItem in
        
        let tempVar = AVPlayerItem(url:self.Url as URL)
        //监听播放状态
        tempVar.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        
        //监听加载时间
        tempVar.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
        
        //监听播放的区域缓存是否为空
        tempVar.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
        
        //缓存可以播放的时候调用
        tempVar.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        return tempVar
    }()
    
    ///播放器
    lazy public var player:AVPlayer = {
        ()->AVPlayer in
        let tempVar = AVPlayer(playerItem: self.playerItem)
        //设置播放的默认音量值
        tempVar.volume = 1.0
        
        return tempVar
    }()
    
    //播放视图层
    lazy public var playerLayer:AVPlayerLayer = {()-> AVPlayerLayer in
        
        let tempVar = AVPlayerLayer.init(player: self.player)
        
        //自适应当前视图
        tempVar.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        //加入到播放视图
        self.layer.addSublayer(tempVar)
        
        return tempVar
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
        let tempF = CMAVPlayerFooterView.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        tempF.delegate = self
        tempF.backgroundColor = UIColor.black
        tempF.alpha = 0.35
        tempF.sliderView?.delegate = self
        self.addSubview(tempF)
        tempF.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(self)
            make.height.equalTo(40)
        }
        return tempF
    }()
    
    //悬浮窗口模式下才会出现在右上角的关闭按钮
    lazy var closeBtn: UIButton = {
        let temp = UIButton()
        temp.isHidden = true
        temp.addTarget(self, action: #selector(closeFloating), for: .touchUpInside)
        temp.setImage(UIImage(named: "Player_close"), for: .normal)
        self.addSubview(temp)
        temp.snp.makeConstraints({ (make) in
            make.top.right.equalTo(self)
            make.width.height.equalTo(35)
        })
        return temp
    }()
    
    /// 中间的播放/暂停按钮
    lazy var centerPlayOrPauseBtn:UIButton  = {
        ()->UIButton in
        let centerBtn = UIButton.init(type: .custom)
        centerBtn.backgroundColor = UIColor.clear
        centerBtn.setImage(UIImage.init(named:"Player_play_btn_small"), for: .normal)
        centerBtn.setImage(UIImage(named: "Player_repeat_video"), for: .selected)
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
        temp.font = UIFont .systemFont(ofSize:15)
        temp.textColor = UIColor.white
        temp.isHidden = true
        temp.textAlignment = NSTextAlignment.center
        temp.clipsToBounds = true
        temp.layer.cornerRadius = 10.0
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
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        tap.delegate = self
        tap.type = gestureRecognizerType.tapGesture
        
        //双指点击
        let doubleTap:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(gestureRecognizerAction(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        doubleTap.cancelsTouchesInView = false
        doubleTap.delaysTouchesBegan   = false
        doubleTap.delaysTouchesEnded   = false
        doubleTap.delegate = self
        doubleTap.type = gestureRecognizerType.doubleTapGesture
        tap.require(toFail: doubleTap)

        //拖拽手势
        let panGest:UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(gestureRecognizerAction(_:)))
        panGest.minimumNumberOfTouches = 1
        panGest.maximumNumberOfTouches = 1
        panGest.type = gestureRecognizerType.panGesture
        panGest.delegate = self
        
        self.addGestureRecognizer(tap)
        self.addGestureRecognizer(doubleTap)
        self.addGestureRecognizer(panGest)
    }
    //显示/隐藏(标题,播放进度等)
    var isHiddenOutlineView = false
    
    //手指是否在接触滑块
    var isSliderTouch = false
    
    /** *时间观察 */
    private var timeObserve : Any?
    
    /** *播放器状态 */
    var status : PlayerStatus?
    
    //资源播放失败显示的视图
    lazy var failView:CMPlayerFailView = {
        
        let temp = CMPlayerFailView.init(frame: self.bounds)
        
        temp.backgroundColor = .clear
        
        temp.isHidden = true
        
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            
            make.center.equalTo(self)
            
            make.width.height.equalTo(80)
        })
        
        return temp
    }()
    
    lazy var bufferingBackgroundView: CMBufferingBackgroundView = {
        let temp = CMBufferingBackgroundView()
        //temp.isHidden = true
        temp.backgroundColor = UIColor.black
        self.addSubview(temp)
        temp.snp.makeConstraints({ (make) in
            make.left.right.equalTo(self)
            make.top.equalTo(self).offset(40)
            make.bottom.equalTo(self).offset(-40)
        })
        return temp
    }()
}

// MARK: - 播放器 CMAVPlayer 功能实现
extension CMAVPlayer:UIGestureRecognizerDelegate,CMAVPlayerFooterViewDelegate,CMAVPlayerHeaderViewDelegate,CMSliderViewDelegate
{
    /// 开始播放资源
    func startPlayer() {
        if !self.isPlayer {
            self.centerPlayOrPauseBtn.isSelected = false
            self.centerPlayOrPauseBtn.isHidden = true
            //改为正在播放
            self.isPlayer = true
            //开始播放
            self.player.play()
            
            self.footerView.playOrPauseBtn?.isSelected = false
            self.status! = .PlayerPlaying
        }
    }
    
    ///暂停播放
    func suspendPlayer()  {
        if self.isPlayer {
            self.status! = .PlayerPaused
            self.centerPlayOrPauseBtn.isHidden = false
            self.centerPlayOrPauseBtn.isSelected = false
            self.isPlayer = false
            self.player.pause()
            self.footerView.playOrPauseBtn?.isSelected = true
        }
    }
    
    ///播放器关闭
     func closPlayer(){
        
        self.isAllowDeviceOrientation(false)
        NotificationCenter.default.removeObserver(self)

//        if (self.timeObserve != nil) {
//            self.player?.removeTimeObserver(self.timeObserve as Any)
//            self.timeObserve = nil
//        }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        self.removePlayerItemKVO()
        self.playerItem.cancelPendingSeeks()
        self.playerItem.asset.cancelLoading()
        
        if self.isPlayer {
            self.isPlayer = false
            self.player.pause()
        }
        self.player.replaceCurrentItem(with: nil)
        self.removeFromSuperview()
    }
    
    /*
     * 切换视频调用方法
     */
    open func exchangeWithURL(url:NSURL)  {
        
        //移除之前的KVO
        self.removePlayerItemKVO()
        
        self.Url = url
        
        self.playerItem = AVPlayerItem(url:self.Url as URL)

        //监听播放状态
        self.playerItem.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        
        //监听加载时间
        self.playerItem.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
        
        //监听播放的区域缓存是否为空
        self.playerItem.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
        
        //缓存可以播放的时候调用
        self.playerItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        
        self.player.replaceCurrentItem(with: self.playerItem)
        self.player.seek(to: kCMTimeZero)
    }
    
    /// 移除playerItem 上的KVO监听
    fileprivate func removePlayerItemKVO() {
        self.playerItem.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        self.playerItem.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        self.playerItem.removeObserver(self, forKeyPath: "status")
        self.playerItem.removeObserver(self, forKeyPath: "loadedTimeRanges")
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
        self.footerView.playOrPauseBtn?.isSelected = true
        self.centerPlayOrPauseBtn.isHidden = false
        self.centerPlayOrPauseBtn.isSelected = true
        self.player.seek(to: kCMTimeZero)
        self.delegate?.didPlayEndTime?(self)
        self.status = .PlayerComplete
    }
    
    //MARK:实时数据更新
    /// 实时数据更新
    func updataRealTimeData() {
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
    
    /// 中间的播放暂停按钮
    ///
    /// - Parameter sender: 按钮
    @objc func centerPlayOrPauseBtnClick(_ sender:UIButton){
         self.startPlayer()
    }
    
    /// 底部footerView上的 开始暂停按钮事件回调
    ///
    /// - Parameter sender: 按钮
    internal func playOrPauseBtnDidClick(_ sender: UIButton) {
        sender.isSelected ? self.suspendPlayer() : self.startPlayer()
    }
    
    /// 切换为悬浮窗口模式按钮被点击
    ///
    /// - Parameter sender: 点击的按钮
   internal func changeModeToFloating(_ sender: UIButton) {
        if self.isLocked {return}
        
        CMLog("切换为悬浮窗口模式按钮被点击")
        self.entranceFloatingScreenUIConfig()
    }
    
    
    /// 返回按钮被点击
    ///
    /// - Parameter sender: 返回按钮
    internal func gobackBtnClick(_ sender: UIButton) {
        CMLog("返回按钮被点击")
    }
    
    ///悬浮模式下的关闭按钮被点击
    @objc func closeFloating()  {
        CMLog("悬浮模式下的关闭按钮被点击")
        self.closPlayer()
    }
    
    /// (进入/退出)全屏按钮事件
    ///
    /// - Parameter sender: 按钮
    internal func fullScreenBtnDidClick(_ sender:UIButton) {
        
        self.playScreenType == .fullScreen ? self.entranceDefultScreen() : self.entranceFullScreen()
    }
    
    /// 进入全屏模式
    open func entranceFullScreen() {
        if self.isLocked {return}
        
        self.entranceFullScreenUIConfig()

        UIDevice.current.setValue(NSNumber(value: Int8(UIDeviceOrientation.landscapeLeft.rawValue)), forKeyPath: "orientation")
    }
    
    /// 退出全屏模式(进入默认模式 小窗口模式)
    func entranceDefultScreen(){
        if self.isLocked {return}
        
        self.entranceDefultScreenUIConfig()

//        if UIDevice.current.orientation == .portrait{
//            //避免切换为全屏锁定后,转动屏幕,再转为HOME键在下,切换为小屏会不成功
//            UIDevice.current.setValue(NSNumber(value: Int8(UIDeviceOrientation.landscapeLeft.rawValue)), forKeyPath: "orientation")
//        }
        
        UIDevice.current.setValue(NSNumber(value: Int8(UIDeviceOrientation.portrait.rawValue)), forKeyPath: "orientation")
    }
    
    /// 进入悬浮窗口模式UI配置
    func entranceFloatingScreenUIConfig() {
        self.playScreenType = .floatingScreen
        self.closeBtn.isHidden = false
        self.bringSubview(toFront: self.closeBtn)
        self.footerView.fullScreenBtn?.isSelected = false
        self.delegate?.willEntranceFloatingScreenMode?(self)
    }
    
    /// 切换为全屏模式UI配置
    func entranceFullScreenUIConfig() {
        self.playScreenType = .fullScreen
        self.closeBtn.isHidden = true
        self.footerView.fullScreenBtn?.isSelected = true
        self.delegate?.willEntranceFullScreenMode?(self)
    }

    /// 退出全屏模式UI配置(进入默认模式)
    func entranceDefultScreenUIConfig() {
        self.playScreenType = .defultScreen
        self.closeBtn.isHidden = true
        self.footerView.fullScreenBtn?.isSelected = false
        self.delegate?.willEntranceDefultScreenMode?(self)
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
        let orientation:UIDeviceOrientation = UIDevice.current.orientation
        switch orientation {
        case .landscapeLeft,.landscapeRight:
             self.entranceFullScreenUIConfig()
            break
        case .portrait:
             self.entranceDefultScreenUIConfig()
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
                
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: CMAVPlayerNotification_floatingScreenTapGesture), object: self, userInfo: nil)
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
            case .fullScreen://快进/块退/音量/亮度调节
                
                //根据拖动手势状态处理快进后退的值
                self.fullScreenModePanGestureStatus(gesture as! UIPanGestureRecognizer, veloctyPoint)
                
                break
            case .floatingScreen://更改浮动窗口位置(在浮动窗口模式下)
                
                let locationToSuperView = self.convert(locationPoint, to: superview)
                
                let dx:CGFloat  = locationToSuperView.x - self.center.x
                
                let dy:CGFloat = locationToSuperView.y - self.center.y
                
                //计算移动后的view中心点
                var newcenter:CGPoint  = CGPoint(x:(self.center.x + dx),y:(self.center.y + dy))
                
                /* 限制用户不可将视图托出屏幕 */
                let  halfx:CGFloat = self.bounds.midX
                
                //x坐标左边界
                newcenter.x = max(halfx, newcenter.x)
                
                //x坐标右边界
                newcenter.x = min(self.superview!.bounds.size.width - halfx, newcenter.x )
                
                //y坐标同理
                let halfy:CGFloat = self.bounds.minY
                
                newcenter.y = max(halfy, newcenter.y)
                
                newcenter.y = min(self.superview!.bounds.size.height - halfy, newcenter.y)
                
                //移动view
                //self.center = newcenter
                
                //更新约束
                self.snp.remakeConstraints { (make) in
                    make.center.equalTo(newcenter)
                    make.width.height.equalTo(kfloatingWH)
                }
                
                CMLog("父视图:\(self.superview!)")
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
                self.panDirection = PanDirection.HorizontalMoved

                self.speed.isHidden = false
                
                /// 给sumTime初值
                let time = self.player.currentTime()
                
                self.sumTime = CMTimeMake((time.value), (time.timescale))
            }else if x < y {
                
                self.panDirection = .VerticalMoved
                
                /// 开始滑动的时候,状态改为正在控制音量
                /// 大于屏幕的一半为调节音量,否则为调节亮度
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
                ///垂直移动方法只要y方向的值
                self.verticalMoved(value: veloctyPoint.y)
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
    
    /*
     * 手势:上下移动
     */
    private func verticalMoved(value:CGFloat){
        
        self.isVolume ? (self.volumeViewSlider?.value -= Float(value / 10000)) : (UIScreen.main.brightness -= value / 10000)
    }
    
    /// 设置亮度视图
    private func configureBrightnessView(){
       let brightness = CMBrightnessView.share
        CMLog(brightness)
    }
    
    /*
     * 获取系统音量
     */
    private func configureVolume(){
        let volumeView = MPVolumeView()
        self.volumeViewSlider = nil
        for view in volumeView.subviews {
            if NSStringFromClass(view.classForCoder) == "MPVolumeSlider" {
                volumeViewSlider = view as? UISlider
                break
            }
        }
        
        ///监听耳机插入和拔掉通知
       // NotificationCenter.default.addObserver(self, selector: #selector(audioRouteChangeListenerCallback(notification:)), name: NSNotification.Name.AVAudioSessionRouteChange, object: nil)
    }
    
    /// 耳机监听拔插事件
    @objc private func audioRouteChangeListenerCallback(notification:NSNotification){
        
        let interuptionDict = notification.userInfo! as NSDictionary
        let routeChangeReason = interuptionDict.value(forKey: AVAudioSessionRouteChangeReasonKey) as! AVAudioSessionRouteChangeReason
        switch routeChangeReason {
        case .newDeviceAvailable:
            // 耳机插入
            break
        case .oldDeviceUnavailable:
            // 耳机拔掉
            
            break
        default:
            break
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
        if !duration.isNaN {
            self.seekTime(dragedTime: CMTimeMake(Int64(Float64(value) * duration) , 1))
        }
    }
    
    /// 滑杆点击
    func sliderTapped(_ value:Float)->Void{
        CMLog("滑杆点击101112")
        let duration = CMTimeGetSeconds(playerItem.duration)
        if !duration.isNaN {
            self.seekTime(dragedTime: CMTimeMake(Int64(Float64(value) * duration) , 1))
        }
    }
    
    /*
     * 实时刷新数据
     */
    private func addTimeObserve(){
        self.timeObserve = self.player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1), queue: nil, using: { [weak self](time) in
            if #available(iOS 10.0, *) {
                if self?.player.timeControlStatus == .playing {
                    self?.status = PlayerStatus.PlayerPlaying
                    self?.bufferingBackgroundView.isHidden = true
                }else if self?.player.timeControlStatus == .paused {
                    self?.status = PlayerStatus.PlayerPaused
                    self?.bufferingBackgroundView.isHidden = true
                }else if self?.player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                    self?.status = PlayerStatus.PlayerBuffering
                    self?.bufferingBackgroundView.isHidden = false
                }
            }
            
            self?.updataRealTimeData()
        })
    }
    
    /// 通过KVO监控播放器状态
    ///
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if (keyPath == "status")&&((object as AnyObject).isKind(of: AVPlayerItem.self)) {
            
            let playerItem:AVPlayerItem  = object as! AVPlayerItem
            
            let status:NSNumber = change![NSKeyValueChangeKey.newKey]! as! NSNumber
            
            let sta:AVPlayerItemStatus = AVPlayerItemStatus(rawValue: status.intValue)!
            
            switch sta {
            case .readyToPlay://播放
                CMLog("视频正在播放已播放")
                self.status! = .PlayerReadyToPlay
                let durationTiem:Float64 = CMTimeGetSeconds(playerItem.duration)
                self.footerView.totalTimeLab?.text = self.formatPlayTime(secounds: durationTiem)
                self.startPlayer()
                self.addTimeObserve()
                
                break
            case .unknown://未知错误
                //TODO: 处理视频播放未知错误
                CMLog("视频播放未知错误")
                self.status! = .PlayerFaild
                self.failView.isHidden = false
                self.centerPlayOrPauseBtn.isHidden = true
                
                
                break
            case .failed://失败
                 //TODO: 视频播放失败处理
                CMLog("视频播放失败")
                self.status! = .PlayerFaild
                
                self.centerPlayOrPauseBtn.isHidden = true

                self.failView.isHidden = false
               
                break
            }
        }else if (keyPath == "loadedTimeRanges")&&((object as AnyObject).isKind(of: AVPlayerItem.self)){//加载中
            
            self.footerView.sliderView?.sliderBtn.showActivityAnim()
            
            let playerItem:AVPlayerItem  = object as! AVPlayerItem
            
            // 获取缓冲区域
            let timeRange = playerItem.loadedTimeRanges.first?.timeRangeValue
            
            let startSeconds = timeRange == nil ? 0.0 : CMTimeGetSeconds((timeRange?.start)!)
            
            let durationSeconds = timeRange == nil ? 0.0 : CMTimeGetSeconds((timeRange?.duration)!)
            
            // 计算缓冲总进度
            let cacheTotalSeconds = startSeconds + durationSeconds
            
            //缓冲总进度/视频总时长
            let buffer = Float.init(cacheTotalSeconds) / Float(CMTimeGetSeconds(playerItem.duration))
            
            //设置滑杆缓存进度
            self.footerView.sliderView?.bufferValue = buffer
            
            if buffer >= 1.0{
                self.footerView.sliderView?.sliderBtn.hideActivityAnim()
            }
            CMLog("缓冲总进度:\(buffer)")
            
        }else if((keyPath == "playbackBufferEmpty") && ((object as AnyObject).isKind(of: AVPlayerItem.self))){
            //监听播放的区域缓存是否为空
            //TODO: 待测试 应该显示菊花
            CMLog("缓冲不足显示菊花")
            if #available(iOS 10.0, *) {
            }else{
                self.bufferingBackgroundView.isHidden = false
            }
            
        }else if ((keyPath == "playbackLikelyToKeepUp") && ((object as AnyObject).isKind(of: AVPlayerItem.self))){
            //缓存可以播放的时候调用
            //TODO: 待测试
            if #available(iOS 10.0, *) {
            }else{
                self.bufferingBackgroundView.isHidden = true
            }
            self.startPlayer()
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







