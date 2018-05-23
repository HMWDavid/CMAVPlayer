//
//  CMNavigationController.swift
//  RxLocaServer
//
//  Created by 洪绵卫 on 2018/5/3.
//  Copyright © 2018年 洪绵卫. All rights reserved.
//

import UIKit

class CMNavigationController: UINavigationController {
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        
        if self.viewControllers.count > 0{
            
            //push时候自动隐藏tabBar
            viewController.hidesBottomBarWhenPushed = true
        }
        
        super.pushViewController(viewController, animated: animated)
        
        // 修正push控制器tabbar上移问题
        if #available(iOS 11.0, *){
            
            //处理了push后隐藏底部UITabBar的情况，并解决了iPhonX上push时UITabBar上移的问题。
            guard var rect = self.tabBarController?.tabBar.frame else {
                return
            }
            
            rect.origin.y = UIScreen.main.bounds.size.height - rect.size.height
    
            self.tabBarController?.tabBar.frame = rect
        }
    }
    
//    override func popViewController(animated: Bool) -> UIViewController? {
//        // 修正push控制器tabbar上移问题
//        if #available(iOS 11.0, *){
//
//            //处理了push后隐藏底部UITabBar的情况，并解决了iPhonX上push时UITabBar上移的问题。
//            guard var rect = self.tabBarController?.tabBar.frame else {
//                return super.popViewController(animated: animated)
//            }
//
//            rect.origin.y = UIScreen.main.bounds.size.height - rect.size.height
//
//            self.tabBarController?.tabBar.frame = rect
//        }
//
//        return super.popViewController(animated: animated)
//    }
    
    override var shouldAutorotate: Bool{
        return self.topViewController!.shouldAutorotate
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
