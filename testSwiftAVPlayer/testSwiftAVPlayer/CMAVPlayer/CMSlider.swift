//
//  CMSlider.swift
//  testSwiftAVPlayer
//
//  Created by 洪绵卫 on 2018/3/20.
//  Copyright © 2018年 洪绵卫. All rights reserved.
//

import UIKit

let SLIDER_X_BOUND = 30
let SLIDER_Y_BOUND = 40

class CMSlider: UISlider {
    
    var lastBounds:CGRect = CGRect(x:0,y:0,width:0,height:0)
    
    /// 控制slider的宽和高，这个方法才是真正的改变slider滑道的高的
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        super.trackRect(forBounds: bounds)
        return CGRect(x:bounds.origin.x, y:bounds.origin.y, width:bounds.size.width, height:4);
    }
    
    ///修改滑块位置
    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        var tempRrect:CGRect = rect
        tempRrect.origin.x =  tempRrect.origin.x - 6
        tempRrect.size.width = tempRrect.size.width + 12
        let result:CGRect  = super.thumbRect(forBounds: bounds, trackRect: tempRrect, value: value)
        self.lastBounds = result
        return result;
    }
    
    ///检查点击事件点击范围是否能够交给self处理
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        //调用父类方法,找到能够处理event的view
        var result = super.hitTest(point, with: event)
        
        /*如果这个view不是self,我们给slider扩充一下响应范围,
         这里的扩充范围数据就可以自己设置了
         */
        if result != self{
            if ((point.y >= -15) &&
                (point.y < (self.lastBounds.size.height + CGFloat(SLIDER_Y_BOUND))) &&
                (point.x >= 0 && point.x < self.bounds.size.width)) {
                //如果在扩充的范围类,就将event的处理权交给self
                result = self;
            }
        }
        //否则,返回能够处理的view
        return result
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        var result:Bool = super.point(inside: point, with: event)
        
        if !result {
            
            //同理,如果不在slider范围类,扩充响应范围
            if ((point.x >= (self.lastBounds.origin.x - CGFloat(SLIDER_X_BOUND))) && (point.x <= (self.lastBounds.origin.x + self.lastBounds.size.width + CGFloat(SLIDER_X_BOUND)))
                && (point.y >= -CGFloat(SLIDER_Y_BOUND)) && (point.y < (self.lastBounds.size.height + CGFloat(SLIDER_Y_BOUND)))) {
                
                //在扩充范围内,返回yes
                result = true;
            }
        }
        return result
    }
}





