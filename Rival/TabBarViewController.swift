//
//  TabBarViewController.swift
//  Rival
//
//  Created by Yannik Schroeder on 07.05.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let index = tabBar.items?.firstIndex(of: item)
        switch(index) {
        case 0: //Explorer
            break
        case 1: //Plot
            if let navigationController = self.viewControllers![1] as? UINavigationController {
                //let plotController = navigationController.topViewController as! PlotViewController
                //plotController.refreshPlot()
            }
        default:
            break
        }
    }

}
