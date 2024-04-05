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

struct FirebaseCamListModel: Codable {
    let result: [FirebaseCamList]
}

struct FirebaseCamList: Codable {
    let camName: String
    let hls: String
    let date: Int
    let batteryLevel: Int
    let batteryState: String
    let deviceModel: String
    let deviceVersion: String
    let torch: Bool
}

class FirebaseModel: ObservableObject {
    static var fb = FirebaseModel()
    private init () {}
    var moveVC = MoveViewControllerModel()
    var databaseRef = Database.database().reference()
    var storageRef = Storage.storage().reference()
    var userID = Auth.auth().currentUser?.uid ?? ""
    var userEmail = Auth.auth().currentUser?.email ?? ""
    var userName = Auth.auth().currentUser?.displayName ?? ""
    var userPhotoURL = Auth.auth().currentUser?.photoURL
    var cancellables: Set<AnyCancellable> = []
    var checkCamList: [String:Int] = [:]
    @Published var camList: [FirebaseCamList] = []
    func camListCount(completion: @escaping(Int) -> Void)  {
        $camList.sink { fb in
            completion(fb.count)
        }.store(in: &cancellables)
    }
    func creatUserChild () -> String {
        let path = "PetCam/Users/\(userID)"
        return path
    }
    func creatUser() {
        let child = creatUserChild() + "/userInfo"
        print("FirebaseModel CreatUser() child : ", child)
        let value = ["userEmail" : userEmail, "userID" : userID]
        databaseRef.child(child ).setValue(value)
    }
    func updateUserInfo() {
        guard let auth = Auth.auth().currentUser else {return}
        print("fb auth", auth)
        guard let name = auth.displayName else {return}
        print("fb name", name)
        guard let email = auth.email else {return}
        print("fb email", email)
//        guard let photoURL = auth.photoURL else {return}
        let uid = auth.uid
        userName = name
        userEmail = email
        userID = uid
//        userPhotoURL = photoURL
    }

    func signOut() {
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }
        camList = []
        
    }
    func singleEventUpdate() {
        let child = creatUserChild() + "/CamList/"
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
    func camListUpdate() {
        let child = creatUserChild() + "/CamList/"
        print("camListUpdate", child)
        print("userName", userName)
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
        let child = creatUserChild() + "/CheckCam/"
        databaseRef.child(child).observe(DataEventType.value) { snapData in
            if let data = snapData.value as? [String:Int] {
                
                self.checkCamList = data
            }
            completion()
        }
    }
    func removeObseve() {
        removeCamListObseve()
        removeCheckCamObseve()
    }
    func removeCamListObseve() {
        let child = creatUserChild() + "CamList/"
        databaseRef.child(child).removeAllObservers()
    }
    func removeCheckCamObseve() {
        let child = creatUserChild() + "CamList/"
        databaseRef.child(child).removeAllObservers()
    }
    func changePosition(hls: String) {
        let path  = creatUserChild() + "/CamList/\(hls)/position"
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
