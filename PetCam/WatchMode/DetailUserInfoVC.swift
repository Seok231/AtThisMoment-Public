//
//  DetailUserInfoView.swift
//  AtThisMoment
//
//  Created by 양윤석 on 4/17/24.
//

import Foundation
import Combine
import UIKit
import FirebaseAuth

class DetailUserInfoVC: UIViewController {
    let userInfo = UserInfo.info
    let userInfoVCModel = UserInfoVCModel()

    var cancellables: Set<AnyCancellable> = []
    @IBOutlet weak var userNameView: UIView!
    @IBOutlet weak var userNameTilteLabel: UILabel!
    @IBOutlet weak var setUserNameBT: UIButton!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userEmailView: UIView!
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var userEmailTitleLabel: UILabel!
    @IBOutlet weak var deleteUserBT: UIButton!
    @IBOutlet weak var userImageView: UIImageView!
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor(named: "BackgroundColor")
        setLayout()
        
    }
    
    @IBAction func deleteUser(_ sender: Any) {
        let alert = deleteUserAlert()
        self.present(alert, animated: true)
    }
    func setLayout() {
        let backgroundColor = UIColor(named: "BackgroundColor")
        let fontColor = UIColor(named: "FontColor")
        if let photoURL = userInfo.photoURL {
            print("pho")
            let userImage = userInfoVCModel.setUserImage(photoURL: photoURL)
            userImageView.image = userImage
        } else {
            userImageView.image = UIImage(systemName: "person.crop.circle.fill")
            
        }
        userNameTilteLabel.textColor = .lightGray
        userNameTilteLabel.text = "닉네임"
        userNameTilteLabel.font = UIFont.boldSystemFont(ofSize: 13)
        
        userImageView.tintColor = fontColor
        userImageView.layer.cornerRadius = userImageView.frame.width / 2
        
        let setUserName = UITapGestureRecognizer(target: self, action: #selector(setUserName(sender:)))
        userNameView.addGestureRecognizer(setUserName)
        userNameView.layer.borderWidth = 0.5
        userNameView.layer.borderColor = UIColor.lightGray.cgColor
        userNameView.layer.cornerRadius = 10
        userNameView.backgroundColor = backgroundColor
        
        userNameLabel.textColor = fontColor
        userInfo.$name.sink { name in
            self.userNameLabel.text = name
        }.store(in: &cancellables)
        
        setUserNameBT.setTitle("", for: .normal)
        setUserNameBT.setImage(UIImage(systemName: "pencil"), for: .normal)
        setUserNameBT.tintColor = .lightGray
        setUserNameBT.isUserInteractionEnabled = false
        
        userEmailTitleLabel.textColor = .lightGray
        userEmailTitleLabel.text = "이메일"
        userEmailTitleLabel.font = UIFont.boldSystemFont(ofSize: 13)
        
        userEmailView.layer.borderWidth = 0.5
        userEmailView.layer.borderColor = UIColor.lightGray.cgColor
        userEmailView.layer.cornerRadius = 10
        userEmailView.backgroundColor = backgroundColor
        
        
        
        userEmailLabel.textColor = fontColor
        userEmailLabel.text = userInfo.email
//        userEmailLabel.font = UIFont.boldSystemFont(ofSize: 20)
        
//        deleteUserBT.setTitle("계정 삭제", for: .normal)
        deleteUserBT.backgroundColor = .gray
        deleteUserBT.layer.cornerRadius = 10
        deleteUserBT.titleLabel?.text = "계정 삭제"
        deleteUserBT.titleLabel?.textColor = .white
    }
    @objc func setUserName(sender: UITapGestureRecognizer) {

        let alert = userInfoVCModel.setUserNameAlert(oldName: userInfo.name ?? "")
        let save = UIAlertAction(title: "변경", style: .destructive) { save in
            if let text = alert.textFields?[0].text {
                self.userInfo.name = text
                self.userInfo.setAuthName(newName: text)
                self.userInfo.setUserInfoName(newName: text)
            }
        }
        save.setValue(UIColor(named: "MainGreen"), forKey: "titleTextColor")
        alert.addAction(save)
        self.present(alert, animated: true)
        
    }

    
}
extension DetailUserInfoVC {
    func deleteUserAlert() -> UIAlertController {
        let title = "정말 계정을 삭제하시겠습니까?"
        let message = "계정을 삭제한 후에는 복구할 수 없습니다."
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        guard let user = Auth.auth().currentUser else {
            let userInfo = UserInfo.info
            let alert = userInfo.noneUserInfoAlert()
            return alert
        }
        guard let email = user.email else {return alert}
        let delete = UIAlertAction(title: "삭제", style: .destructive) {_ in
            let splitEmail = email.split(separator: "@")
            let credential = EmailAuthProvider.credential(withEmail: email, password: String(splitEmail[0]))
            
            
            self.userInfoVCModel.checkAuthProvider()
            
            user.reauthenticate(with: credential) { error, authResult in
              if let error = error {
                  print("reauthenticate",error)
              } else {
                  
                  user.delete { error in
                    if let error = error {
                      print("deleteUser error",error)
                    } else {
                        guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else {return}
                        
                        sceneDelegate.moveToSignInVC()
                    }
                  }
              }
            }
            
            
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        cancel.setValue(UIColor.lightGray, forKey: "titleTextColor")
        alert.addAction(delete)
        alert.addAction(cancel)
        return alert
    }

}
