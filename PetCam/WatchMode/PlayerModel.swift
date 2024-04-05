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

class PlayerModel {
    var databaseRef = Database.database().reference()
    let fbModel = FirebaseModel.fb
    var camInfo: FirebaseCamList?
    let imageConf = UIImage.SymbolConfiguration(pointSize: 9, weight: .light)
    let labelFont = UIFont.boldSystemFont(ofSize: 13)
    let tintColor = UIColor.white
    func getCamPath(hls: String) -> String {
        let userID = fbModel.userID
        let path = "PetCam/Users/\(userID)/CamList/\(hls)/"
        return path
    }
    func setOnTorch(hls: String) {
        let path = getCamPath(hls: hls) + "torch/"
        databaseRef.child(path).setValue(true)
    }
    func setOffTorch(hls: String) {
        let path = getCamPath(hls: hls) + "torch/"
        databaseRef.child(path).setValue(false)
    }
}
