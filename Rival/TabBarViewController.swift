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

        // Do any additional setup after loading the view.
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let index = tabBar.items?.firstIndex(of: item)
        switch(index) {
        case 0: //Explorer
            break
        case 1: //Plot
            if let navigationController = self.viewControllers![1] as? UINavigationController {
                let plotController = navigationController.topViewController as! PlotViewController
                plotController.refreshPlot()
            }
        default:
            break
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
