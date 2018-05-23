//
//  CMHomeViewController.swift
//  RxLocaServer
//
//  Created by 洪绵卫 on 2018/5/2.
//  Copyright © 2018年 洪绵卫. All rights reserved.
//

import UIKit
import AVKit

class CMHomeViewController: CMBaseViewController,CMAVPlayerDelegate,AVPlayerViewControllerDelegate {
    
    var player:CMAVPlayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //self.view.translatesAutoresizingMaskIntoConstraints = false

        self.view.backgroundColor = UIColor.blue
        
        NotificationCenter.default.addObserver(self, selector: #selector(floatingScreenTapGesture), name: NSNotification.Name(rawValue: CMAVPlayerNotification_floatingScreenTapGesture), object: nil)
        
        let btn = UIButton()
        btn.setTitle("pushVC", for: .normal)
        btn.backgroundColor = .orange
        btn.addTarget(self, action: #selector(btnClick), for: .touchUpInside)
        self.view.addSubview(btn)
        btn.snp.makeConstraints { (make) in
            make.width.height.equalTo(80)
            make.center.equalTo(self.view)
        }
    }
    
    
    /// 悬浮窗口模式下,tap单击手势触发了
    ///
    /// - Parameter notification: 通知
    @objc func floatingScreenTapGesture(_ notification:NSNotification){
        
        if self.navigationController?.viewControllers.count == 1 {
            
            let player = notification.object as! CMAVPlayer

            let nextVC = CMHomeNextViewController()
    
            nextVC.player = player
            
            nextVC.view.addSubview(player)
            
            self.navigationController?.pushViewController(nextVC, animated: true)
            
            player.entranceDefultScreen()
        }
    }
    
    @objc func btnClick() {
        
        var player:CMAVPlayer?
        
        for object in self.navigationController!.view.subviews {
            if object.isKind(of: CMAVPlayer.self) {
                player = object as? CMAVPlayer
                break
            }
        }
        
        if player == nil {
            let nextVC = CMHomeNextViewController()
            self.navigationController?.pushViewController(nextVC, animated: true)
        }else{
            let nextVC = CMHomeNextViewController()
            
            nextVC.player = player!
            
            nextVC.view.addSubview(player!)
            
            self.navigationController?.pushViewController(nextVC, animated: true)
            
            player!.entranceDefultScreen()
        }
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
