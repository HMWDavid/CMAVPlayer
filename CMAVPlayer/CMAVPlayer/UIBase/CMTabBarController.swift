//
//  CMTabBarController.swift
//  RxLocaServer
//
//  Created by 洪绵卫 on 2018/5/3.
//  Copyright © 2018年 洪绵卫. All rights reserved.
//

import UIKit
import Hue
class CMTabBarController: UITabBarController,UITabBarControllerDelegate {
    
    var navigationControllers = [CMNavigationController]()
    
    var layout:[NSLayoutConstraint]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.layout = self.tabBar.constraints

        self.delegate = self as UITabBarControllerDelegate
        
        self.addChildViewControllers()
        
        self.viewControllers = self.navigationControllers
    }

    @objc func barButtonClick(_ sender:UIButton) {
        sender.isSelected = true
        self.selectedIndex = 1
    }

    var TabBar:UIView!
    
    func setTabBar() {
        self.TabBar = UIView()
        self.view.addSubview(self.TabBar)
    }
    
    ///设置子控制器
    func addChildViewControllers() {
        
        let classNameArray = ["CMHomeViewController",
                              "CMCommunityViewController",
                              "CMPersonalCenterViewController",]
        
        let imageArray     = ["tabBar_IpaoThemeNormal",
                              "",
                              "tabBar_TrystNormal",
                              ]
        
        let imageSelectArray = ["tabBar_IpaoThemeSelected",
                                "",
                                "tabBar_TrystSelected",
                                ]
        let titleArray = ["主页","社区","个人中心",]
        
        for item in classNameArray{
            
            let index = classNameArray.index(of: item)!

            //1:动态获取命名空间
            guard let name = Bundle.main.infoDictionary!["CFBundleExecutable"] as? String else {
                CMLog("获取命名空间失败")
                continue
            }
            
            let cls: AnyClass? = NSClassFromString(name + "." + item)
            
            // Swift中如果想通过一个Class来创建一个对象, 必须告诉系统这个Class的确切类型
            guard let typeClass = cls as? UIViewController.Type else {
                CMLog("class不能当做UIViewController")
                continue
            }
            
            let childController = typeClass.init()
            
            self.addChildrenViewController(childController,
                                           titleArray[index],
                                           UIImage(named: imageArray[index]),
                                           UIImage(named: imageSelectArray[index]))
        }
    }
    
    func addChildrenViewController(_ rootChildVC:UIViewController,
                                   _ title:String,
                                   _ normalImage:UIImage?,
                                   _ selecedImage:UIImage?){
        
        let navi = CMNavigationController.init(rootViewController: rootChildVC)
        
        rootChildVC.title = title
        
        rootChildVC.tabBarItem.image = normalImage?.withRenderingMode(.alwaysOriginal)
        
        //设置图片,并使用原始图片色值,不用系统渲染(蓝色)
        rootChildVC.tabBarItem.selectedImage = selecedImage?.withRenderingMode(.alwaysOriginal)
        
        //设置标题颜色
       UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor:UIColor(hex: "#ff9191")], for: .selected)

        self.navigationControllers.append(navi)
    }
    
    override var shouldAutorotate: Bool{
        return self.selectedViewController!.shouldAutorotate
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
