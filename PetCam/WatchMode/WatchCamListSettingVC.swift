//
//  WatchCamListSettingVC.swift
//  PetCam
//
//  Created by 양윤석 on 3/1/24.
//

import Foundation
import UIKit
import FirebaseDatabase

class WatchCamListSettingVC: UIViewController {

    @IBOutlet weak var removeCamBT: UIButton!
    @IBOutlet weak var camOnoffLabel: UILabel!
    @IBOutlet weak var camOnoffTitleLabel: UILabel!
    @IBOutlet weak var batteryLabel: UILabel!
    @IBOutlet weak var batteryTitleLabel: UILabel!
    @IBOutlet weak var deviceVersionLabel: UILabel!
    @IBOutlet weak var deviceVersionTitleLabel: UILabel!
    @IBOutlet weak var deviceModelTitleLabel: UILabel!
    @IBOutlet weak var deviceModelLabel: UILabel!
    @IBOutlet weak var camNameSettingBT: UIButton!
    @IBOutlet weak var camInfoView: UIView!
    @IBOutlet weak var camNameTitleLabel: UILabel!
    @IBOutlet weak var camNameLabel: UILabel!
    let viewModel = WatchCamListSettingModel()
    var watchCamModel = WatchCamListModel()
    let fbModel = FirebaseModel.fb
    var linkStatus: Bool?
    var camList: FirebaseCamList? {
        didSet {
            if let list = camList {
                camNameLabel.text = list.camName
                deviceModelLabel.text = list.deviceModel
                deviceVersionLabel.text = list.deviceVersion
                let battery = viewModel.batteryLabelSetting(level: list.batteryLevel, state: list.batteryState)
                if let status = linkStatus {
                    camOnoffLabel.text = status ? "온라인" : "오프라인"
                    batteryLabel.text = status ? battery : "--%"
                }
            }
        }
    }
    @IBAction func camNameSettingAction(_ sender: Any) {

        let title = "카메라 이름"
        let message = "변경할 카메라 이름을 입력해 주세요."
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField { alert in
            alert.placeholder = self.camList?.camName
        }
        let save = UIAlertAction(title: "저장", style: .destructive) { save in
            if let text = alert.textFields?[0].text {
               print(text)
                self.camNameLabel.text = text
                guard let deviceID = self.camList?.hls else {return}
                self.viewModel.updateCamName(camName: text, deviceID: deviceID)
            }
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        save.setValue(UIColor(named: "MainGreen"), forKey: "titleTextColor")
        cancel.setValue(UIColor.lightGray, forKey: "titleTextColor")
        alert.addAction(save)
        alert.addAction(cancel)
        self.present(alert, animated: true)

    }
    @IBAction func removeCam(_ sender: Any) {
        let alert = UIAlertController(title: "카메라 지우기", message: "카메라를 지우시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .destructive) { action in
          //취소처리...
        })
        alert.addAction(UIAlertAction(title: "확인", style: .default) { action in
            if let camList = self.camList {
                self.viewModel.removeCam(hls: camList.hls)
                self.dismiss(animated: true)
            }
        })
        self.present(alert, animated: true, completion: nil)

    }
    
    
    override func viewDidLoad() {
//        let bold10 = UIFont.boldSystemFont(ofSize: 10)
        let bold15 = UIFont.boldSystemFont(ofSize: 15)
        camInfoView.backgroundColor = UIColor(named: "MainGreen")
        camInfoView.layer.cornerRadius = 10
        camNameTitleLabel.text = "카메라 이름"
        deviceModelTitleLabel.text = "카메라 모델"
        deviceVersionTitleLabel.text = "카메라 버전"
        batteryTitleLabel.text = "배터리"
        camOnoffTitleLabel.text = "상태"
        batteryLabel.text = "--%"
        camOnoffLabel.text = "오프라인"
        
        camNameSettingBT.setImage(UIImage(named: "pencil"), for: .normal)
        camNameSettingBT.setTitle("", for: .normal)
        
        removeCamBT.backgroundColor = .darkGray
        removeCamBT.setTitle("카메라 지우기", for: .normal)
        removeCamBT.setTitleColor(.white, for: .normal)
        removeCamBT.tintColor = .lightGray
        removeCamBT.layer.cornerRadius = 10
        removeCamBT.titleLabel?.font = bold15
//        camNameLabel.font = UIFont.boldSystemFont(ofSize: 10)
        camOnoffTitleLabel.font = bold15
        camOnoffLabel.font = bold15
        camNameTitleLabel.font = bold15
        deviceVersionTitleLabel.font = bold15
        deviceModelTitleLabel.font = bold15
        batteryTitleLabel.font = bold15
        batteryLabel.font = bold15
//        camNameLabel.font = bold15
        deviceModelLabel.font = bold15
        deviceVersionLabel.font = bold15
        camNameSettingBT.tintColor = .gray
//        deviceModelLabel.textColor = .darkGray
//        deviceVersionLabel.textColor = .darkGray
        
    }
}
