//
//  CMHomeNextViewController.swift
//  RxLocaServer
//
//  Created by 洪绵卫 on 2018/5/8.
//  Copyright © 2018年 洪绵卫. All rights reserved.
//

import UIKit

class CMHomeNextViewController: CMBaseViewController,CMAVPlayerDelegate {

    var player:CMAVPlayer?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        self.player?.closPlayer()
        CMLog("已经释放了")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.orange
        
        let btn = UIButton()
        btn.setTitle("popVC", for: .normal)
        btn.backgroundColor = .orange
        btn.addTarget(self, action: #selector(btnClick), for: .touchUpInside)
        self.view.addSubview(btn)
        btn.snp.makeConstraints { (make) in
            make.width.height.equalTo(80)
            make.center.equalTo(self.view)
        }
        
        if self.player == nil{
            AVPlayer()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(floatingScreenTapGesture), name: NSNotification.Name(rawValue: CMAVPlayerNotification_floatingScreenTapGesture), object: nil)
    }
    
    @objc func btnClick() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func floatingScreenTapGesture(_ notification:NSNotification){
        let player = notification.object as! CMAVPlayer

        self.player = player

        self.view.addSubview(player)
        
        player.entranceDefultScreen()
    }
    
    
    
    func AVPlayer() {
        
        //本地视频地址
        let path:String = Bundle.main.path(forResource: "1241_5bcc269bc8400733b98aa1f9b24b5925_20180416094812", ofType: "mp4")!

        let URL:NSURL = NSURL.init(fileURLWithPath: path)
        
        //在线视频地址
       //let URL:NSURL = NSURL(string: "http://www.ipaoapp.com/uploads/1241/videos/1241_5bcc269bc8400733b98aa1f9b24b5925_20180416094812.mp4")!
        
        //let URL:NSURL = NSURL(string: "http://live.hkstv.hk.lxdns.com/live/hks/playlist.m3u8")!
        
        self.player = CMAVPlayer(Url:URL)
        
        self.player?.delegate = self as CMAVPlayerDelegate
        
        self.player?.gestureActionBlock = { (gesture) in
            print("pangest :",gesture.type)
        }
        
        self.view.addSubview(self.player!)
        
        //初始约束
        self.player?.snp.makeConstraints { (make) in
            make.left.right.top.equalTo(self.view)
            make.height.equalTo(kheight)
        }
    }
    
    func willEntranceFloatingScreenMode(_ playerView: CMAVPlayer) {
        self.navigationController?.view.addSubview(self.player!)
        self.player = nil
    }
    
    func willEntranceFullScreenMode(_ playerView: CMAVPlayer) {
        self.player = playerView
        self.view.addSubview(self.player!)
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let URL:NSURL = NSURL(string: "http://live.hkstv.hk.lxdns.com/live/hks/playlist.m3u8")!
//
//        self.player.exchangeWithURL(url: URL)
//    }
    
    //如果有UINavigationController 则 UINavigationController 也要重写此方法,存在UITabBarController 时也一样
    override var shouldAutorotate: Bool
    {
        guard  let islock = self.player?.isLocked else { return false }
        return !islock
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
