//
//  WatchTabbar.swift
//  PetCam
//
//  Created by 양윤석 on 2/16/24.
//

import Foundation
import UIKit

class WatchTabbar: UITabBarController {
    override func viewDidLoad() {
        self.tabBar.items?[0].title = "모니터링"
        self.tabBar.items?[0].image = UIImage(systemName: "camera.on.rectangle")
        self.tabBar.items?[0].selectedImage = UIImage(systemName: "camera.on.rectangle.fill")
        
        self.tabBar.items?[1].title = "공지사항"
        self.tabBar.items?[1].image = UIImage(systemName: "list.bullet")
        self.tabBar.items?[1].selectedImage = UIImage(systemName: "list.bullet.indent")
        
        self.tabBar.items?[2].title = "내정보"
        self.tabBar.items?[2].image = UIImage(systemName: "person.circle")
        self.tabBar.items?[2].selectedImage = UIImage(systemName: "person.circle.fill")
        
        let tabBarItemAppearance = UITabBarItemAppearance()
        tabBarItemAppearance.normal.iconColor = .lightGray
        tabBarItemAppearance.normal.titleTextAttributes = [.foregroundColor : UIColor.gray]
    
        tabBarItemAppearance.selected.iconColor = UIColor(named: "MainGreen")
        tabBarItemAppearance.selected.titleTextAttributes = [.foregroundColor : UIColor(named: "MainGreen") ?? .green]
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.backgroundColor = UIColor(named: "BackgroundColor")
        tabBarAppearance.inlineLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.compactInlineLayoutAppearance =
        tabBarItemAppearance
        
        self.tabBar.standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            self.tabBar.scrollEdgeAppearance = tabBarAppearance
        } else {
        }
        
    }
}
