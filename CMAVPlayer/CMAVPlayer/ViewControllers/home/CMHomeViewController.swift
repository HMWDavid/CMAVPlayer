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
    }
    
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let nextVC = CMHomeNextViewController()
        
        self.navigationController?.pushViewController(nextVC, animated: true)
    }

    
    
    
    
//    //如果有UINavigationController 则 UINavigationController 也要重写此方法,存在UITabBarController 时也一样
//    override var shouldAutorotate: Bool
//    {
//        guard  let islock = self.player?.isLocked else { return false }
//        return !islock
//        
//    }
    
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
