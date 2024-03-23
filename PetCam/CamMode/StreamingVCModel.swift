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

class StreamingVCModel {
    
    let fbModel = FirebaseModel.fb
    var databaseRef = Database.database().reference()
    var storageRef = Storage.storage().reference()
    let userDeviceID = UIDevice.current.identifierForVendor!.uuidString
    let userID = Auth.auth().currentUser?.uid ?? ""
    let userName = Auth.auth().currentUser?.displayName ?? ""
    let userEmail = Auth.auth().currentUser?.email ?? ""
    let deviceVersion = UIDevice.current.systemVersion
    var pushURL = "rtmp://220.121.93.66:1935/live"
    var pushID = "ch1_s1"
    @Published var camInfo = [:]
    var cancellables: Set<AnyCancellable> = []
    var deviceModelName: String {
        let selName = "_\("deviceInfo")ForKey:"
        let selector = NSSelectorFromString(selName)
//        let test : String = UIDevice.current.model
//        print(test)
        if UIDevice.current.responds(to: selector) { // [옵셔널 체크 실시]
            let name = String(describing: UIDevice.current.perform(selector, with: "marketing-name").takeRetainedValue())
            return name
        }
        return ""
    }
    

    
    func deviceName() -> String {
        let device = UIDevice.current
        let selName = "_\("deviceInfo")ForKey:"
        let selector = NSSelectorFromString(selName)
        if device.responds(to: selector) { // [옵셔널 체크 실시]
            let name = String(describing: device.perform(selector, with: "marketing-name").takeRetainedValue())
            return name
        }
        return ""
    }
    func userCamPath() -> String {
        let path = "PetCam/Users/\(userID)/CamList/\(userDeviceID)/"
        return path
    }
    func currentCamInfo(batteryLevel: Float, batteryState: UIDevice.BatteryState) {
        let path = "PetCam/Users/\(userID)/CamList/\(userDeviceID)/"
        databaseRef.child(path).observeSingleEvent(of: .value) { data in
            if data.value is NSDictionary {
                self.setCamBatteryLevel(batteryLevel: batteryLevel)
                self.setCamBatteryState(batteryState: batteryState)
                self.setCamDate()
            } else {
                self.creatCam(batteryLevel: batteryLevel, batteryState: batteryState, deviceModelName: self.deviceModelName, camName: self.deviceModelName)
            }
            
        }
    }
    
    func currentCamInfo2(batteryLevel: Float, batteryState: UIDevice.BatteryState, completion: @escaping () -> Void) {
        let path = "PetCam/Users/\(userID)/CamList/\(userDeviceID)/"
        databaseRef.child(path).observe(DataEventType.value) { data in
            guard let snapData = data.value as? [String:Any]  else {
                self.creatCam(batteryLevel: batteryLevel, batteryState: batteryState, deviceModelName: self.deviceModelName, camName: self.deviceModelName)
                return }
            self.setCamBatteryLevel(batteryLevel: batteryLevel)
            self.setCamBatteryState(batteryState: batteryState)
            self.setCamDate()
            self.camInfo = snapData
            completion()
        }
    }
    
    func creatCam(batteryLevel: Float, batteryState: UIDevice.BatteryState, deviceModelName: String, camName: String) {
        let path = userCamPath()
        let date = Int(Date().timeIntervalSince1970)
        let value = ["camName": deviceModelName, "hls":userDeviceID, "deviceModel":deviceModelName, "deviceVersion":deviceVersion, "date":date] as [String : Any]
        databaseRef.child(path).setValue(value)
        setCamBatteryLevel(batteryLevel: batteryLevel)
        setCamBatteryState(batteryState: batteryState)
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
    func setCamBatteryState(batteryState: UIDevice.BatteryState) {
        let path = userCamPath() + "batteryState/"
        print("batteryState", batteryState)
        switch batteryState {
        case .unplugged, .unknown:
            print("Not charging")
            databaseRef.child(path).setValue("NotCharging")
        case .charging, .full:
            print("Charging")
            databaseRef.child(path).setValue("Charging")
        @unknown default:
            print("Nothing")
        }
        
    }
    func currentPosition(completion: @escaping () -> Void) {
        let path = userCamPath() + "position"
        print(path)
        databaseRef.child(path).observe(DataEventType.value) { data in
            guard let snapData = data.value as? Double else {return}
            print(snapData)
            completion()
        }
    }
    func removeListener() {
        let path = userCamPath() + "position"
        databaseRef.child(path).removeAllObservers()
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
    
}
