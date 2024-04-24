//
//  UserInfoVC.swift
//  PetCam
//
//  Created by 양윤석 on 2/17/24.
//

import Foundation
import UIKit
import FirebaseAuth
import Combine

class UserInfoVC: UIViewController {
    let moveModel = MoveViewControllerModel()
    let nvModel = NavigationModel()
    let fbModel = FirebaseModel.fb
    let viewModel = UserInfoVCModel()
    let userInfo = UserInfo.info
    var cancellables: Set<AnyCancellable> = []
    @IBOutlet weak var userInfoView: UIView!
    @IBOutlet weak var showUserInfoBT: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var signInLogoView: UIImageView!
    @IBOutlet weak var signOutBT: UIButton!
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBAction func signOutBTAction(_ sender: Any) {
        guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else {return}
        let signOut = UIAlertAction(title: "로그아웃", style: .default) { _ in
            self.userInfo.signOut()
            sceneDelegate.moveToSignInVC()
        }
        let alert = moveModel.signOutAlert(signOut: signOut)
        self.present(alert, animated: true)
        
    }
    override func viewWillAppear(_ animated: Bool) {
        userInfo.getUserInfo()
    }
    override func viewDidLoad() {
        tableView.backgroundColor = UIColor(named: "BackgroundColor")
        setLayer()
        navigationSet()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "DetailCell", bundle: nil), forCellReuseIdentifier: "DetailCell")
        tableView.isScrollEnabled = false
    }
    func navigationSet() {
        let appearance = nvModel.navigationBaseSet()
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.navigationItem.title = "내정보"
        self.navigationController?.navigationBar.tintColor = UIColor(named: "MainGreen")
    }
    func setLayer() {
        let showUserInfo = UITapGestureRecognizer(target: self, action: #selector(showUserInfoView(sender: )))
        let fontColor = UIColor(named: "FontColor")
        let backgroundColor = UIColor(named: "BackgroundColor")
        self.view.backgroundColor = backgroundColor
        
        userInfoView.addGestureRecognizer(showUserInfo)
        userInfoView.backgroundColor = backgroundColor
        userInfoView.layer.cornerRadius = 10
        userInfoView.layer.borderWidth = 0.5
        userInfoView.layer.borderColor = UIColor.lightGray.cgColor
        
        showUserInfoBT.setTitle("", for: .normal)
        showUserInfoBT.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        showUserInfoBT.tintColor = fontColor
        showUserInfoBT.isUserInteractionEnabled = false
        
        userImageView.image = UIImage(systemName: "person.crop.circle.fill")
        
        if let photoURL = userInfo.photoURL {
            let userImage = viewModel.setUserImage(photoURL: photoURL)
            userImageView.image = userImage
        }
        userImageView.tintColor = fontColor
        userInfo.$name.sink { name in
            self.userNameLabel.text = name
        }.store(in: &cancellables)
        
        let authProvider = viewModel.checkAuthProviderImage()
        signInLogoView.image = authProvider
        userEmailLabel.text = userInfo.email
        
        userNameLabel.textColor = fontColor
        userEmailLabel.textColor = .gray
        
        userNameLabel.font = UIFont.boldSystemFont(ofSize: 25)
        userEmailLabel.font = UIFont.boldSystemFont(ofSize: 15)
        
        userImageView.layer.cornerRadius = userImageView.frame.height / 2
        
        signOutBT.backgroundColor = .gray
        signOutBT.titleLabel?.text = "로그아웃"
        signOutBT.layer.cornerRadius = 10
        signOutBT.titleLabel?.textColor = .white
        
        
    }
    @objc func showUserInfoView(sender: UITapGestureRecognizer) {
        guard let nextVC = self.storyboard?.instantiateViewController(identifier: "DetailUserInfoVC") else {return}
        self.navigationController?.pushViewController(nextVC, animated: true)
    }
}

extension UserInfoVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath) as! DetailCell
        switch indexPath.row {
        case 0:
            cell.detailLabel.text = "카메라 모드로 전환"
            cell.iconView.image = UIImage(systemName: "arrow.triangle.2.circlepath.camera.fill")
            return cell
        case 1:
            cell.detailLabel.text = "기기 관리"
            cell.iconView.image = UIImage(systemName: "iphone.gen2")
            return cell
        default:
            cell.detailLabel.text = "기기 관리"
            cell.iconView.image = UIImage(systemName: "iphone.gen2")
            return cell
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let move = UIAlertAction(title: "모드 변경", style: .default) { _ in
                let vc = self.moveModel.moveToVC(storyboardName: "CamMode", className: "StreamingVC")
                self.fbModel.removeObseve()
                UserDefaults.standard.set("StreamingVC", forKey: "Mode")
                self.present(vc, animated: true)
            }
            let alert = moveModel.moveToCamModAlert(move: move)
            print("1")
            self.present(alert, animated: true)
        case 1:
            guard let nextVC = self.storyboard?.instantiateViewController(identifier: "SettingDeviceVC") else {return}
            self.navigationController?.pushViewController(nextVC, animated: true)
        default :
            let move = UIAlertAction(title: "모드 변경", style: .default) { _ in
                let vc = self.moveModel.moveToVC(storyboardName: "CamMode", className: "StreamingVC")
                UserDefaults.standard.set("StreamingVC", forKey: "Mode")
                self.present(vc, animated: true)
            }
            let alert = moveModel.moveToCamModAlert(move: move)
            self.present(alert, animated: true)
        }
    }
    
    
}
