//
//  UserInfoModel.swift
//  PetCam
//
//  Created by 양윤석 on 3/19/24.
//

import Foundation
import UIKit
import FirebaseAuth
import GoogleSignIn

class UserInfoVCModel {
//    let fbModel = FirebaseModel()
    
    func setUserNameAlert(oldName: String) -> UIAlertController {
        let title = "닉네임 변경"
//        let message = "변경할 카메라 이름을 입력해 주세요."
        let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
        alert.addTextField { alert in
            alert.text = oldName
        }

        let cancel = UIAlertAction(title: "취소", style: .cancel)
//        save.setValue(UIColor(named: "MainGreen"), forKey: "titleTextColor")
        cancel.setValue(UIColor.lightGray, forKey: "titleTextColor")
        alert.addAction(cancel)
        return alert
    }
    func setUserImage(photoURL: URL) -> UIImage? {
        let defaultImage = UIImage(systemName: "person.crop.circle.fill")
        if let image = UserDefaults.standard.data(forKey: photoURL.description) {
            return UIImage(data: image)
        } else {
            guard let data = try? Data(contentsOf: photoURL) else {return defaultImage}
            guard let photoImage = UIImage(data: data) else {return defaultImage}
            
            let imagePng = photoImage.pngData()
            UserDefaults.standard.set(imagePng, forKey: photoURL.description)
            return photoImage
            
        }
        
    }
    func checkAuthProvider() {
        guard let user = Auth.auth().currentUser else {return}
            for userInfo in user.providerData {
                switch userInfo.providerID {
                case "google.com":
                    return
                case "apple.com":
                    revokeToken()
                    return
                default:
                    return
                }
            }
        
    }
    func checkAuthProviderImage() -> UIImage {
        let defaultImage = UIImage(systemName: "person.crop.circle.fill")!
        if let user = Auth.auth().currentUser {
            for userInfo in user.providerData {
                switch userInfo.providerID {
                case "google.com":
                    return UIImage(named: "GoogleLogo") ?? defaultImage
                case "apple.com":
                    return UIImage(named: "AppleLogo") ?? defaultImage
                default:
                    return defaultImage
                }
            }
        } else {
            // 사용자가 로그인하지 않았을 경우
            print("사용자가 로그인하지 않았습니다.")
        }
        return defaultImage
    }
    func revokeToken() {
        guard let refreshToken = UserDefaults.standard.string(forKey: "refreshToken") else {
            print("No refresh token found")
            return
        }
        
        guard let url = URL(string: "http://diddbstjr55.iptime.org:8002/revoke_token?refresh_token=\(refreshToken)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error during URLSession data task: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
        }
        
        task.resume()
    }

    func removeAccount() {
      let token = UserDefaults.standard.string(forKey: "refreshToken")
     
      if let token = token {
          let url = URL(string: "https://diddbstjr55.iptime.org:8002/revoke_token?refresh_token=\(token)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "https://apple.com")!
     
          let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard data != nil else { return }
          }
          task.resume()
      }
      // Delete other information from the database...
      // Sign out on FirebaseAuth
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }


}
