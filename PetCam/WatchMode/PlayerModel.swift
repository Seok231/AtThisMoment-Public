//
//  PlayerModel.swift
//  PetCam
//
//  Created by 양윤석 on 2/17/24.
//
import FirebaseDatabase
import Foundation
import AVKit
import UIKit
import Photos

class PlayerModel {
    deinit {
        print("deinit")
    }
    var databaseRef = Database.database().reference()
    var ref: DatabaseReference!
    var fbHandle: DatabaseHandle?
    let fbModel = FirebaseModel.fb
    let userInfo = UserInfo.info
    let imageConf = UIImage.SymbolConfiguration(pointSize: 9, weight: .light)
    let labelFont = UIFont.boldSystemFont(ofSize: 13)
    let tintColor = UIColor.white
    func removeObserve() {
        guard let handle = fbHandle else {
            print("removeObserve() fbHandle error")
            return}
        ref.removeObserver(withHandle: handle)
    }
    func getCamPath(hls: String) -> String {
        let userID = userInfo.uid
        let path = "PetCam/Users/\(userID)/CamList/\(hls)/"
        return path
    }
    func currentCamInfo(hls: String , completion: @escaping(FirebaseCamList) -> Void) {
        let path = "PetCam/Users/\(userInfo.uid)/CamList/\(hls)/"
        print("currentCamInfo2 path", path)
        
        ref = databaseRef.child(path)
        
        fbHandle = ref.observe(DataEventType.value) { snapshot in
            guard let value = snapshot.value as? [String: Any] else { return }
            do {
                let data = try JSONSerialization.data(withJSONObject: value)
                let camList = try JSONDecoder().decode( FirebaseCamList.self, from: data)
                
                completion(camList)
            } catch let error {
                print("Error decoding data: \(error.localizedDescription)")
            }
        }
    }
    func setOnTorch(hls: String) {
        let path = getCamPath(hls: hls) + "torch/"
        databaseRef.child(path).setValue(true)
    }
    func setOffTorch(hls: String) {
        let path = getCamPath(hls: hls) + "torch/"
        databaseRef.child(path).setValue(false)
    }
    
    func checkCameraPermission(){
        if #available(iOS 14, *) {
            _ = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            
        } else {
            _ = PHPhotoLibrary.authorizationStatus()
            
        }
    }
}
