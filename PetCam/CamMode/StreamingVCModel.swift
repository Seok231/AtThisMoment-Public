//
//  StreamingVCModel.swift
//  PetCam
//
//  Created by 양윤석 on 2/26/24.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
import FirebaseDatabaseInternal
import AVFoundation
import Combine
import Photos

class StreamingVCModel {
    let fbModel = FirebaseModel.fb
    let userInfo = UserInfo.info
    var databaseRef = Database.database().reference()
    var storageRef = Storage.storage().reference()
    let userDeviceID = UIDevice.current.identifierForVendor!.uuidString
    let deviceVersion = UIDevice.current.systemVersion
    var batteryLevel: Float { UIDevice.current.batteryLevel }
    var pushURL = "rtmp://220.121.93.66:1935/live"
    var pushID = "ch1_s1"
    @Published var camStatus = false
    @Published var camInfo = [:]
    var cancellables: Set<AnyCancellable> = []
//    var deviceModelName: String {
//        let selName = "_\("deviceInfo")ForKey:"
//        let selector = NSSelectorFromString(selName)
////        let test : String = UIDevice.current.model
////        print(test)
//        if UIDevice.current.responds(to: selector) { // [옵셔널 체크 실시]
//            let name = String(describing: UIDevice.current.perform(selector, with: "marketing-name").takeRetainedValue())
//            return name
//        }
//        return ""
//    }
    func deviceName() -> String {
        let device = UIDevice.current
        let selName = "_\("deviceInfo")ForKey:"
        let selector = NSSelectorFromString(selName)
        if device.responds(to: selector) {
            let name = String(describing: device.perform(selector, with: "marketing-name").takeRetainedValue())
            return name
        }
        return ""
        
        
    }
    func userCamPath() -> String {
        let path = "PetCam/Users/\(userInfo.uid)/CamList/\(userDeviceID)/"
        return path
    }
    func checkCam() {
        let path = "PetCam/Users/\(userInfo.uid)/CheckCam/\(userDeviceID)/"
        databaseRef.child(path).observe(.value) { snapData in
            if let data = snapData.value as? Int {
                if data == 1 {self.camStatus = true} else {self.camStatus = false}
            }
        }
    }
    func checkCamName(completion: @escaping(String) -> Void) {
        let path = "\(userCamPath())camName"
        databaseRef.child(path).observe(.value) { snapData in
            if let data = snapData.value as? String {
                completion(data)
            }
            
            
        }
    }
    func checkTorch(completion: @escaping(Bool) -> Void) {
        let path = "\(userCamPath())camName"
        databaseRef.child(path).observe(.value) { snapData in
            if let data = snapData.value as? Bool {
                completion(data)
            }
        }
    }
    
    func currentCamInfo(completion: @escaping () -> Void) {
        let path = userCamPath()
        print("currentCamInfo",path)
        databaseRef.child(path).observeSingleEvent(of: .value) { data in
            if data.value is [String:Any] {
                self.startSetting()
            } 
            else {self.creatCam()}
        }
        completion()
    }
        
    
    func currentCamInfo2(completion: @escaping(FirebaseCamList) -> Void) {
        let path = "PetCam/Users/\(userInfo.uid)/CamList/\(userDeviceID)/"
        print("currentCamInfo2 path", path)
        databaseRef.child(path).observe(DataEventType.value) { snapshot in
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
    
    func creatCam() {
        let path = userCamPath()
        let date = Int(Date().timeIntervalSince1970)

        let level = Int(batteryLevel*100)
        let status = currentCamBatteryState()
        guard let modelName = fbModel.deviceName else {
            print("StreamingVCModel creatCam modelName error")
            return}
        let value = ["camName": modelName, "hls":userDeviceID, "deviceModel":modelName, "deviceVersion":deviceVersion, "date":date, "batteryLevel":level, "torch":false, "position":1, "batteryState":status] as [String : Any]
        databaseRef.child(path).setValue(value)
//        setCamBatteryState()
    }
    func startSetting() {
        let path = userCamPath()
        let level = Int(batteryLevel*100)
        let date = Int(Date().timeIntervalSince1970)
        var state = ""
        var batteryState: UIDevice.BatteryState { UIDevice.current.batteryState }
        switch batteryState {
        case .unplugged, .unknown:
            state = "NotCharging"
        case .charging, .full:
            state = "Charging"
        @unknown default:
            print("Nothing")
        }
        let value = ["deviceVersion":deviceVersion, "date":date, "batteryLevel":level, "batteryState": state, "torch":false] as [String : Any]
        databaseRef.child(path).updateChildValues(value)
    }
    func setOnTorch() {
        let path = userCamPath() + "torch/"
        databaseRef.child(path).setValue(true)
    }
    func setOffTorch() {
        let path = userCamPath() + "torch/"
        databaseRef.child(path).setValue(false)
    }
    func setCamBatteryLevel(batteryLevel: Float) {
        let path = userCamPath() + "batteryLevel/"
        let level = Int(batteryLevel*100)
        databaseRef.child(path).setValue(level)
    }
    func setCamDate() {
        let date = Int(Date().timeIntervalSince1970)
        let path = userCamPath() + "date"
        databaseRef.child(path).setValue(date)
    }
    func currentCamBatteryState() -> String {
        var batteryState: UIDevice.BatteryState { UIDevice.current.batteryState }
        switch batteryState {
        case .unplugged, .unknown:
            return "NotCharging"
        case .charging, .full:
            return "Charging"
        @unknown default:
            return "NotCharging"
        }
        
    }

    func setCamBatteryState() {
        let path = userCamPath() + "batteryState/"
        
        var batteryState: UIDevice.BatteryState { UIDevice.current.batteryState }
        switch batteryState {
        case .unplugged, .unknown:
            databaseRef.child(path).setValue("NotCharging")
        case .charging, .full:
            databaseRef.child(path).setValue("Charging")
        @unknown default:
            print("Nothing")
        }
        
    }
    func currentPosition(completion: @escaping () -> Void) {
        let path = userCamPath() + "position"
        databaseRef.child(path).observe(DataEventType.value) { data in
            guard data.value is Double else {return}
            completion()
        }
    }
    func removeListener() {
        let path = userCamPath() + "position"
        databaseRef.child(path).removeAllObservers()
        databaseRef.child(userCamPath()).removeAllObservers()
        databaseRef.child("\(userCamPath())camName").removeAllObservers()
        databaseRef.child("\(userCamPath())torch").removeAllObservers()
    }
    func checkCameraPermission(){
       AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
           if granted {
               print("Camera: 권한 허용")
           } else {
               print("Camera: 권한 거부")
           }
       })
        AVCaptureDevice.requestAccess(for: .audio, completionHandler: { (granted: Bool) in
            if granted {
                print("Audio: 권한 허용")
            } else {
                print("Audio: 권한 거부")
            }
        })

    }
    func moveAlert(moveAction: UIAlertAction) -> UIAlertController {
//        let fbModel = FirebaseModel.fb
        let title = "모드를 변경하시겠습니까?"
        let message = ""
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        let signOut = UIAlertAction(title: "로그아웃", style: .cancel) { _ in fbModel.signOut() }
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        moveAction.setValue(UIColor(named: "MainGreen"), forKey: "titleTextColor")
        cancel.setValue(UIColor.lightGray, forKey: "titleTextColor")
        alert.addAction(moveAction)
        alert.addAction(cancel)
        return alert
    }
    
}
