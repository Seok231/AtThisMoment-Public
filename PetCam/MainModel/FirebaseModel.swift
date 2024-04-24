//
//  FirebaseModel.swift
//  PetCam
//
//  Created by 양윤석 on 2/17/24.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth
import Combine
import FirebaseStorage
import UIKit


struct FirebaseCamList: Codable {
    let camName: String
    let hls: String
    let date: Double
    let batteryLevel: Int
    let batteryState: String
    let deviceModel: String
    let deviceVersion: String
    let torch: Bool
    let position: Double
}

class UserInfo: ObservableObject {
    static var info = UserInfo()
    private init () {}
    var databaseRef = Database.database().reference()
    var uid = Auth.auth().currentUser?.uid ?? ""
    @Published var name = Auth.auth().currentUser?.displayName
    var email = Auth.auth().currentUser?.email
    var photoURL = Auth.auth().currentUser?.photoURL
    var userDeviceID = UIDevice.current.identifierForVendor!.uuidString
    @Published var info: [String:Any] = [:]
    func creatUserChild () -> String {
        let path = "PetCam/Users/\(uid)"
        print(path)
        return path
    }
    func signOutOtherDevice(completion: @escaping () -> Void) {
        let child = "PetCam/Users/\(uid)" + "/userInfo"
        databaseRef.child(child).observe(.childRemoved) { DataSnapshot in
            print(child)
//            guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else {return}
//            sceneDelegate.moveToSignInVC()
            completion()
        }
    }
    func deleteUser() {
        let child = "PetCam/Users/\(uid)"
        let info = "\(child)/userInfo/name"
        databaseRef.child(info).removeValue()
        databaseRef.child(child).removeValue()
    }
    func creatUser(name: String, user: User) {
        let child = "PetCam/Users/\(user.uid)" + "/userInfo"
        let email = user.email
        let uid = user.uid
        let value = ["userEmail" : email, "userID" : uid, "name" : name]
        databaseRef.child(child).setValue(value)
    }
        
    func getUserInfo() {
        let child = creatUserChild() + "/userInfo/"
        print("getUserInfo", child)
        databaseRef.child(child).observe(.value) { dataSnap in
            guard let data = dataSnap.value as? [String:Any] else{return}
            self.info = data
            guard let name = data["name"] as? String else {return}
            self.name = name
        }
    }
    func userInfoInit(user: User) {
        uid = user.uid
        name = user.displayName
        email = user.email
        userDeviceID = UIDevice.current.identifierForVendor!.uuidString
        photoURL = user.photoURL
    }

    func signOut() {
        
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }
        
    }
    func setAuthName(newName: String) {
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = newName
        changeRequest?.commitChanges()
    }
    func setUserInfoName(newName: String) {
        let child = creatUserChild() + "/userInfo/"
        let value = ["name":newName]
        databaseRef.child(child).updateChildValues(value)
    }
    func noneUserInfoAlert() -> UIAlertController {
        
        let title = "로그인 세션이 만료되었습니다."
        let message = "로그인 화면으로 이동합니다."
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else {return alert}
        let move = UIAlertAction(title: "확인", style: .cancel) {_ in
            self.signOut()
            sceneDelegate.moveToSignInVC()
        }
        move.setValue(UIColor(named: "MainGreen"), forKey: "titleTextColor")
        alert.addAction(move)
        return alert
    }
}

class FirebaseModel: ObservableObject {
    static var fb = FirebaseModel()
    private init () {
        let device = UIDevice.current
        let selName = "_\("deviceInfo")ForKey:"
        let selector = NSSelectorFromString(selName)
        if device.responds(to: selector) {
            let name = String(describing: device.perform(selector, with: "marketing-name").takeRetainedValue())
            deviceName = name
        }
        
    }
    var moveVC = MoveViewControllerModel()
    var userInfo = UserInfo.info
    var databaseRef = Database.database().reference()
    var storageRef = Storage.storage().reference()
    var cancellables: Set<AnyCancellable> = []
    var deviceName: String?
    @Published var info: [String:Any] = [:]
    @Published var checkCamList: [String:Int] = [:]
    @Published var camList: [FirebaseCamList] = []
    func camListCount(completion: @escaping(Int) -> Void)  {
        $camList.sink { fb in
            completion(fb.count)
        }.store(in: &cancellables)
    }
    func singleEventUpdate() {
        let child = userInfo.creatUserChild() + "/CamList/"
        databaseRef.child(child).observeSingleEvent(of: .value){ DataSnapshot in
            guard let snapData = DataSnapshot.value as? [String:Any] else{
                self.camList = []
                return}
            let data = try! JSONSerialization.data(withJSONObject: Array(snapData.values), options: [])
            do {
                let decoder = JSONDecoder()
                self.camList = try decoder.decode([FirebaseCamList].self, from: data)
                self.camList.sort(by: {$0.date > $1.date})
            } catch let error {
                print("get Firebase data error", error)
            }
        }
    }
    // (Int(Date().timeIntervalSince1970)).description
    func camListUpdate(completion: @escaping () -> Void) {
        let child = userInfo.creatUserChild() + "/CamList/"
        databaseRef.child(child).observe(DataEventType.value) { DataSnapshot in
            guard let snapData = DataSnapshot.value as? [String:Any] else{
                self.camList = []
                return }
            let data = try! JSONSerialization.data(withJSONObject: Array(snapData.values), options: [])
            do {
                let decoder = JSONDecoder()
                self.camList = try decoder.decode([FirebaseCamList].self, from: data)
                self.camList.sort(by: {$0.date > $1.date})
            } catch let error {
                print("get Firebase data error", error)
            }

        }
    }

    func updateCheckCam(completion: @escaping () -> Void) {
        
        let child = userInfo.creatUserChild() + "/CheckCam"
        print("updateCheckCam path", child)
        databaseRef.child(child).observe(DataEventType.value) { snapData in
            if let data = snapData.value as? [String:Int] {
                
                self.checkCamList = data
            }
            completion()
        }
    }
    func removeObseve() {
        print("removeObseve")
        removeCamListObseve()
        removeCheckCamObseve()
        removeGetUserInfo()
    }
    func removeCamListObseve() {
        let child = userInfo.creatUserChild() + "/CamList/"
        databaseRef.child(child).removeAllObservers()
    }
    func removeCheckCamObseve() {
        let child = userInfo.creatUserChild() + "/CheckCam/"
        databaseRef.child(child).removeAllObservers()
    }
    func removeGetUserInfo() {
        let child = userInfo.creatUserChild() + "/userInfo/"
        databaseRef.child(child).removeAllObservers()
    }
    func changePosition(hls: String) {
        let path  = userInfo.creatUserChild() + "/CamList/\(hls)/position"
        let date = Int(Date().timeIntervalSince1970)
        databaseRef.child(path).setValue(date)
    }
    func uploadImage(image: UIImage, imageName: String, completion: @escaping (URL?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.4) else { return }
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpeg"
        storageRef.child("Thumbnail/\(imageName)").putData(imageData, metadata: metaData) { metaData, error in
            self.storageRef.downloadURL { url, _ in
                completion(url)
            }
        }
    }
    
    func downloadImage(urlString: String, completion: @escaping (UIImage?) -> Void) {
        let megaByte = Int64(1 * 1024 * 1024)
        storageRef.child("Thumbnail/").getData(maxSize: megaByte) { data, error in
            guard let imageData = data else {
                completion(nil)
                return
            }
            completion(UIImage(data: imageData))
        }
    }       
    
    func deleteImage(imageName: String) {
        storageRef.child("Thumbnail/\(imageName)").delete { error in
            if let error = error { print("deleteImage error", error) }
        }
    }
    func selectModeSave(value: String) {
        UserDefaults.standard.set(value, forKey: "selectMode")
    }
    //current
    func currentSelectMode() -> String {
        UserDefaults.standard.string(forKey: "selectMode") ?? "SelectModeVC"
    }

    
}
