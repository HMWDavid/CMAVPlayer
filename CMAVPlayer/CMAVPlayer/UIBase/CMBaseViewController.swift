//
//  CMBaseViewController.swift
//  RxLocaServer
//
//  Created by 洪绵卫 on 2018/5/2.
//  Copyright © 2018年 洪绵卫. All rights reserved.
//

import UIKit

class CMBaseViewController: UIViewController {
    
    override func loadView() {
        super.loadView()
        //这个无法侧滑返回
        //self.navigationController?.isNavigationBarHidden = true
        
        self.navigationController?.navigationBar.isHidden = true
        
        //关闭自动偏移
        self.automaticallyAdjustsScrollViewInsets = false
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    
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
