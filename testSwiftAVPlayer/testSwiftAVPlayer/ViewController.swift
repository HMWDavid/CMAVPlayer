//
//  ViewController.swift
//  testSwiftAVPlayer
//
//  Created by 洪绵卫 on 2018/3/14.
//  Copyright © 2018年 洪绵卫. All rights reserved.
//

import UIKit


class ViewController: UIViewController,CMAVPlayerDelegate {
    
    var player:CMAVPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
         self.view.translatesAutoresizingMaskIntoConstraints = false
        
        //本地视频地址
//        let path:String = Bundle.main.path(forResource: "1241_5bcc269bc8400733b98aa1f9b24b5925_20180416094812", ofType: "mp4")!
//        let URL:NSURL = NSURL.init(fileURLWithPath: path)
        
        //在线视频地址
        let URL:NSURL = NSURL(string: "http://www.ipaoapp.com/uploads/1241/videos/1241_5bcc269bc8400733b98aa1f9b24b5925_20180416094812.mp4")!
        
        self.player = CMAVPlayer(Url:URL,addToView:self.view)
        self.player.delegate = self as CMAVPlayerDelegate
        self.player.gestureActionBlock = { (gesture) in
            print("pangest :",gesture.type)
        }
    }
    
    /// 传入一个color返回一张图片
    ///
    /// - Parameter color: 颜色
    /// - Returns: 图片
    func imageWithColor(_ color:UIColor) -> UIImage {
        let rect = CGRect(x:0.0,y:0.0,width:20.0,height:20.0)
        UIGraphicsBeginImageContext(rect.size)
        let context:CGContext =  UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(rect)
        let img:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override var shouldAutorotate: Bool
    {
        return !self.player.isLocked
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

