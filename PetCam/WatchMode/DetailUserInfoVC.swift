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
import GoogleSignIn
import FirebaseCore
import AuthenticationServices

class DetailUserInfoVC: UIViewController {
    let userInfo = UserInfo.info
    let userInfoVCModel = UserInfoVCModel()
    let activityIndicator = UIActivityIndicatorView(style: .large)
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
        let message = "계정을 삭제한 후에는 복구할 수 없습니다.\n 보안을 위해 로그인 후 계정이 삭제됩니다."
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let delete = UIAlertAction(title: "삭제", style: .destructive) {_ in
 
            self.checkAuthProvider()
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        cancel.setValue(UIColor.lightGray, forKey: "titleTextColor")
        alert.addAction(delete)
        alert.addAction(cancel)
        return alert
    }
    func checkAuthProvider() {
        guard let user = Auth.auth().currentUser else {return}
            for userInfo in user.providerData {
                switch userInfo.providerID {
                case "google.com":
                    deleteGoogleAuth()
                    return
                case "apple.com":
                    reauthenticateAppleUser()

                    return
                default:
                    return
                }
            }
        
    }
    func moveSignInVC() {
        guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else {return}
        setupActivityIndicator()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.activityIndicator.isHidden = true
            sceneDelegate.moveToSignInVC()
        }
        
    }
    func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
        activityIndicator.startAnimating()
    }
    func deleteGoogleAuth() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            return }

        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: self) {
            [unowned self] result, error in
            guard error == nil else {return}
            guard let user = result?.user, let idToken = user.idToken?.tokenString else {return}
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            Auth.auth().currentUser?.reauthenticate(with: credential) { error, authResult in
              if let error = error {
                  print("reauthenticate",error)
              } else {
                  
              
              }
            }
            Auth.auth().currentUser?.delete { error in
              if let error = error {
                print("deleteUser error",error)
              } else {
                  guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else {return}
                  
                  self.userInfo.deleteUser()
                  self.moveSignInVC()
              }
            }
        }
    }
    func reauthenticateAppleUser() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self // Ensure you conform to ASAuthorizationControllerDelegate
        authorizationController.presentationContextProvider = self // Ensure you conform to ASAuthorizationPresentationContextProviding
        authorizationController.performRequests()
    }

    


}
extension DetailUserInfoVC: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let appleIDToken = appleIDCredential.identityToken,
           let idTokenString = String(data: appleIDToken, encoding: .utf8) {
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nil)
            fetchRefreshToken(from: idTokenString)
            Auth.auth().currentUser?.reauthenticate(with: credential) { authResult, error in
                if let error = error {
                    print("Reauthentication failed: \(error.localizedDescription)")
                } else {
                    print("Reauthentication successful. Now you can proceed with the account deletion.")
                    // Proceed with account deletion
                    Auth.auth().currentUser?.delete { error in
                        if let error = error {
                            print("Failed to delete user: \(error.localizedDescription)")
                        } else {
                            guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else {return}
                            self.userInfoVCModel.revokeToken()
                            self.userInfo.deleteUser()
                            self.moveSignInVC()
                        }
                    }
                }
            }
        }
    }
    func fetchRefreshToken(from code: String) {
        guard let url = URL(string: "http://diddbstjr55.iptime.org:8002/refresh_token?code=\(code)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let refreshToken = jsonResponse["refresh_token"] as? String {
                    // 토큰을 UserDefaults에 저장합니다.
                    UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
                    print("Refresh token saved: \(refreshToken)")
                }
            } catch let parsingError {
                print("Error parsing JSON: \(parsingError)")
            }
        }
        
        task.resume()
    }
}
extension DetailUserInfoVC : ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

