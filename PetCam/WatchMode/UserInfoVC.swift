//
//  UserInfoVC.swift
//  PetCam
//
//  Created by 양윤석 on 2/17/24.
//

import Foundation
import UIKit
import FirebaseAuth

class UserInfoVC: UIViewController {
    let moveVC = MoveViewControllerModel()
    let nvModel = NavigationModel()
    let fbModel = FirebaseModel.fb
    let viewModel = UserInfoModel()
    @IBOutlet weak var signOutBT: UIButton!
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBAction func signOutBTAction(_ sender: Any) {
        let signOut = UIAlertAction(title: "로그아웃", style: .default) { _ in
            self.fbModel.signOut()
            let vc = self.moveVC.moveToVC(storyboardName: "Main", className: "SignInVC")
            self.present(vc, animated: true)
        }
        let alert = moveVC.signOutAlert(signOut: signOut)
        self.present(alert, animated: true)
        
    }
    
    override func viewDidLoad() {
        setLayer()
        navigationSet()
    }
    func navigationSet() {
        let appearance = nvModel.navigationBaseSet()
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.navigationItem.title = "내정보"
    }
    func setLayer() {
        guard let user = Auth.auth().currentUser else {return}
        guard let photoURL = user.photoURL else {return}
        let userImage = viewModel.setUserImage(photoURL: photoURL)
        
        self.view.backgroundColor = UIColor(named: "BackgroundColor")

        
        userImageView.image = userImage
        userNameLabel.text = user.displayName
        userEmailLabel.text = user.email
        
        userNameLabel.textColor = UIColor(named: "FontColor")
        userEmailLabel.textColor = .gray
        
        userNameLabel.font = UIFont.boldSystemFont(ofSize: 30)
        userEmailLabel.font = UIFont.boldSystemFont(ofSize: 15)
        
        userImageView.layer.cornerRadius = userImageView.frame.height / 2
        
        signOutBT.backgroundColor = .gray
        signOutBT.titleLabel?.text = "로그아웃"
        signOutBT.layer.cornerRadius = 10
        signOutBT.titleLabel?.textColor = .white
        
        
    }
}
