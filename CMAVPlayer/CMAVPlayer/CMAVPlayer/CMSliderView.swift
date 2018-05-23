//
//  CMSliderView.swift
//  testSwiftAVPlayer
//
//  Created by 洪绵卫 on 2018/3/21.
//  Copyright © 2018年 洪绵卫. All rights reserved.
//

import UIKit

/** 滑块的大小 */
let kSliderBtnWH:CGFloat = 20.0

/** 间距 */
let kProgressMargin:CGFloat = 2.0

/* 所有进度的控件高度值 */
let KProgress:Float = 3.0

@objc protocol CMSliderViewDelegate {
    
    /// 滑块滑动开始
    @objc optional func sliderTouchBegan(_ value:Float)->Void
    
    /// 滑块滑动中
    @objc optional func sliderValueChanged(_ value:Float)->Void
    
    /// 滑块滑动结束
    @objc optional func sliderTouchEnded(_ value:Float)->Void
    
    /// 滑杆点击
    @objc optional func sliderTapped(_ value:Float)->Void
}

class CMSliderView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
       self.addGestureRecognizer(self.tapGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - 属性
    weak var delegate: CMSliderViewDelegate?
    
   /// 背景
    private lazy var bgProgressView: UIImageView = {
        ()-> UIImageView in
        let temp = UIImageView()
        temp.backgroundColor = UIColor.gray
        temp.contentMode = UIViewContentMode.scaleAspectFill
        temp.clipsToBounds = true
        temp.frame = CGRect(x:kProgressMargin, y:0, width:0, height: CGFloat(KProgress))
        self.addSubview(temp)
        CMLog("self.bgProgressView:\(temp)")
        return temp
    }()

    /// 缓存进度
    private lazy var bufferProgressView: UIImageView = {
        ()-> UIImageView in
        let temp = UIImageView()
        temp.backgroundColor = UIColor.white
        temp.contentMode = UIViewContentMode.scaleAspectFill
        temp.clipsToBounds = true
        temp.frame = self.bgProgressView.frame
        self.addSubview(temp)
        
        CMLog("self.bufferProgressView:\(temp)")
        return temp
    }()
    
    ///滑动进度
    private lazy var sliderProgressView: UIImageView = {
        ()-> UIImageView in
        let temp = UIImageView()
        temp.backgroundColor = UIColor.blue
        temp.contentMode = UIViewContentMode.scaleAspectFill
        temp.clipsToBounds = true
        temp.frame = self.bgProgressView.frame
        self.addSubview(temp)
        CMLog("self.sliderProgressView:\(temp)")

        return temp
    }()
    
    ///滑块
    lazy var sliderBtn: CMSliderButton = {
        ()-> CMSliderButton in
        let temp = CMSliderButton()
        temp.addTarget(self, action: #selector(sliderBtnTouchBegin(_:)), for: UIControlEvents.touchDown)
        temp.addTarget(self, action: #selector(sliderBtnTouchEnded(_:)), for: UIControlEvents.touchCancel)
        temp.addTarget(self, action: #selector(sliderBtnTouchEnded(_:)), for: UIControlEvents.touchUpInside)
        temp.addTarget(self, action: #selector(sliderBtnTouchEnded(_:)), for: UIControlEvents.touchUpOutside)
        temp.addTarget(self, action: #selector(sliderBtnDragMoving(_:event:)), for: UIControlEvents.touchDragInside)
        temp.frame = CGRect(x:0, y:0, width:kSliderBtnWH, height:kSliderBtnWH)
        self.addSubview(temp)
        return temp
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if (self.sliderBtn.isHidden) {
            self.bgProgressView.frame.size.width   = self.frame.size.width
        }else {
            self.bgProgressView.frame.size.width   = self.frame.size.width - kProgressMargin * 2
        }
        self.bgProgressView.frame.origin.x = kProgressMargin
        self.bgProgressView.center.y     = self.frame.size.height * 0.5
        self.bufferProgressView.center.y = self.frame.size.height * 0.5
        self.sliderProgressView.center.y = self.frame.size.height * 0.5
        self.sliderBtn.center.y = self.frame.size.height * 0.5
        
        
        self.bufferProgressView.frame.size.width = self.bgProgressView.frame.size.width * CGFloat(self.bufferValue.isNaN ? 0.0 : self.bufferValue)
        self.sliderProgressView.frame.size.width = self.bgProgressView.frame.size.width * CGFloat(self.value.isNaN ? 0.0 : self.value)
        self.sliderBtn.center.x = self.sliderProgressView.frame.size.width
    }
    
    ///滑杆的颜色 默认white
    public var maximumTrackTintColor:UIColor?{
        willSet{
            self.bgProgressView.backgroundColor = newValue
        }
    }
    
    ///滑杆进度颜色
    public var minimumTrackTintColor:UIColor?{
        willSet{
            self.sliderProgressView.backgroundColor = newValue
        }
    }
    
    ///缓存进度颜色
    public var bufferTrackTintColor:UIColor?{
        willSet{
            self.bufferProgressView.backgroundColor = newValue
        }
    }
    
    ///默认滑杆的图片
    public var maximumTrackImage:UIImage?{
        willSet{
            self.bgProgressView.image  = newValue
            self.maximumTrackTintColor = UIColor.clear
        }
    }
    
    ///滑杆进度的图片
    public var minimumTrackImage:UIImage?{
        willSet{
            self.sliderProgressView.image = newValue
            self.minimumTrackTintColor = UIColor.clear
        }
    }
    
    /// 缓存进度的图片
    public var bufferTrackImage:UIImage?{
        willSet{
            self.bufferProgressView.image = newValue
            self.bufferTrackTintColor = UIColor.clear
        }
    }
    
    /// 滑杆进度
    public var value:Float = 0.0{
        willSet{
            
            let multipliedValue = newValue >= 1.0 ? 1.0 : newValue <= 0.0 ? 0.0000001 : newValue
            if !multipliedValue.isNaN {
                self.sliderProgressView.frame.size.width = self.bgProgressView.frame.size.width * CGFloat(multipliedValue)
                
                self.sliderBtn.center.x = self.sliderProgressView.frame.size.width
            }
        }
    }
    
    /// 缓存进度
    public var bufferValue:Float = 0.0{
        willSet{
            let multipliedValue = newValue >= 1.0 ? 1.0 : newValue <= 0.0 ? 0.0 : newValue
            if !multipliedValue.isNaN {
                self.bufferProgressView.frame.size.width = self.bgProgressView.frame.width * CGFloat(multipliedValue.isNaN ? 0.0 : multipliedValue)
            }
        }
    }
    
    /// 设置滑块背景图片
    ///
    /// - Parameters:
    ///   - image: 图片
    ///   - state: 状态
    public func setBackgroundImage(_ image:UIImage,state:UIControlState) {
        self.sliderBtn.setBackgroundImage(image, for: state)
        
        self.sliderBtn.sizeToFit()
    }
    
    /// 设置滑块前景图片
    ///
    /// - Parameters:
    ///   - image: 图片
    ///   - state: 状态
    public func setThumbImage(_ image:UIImage,state:UIControlState){
        self.sliderBtn.setImage(image, for: state)
        
        self.sliderBtn.sizeToFit()
    }
    
    /// 显示菊花动画
    public func showLoading(){
        self.sliderBtn.showActivityAnim()
    }
    
    /// 隐藏菊花动画
    public func hideLoading(){
        self.sliderBtn.hideActivityAnim()
    }
    
    /// 滑杆的高度
    public var sliderHeight:Float = KProgress{
        willSet{
            self.bgProgressView.frame.size.height     = CGFloat(newValue)
            self.bufferProgressView.frame.size.height = CGFloat(newValue)
            self.sliderProgressView.frame.size.height = CGFloat(newValue)
        }
    }
    
    /// 是否允许点击，默认是true
    public var allowTapped:Bool = true{
        willSet{
            if !newValue {
                self.removeGestureRecognizer(self.tapGesture)
            }
        }
    }
    ///是否隐藏滑块（默认为false)
    public var isHideSlider:Bool = false{
        willSet{
            if newValue {
                self.sliderBtn.isHidden = true
                self.allowTapped = false
                self.bgProgressView.frame.origin.x = 0
                self.bufferProgressView.frame.origin.x = 0
                self.sliderProgressView.frame.origin.x = 0
            }
        }
    }
    
    /// 点击事件
    private lazy var tapGesture:UITapGestureRecognizer = {
        
        //单指点击手势
        let tap:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        return tap
    }()
    
     @objc func tapped (_ tap:UITapGestureRecognizer){
        let point = tap.location(in: self)
        
        var value = (point.x - (self.bgProgressView.frame.origin.x)) * 1.0/(self.bgProgressView.frame.size.width)
        
        value = value >= 1.0 ? 1.0 : value <= 0 ? 0 : value
        
        self.value = Float(value)
        
        self.delegate?.sliderTapped?(self.value)
    }
    
     @objc func sliderBtnTouchBegin(_ sender:CMSliderButton){
        self.delegate?.sliderTouchBegan?(self.value)
    }
    
     @objc func sliderBtnTouchEnded(_ sender:CMSliderButton){
        self.delegate?.sliderTouchEnded?(self.value)
    }
    
     @objc func sliderBtnDragMoving(_ sender:CMSliderButton,event:UIEvent){
        //取出touch事件
        guard let touch = event.allTouches?.first else {
            CMLog("Ops, no touch found...")
            return
        }
        let btn_W = sender.frame.size.width
        
        //取touch在视图上的位置
        let point = touch.location(in: self)
        
        // 获取进度值 由于btn是从 0-(self.width - btn.width)
        var value = (point.x - btn_W * 0.5) / (self.frame.size.width - btn_W)
        
        // value的值需在0-1之间
        value = value >= 1.0 ? 1.0 : value <= 0.0 ? 0.0:value
        
        self.value = Float(value)
        
        self.delegate?.sliderValueChanged?(self.value)
    }
}

class CMSliderButton: UIButton {
    
    var indicatorView:UIActivityIndicatorView?
    
    func showActivityAnim() {
        self.indicatorView?.isHidden = false
        self.indicatorView?.startAnimating()
    }
    
    func hideActivityAnim() {
        self.indicatorView?.isHidden = true
        self.indicatorView?.stopAnimating()
    }
    
    /// 重写此方法将按钮的点击范围扩大
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let bound:CGRect = self.bounds
        // 扩大点击区域
        bound.insetBy(dx: -20, dy: -20)
        
        // 若点击的点在新的bounds里面。就返回true
        return bound.contains(point)
    }
    
    func setSubViews(){
        self.indicatorView = {() -> UIActivityIndicatorView in
            let temp = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
            temp.hidesWhenStopped = false
            temp.isUserInteractionEnabled = false
            temp.transform = CGAffineTransform.init(scaleX: 0.6, y: 0.6)
            self.addSubview(temp)
            
            temp.snp.makeConstraints({ (make) in
                make.center.equalTo(self)
                make.width.equalTo(20)
                make.height.equalTo(20)
            })
            return temp
        }()
    }
    
    override func updateConstraints() {
        
        super.updateConstraints()
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        self.setSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



