//
//  WatchCamListModel.swift
//  PetCam
//
//  Created by 양윤석 on 2/27/24.
//

import Foundation
import FirebaseDatabase
import UIKit
import Combine
import HaishinKit


class WatchCamListModel: ObservableObject {
    let urlModel = URLModel()
    let fbModel = FirebaseModel.fb
    var linkStatusDict = [String: Bool]()
    var cancellables: Set<AnyCancellable> = []
    var databaseRef = Database.database().reference()
    
    // cell
    let imageConf = UIImage.SymbolConfiguration(pointSize: 13, weight: .light)
    let infoColor = UIColor(named: "WatchCellInfo")
    let thumbnailColor = UIColor(named: "CamListCell")
    let statuseRedColor = UIColor(named: "CamStatusRed")
    let statuseGreenColor = UIColor(named: "CamStatusGreen")

    func checkCam(status: Int) -> Bool {
        if status == 1 { return true } else { return false }
    }
    
    func batteryLevelString(level: Int?, status: Bool) -> String {
        let df = "--%"
        guard let lv = level else{return df}
        if status {
            return lv.description + "%"
        } else {
            return "--%"
        }
        
    }
    
    func batteryImage(level: Int?, status: String?, linkStatus: Bool) -> UIImage {
        let df = UIImage(systemName: "battery.50", withConfiguration: imageConf)!
        if linkStatus == false {
            return UIImage(systemName: "battery.50", withConfiguration: imageConf)!
        }
        guard let lv = level else {return df}
        
        if status == "Charging" {
            return UIImage(systemName: "battery.100.bolt", withConfiguration: imageConf)!
        } else {
            switch lv {
            case 76...100:
                return UIImage(systemName: "battery.100", withConfiguration: imageConf)!
            case 51...75:
                return UIImage(systemName: "battery.75", withConfiguration: imageConf)!
            case 26...50:
                return UIImage(systemName: "battery.50", withConfiguration: imageConf)!
            default :
                return UIImage(systemName: "battery.25", withConfiguration: imageConf)!
            }
        }
    }
    
//    func updateListStatus(completion: @escaping () -> Void) {
//        fbModel.camListUpdate {
//            self.checkLinkStatus {
//                completion()
//            }
//        }
//    }
//    func checkLinkStatus(completion: @escaping () -> Void) {
//        
//        for link in fbModel.camList {
//            let url = urlModel.inputURL(hls: link.hls)
//            let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
//                guard let self = self else { return }
//                
//                if error != nil {
////                    print("Error checking link:", error)
//                    self.linkStatusDict[link.hls] = false
//                } else {
//                    if let httpResponse = response as? HTTPURLResponse {
//                        let statusCode = httpResponse.statusCode
//                        self.linkStatusDict[link.hls] = (statusCode == 200)
//                    } else {
//                        self.linkStatusDict[link.hls] = false
//                    }
//                }
//                DispatchQueue.main.async {
//                    completion()
//                }
//            }
//            task.resume()
//        }
//    }
//    

//    func srtToBool(srt: Int) -> Bool {
//        if srt == 1 {
//            return true
//        } else {
//            return false
//        }
//    }
    



    
}

    
    

