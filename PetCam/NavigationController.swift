//
//  NavigationController.swift
//  PetCam
//
//  Created by 양윤석 on 2/23/24.
//

import Foundation
import UIKit

class NavigationModel {
    let navigationColor = UIColor(named: "BackgroundColor") ?? .green
    let fontColor = UIColor(named: "FontColor") ?? .black
    
    func navigationBaseSet() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = navigationColor
        appearance.titleTextAttributes = [.foregroundColor: fontColor ]
        return appearance
    }
    
}


extension UINavigationItem {
    func makeSFSymbolButton(_ target: Any?, action: Selector, symbolName: String) -> UIBarButtonItem {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: symbolName), for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
//        button.tintColor = UIColor(named: "FontColor")
        button.tintColor = .white
        
        let barButtonItem = UIBarButtonItem(customView: button)
        barButtonItem.customView?.translatesAutoresizingMaskIntoConstraints = false
        barButtonItem.customView?.heightAnchor.constraint(equalToConstant: 30).isActive = true
        barButtonItem.customView?.widthAnchor.constraint(equalToConstant: 30).isActive = true
        
        return barButtonItem
    }
    
}

