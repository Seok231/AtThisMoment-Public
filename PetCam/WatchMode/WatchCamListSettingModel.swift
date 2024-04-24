//
//  WatchCamListSettingModel.swift
//  PetCam
//
//  Created by 양윤석 on 3/1/24.
//

import Foundation
import UIKit
import FirebaseDatabase

class WatchCamListSettingModel {
    let fbModel = FirebaseModel.fb
    let userInfo = UserInfo.info
    var databaseRef = Database.database().reference()
    func setAlert(camName: String) -> UIAlertController {
        let title = "카메라 이름"
        let message = "변경할 카메라 이름을 입력해 주세요."
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField { alert in
            alert.placeholder = camName
        }
        let save = UIAlertAction(title: "저장", style: .destructive) { save in
            if let text = alert.textFields?[0].text {
               print(text)
//                self.camNameLabel.text = text
                
            }
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        save.setValue(UIColor(named: "MainGreen"), forKey: "titleTextColor")
        cancel.setValue(UIColor.lightGray, forKey: "titleTextColor")
        alert.addAction(save)
        alert.addAction(cancel)
        return alert
    }
    func updateCamName(camName: String, deviceID: String) {
        let path = userInfo.creatUserChild() + "/CamList/\(deviceID)/camName"
        print(path)
        databaseRef.child(path).setValue(camName)
    }
    func removeCam(hls: String) {
        let path = userInfo.creatUserChild() + "/CamList/\(hls)"
        databaseRef.child(path).removeValue()
    }
    func batteryLabelSetting(level: Int?, state: String?) -> String {
        let df = "--%"
        guard let lv = level else{return df }
        if state == "Charging" {
            return "\(lv.description)% [충전중]"
        }
        return "\(lv.description)% [충전중 아님]"
        
    }
}
