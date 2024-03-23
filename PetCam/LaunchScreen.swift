//
//  LaunchScreen.swift
//  PetCam
//
//  Created by 양윤석 on 2/24/24.
//

import Foundation
import UIKit
import FirebaseAuth

class LaunchScreen: UIViewController {
    let moveVC = MoveViewControllerModel()
    let fbModel = FirebaseModel.fb
    override func viewDidLoad() {
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        print("viewWillDisappear")
        if let auth = Auth.auth().currentUser {
            print(auth.uid)
            let value = fbModel.currentSelectMode()
            print("s",value)
            if value == "CamMode" {
                self.present(moveVC.moveToVC(storyboardName: "CamMode", className: value), animated: true)
            }
            self.present(moveVC.moveToVC(storyboardName: "Main", className: value), animated: true)
        } else {
            self.present(moveVC.moveToVC(storyboardName: "Main", className: "SigninVC"), animated: true)
        }
    }
}
