//
//  SelectModeVC.swift
//  PetCam
//
//  Created by 양윤석 on 2/16/24.
//

import UIKit

class SelectModeVC: UIViewController {
    let moveView = MoveViewControllerModel()
    let urlModel = URLModel()
    let fbModel = FirebaseModel.fb
//    let watchCamListModel = WatchCamListModel()
    @IBOutlet weak var camModeBT: UIButton!
    @IBOutlet weak var watchModeBT: UIButton!
    
    @IBOutlet weak var testLabel: UILabel!
    @IBAction func moveCamMode(_ sender: Any) {
        let nextVC = moveView.moveToVC(storyboardName: "CamMode", className: "StreamingVC")
        fbModel.selectModeSave(value: "CamMode")
        self.present(nextVC, animated: true)
    }
    @IBAction func moveWatchMode(_ sender: Any) {
        let nextVC = moveView.moveToVC(storyboardName: "Main", className: "WatchTabbar")
        fbModel.selectModeSave(value: "WatchTabbar")
        self.present(nextVC, animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        uiSetting()
        fbModel.removeObseve()
        fbModel.updateUserInfo()
    }
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//            return .portrait
//    }
    
    func uiSetting() {
        self.view.backgroundColor = UIColor(named: "BackgroundColor")
        camModeBT.backgroundColor = UIColor(named: "MainGreen")
        watchModeBT.backgroundColor = UIColor(named: "MainGreen")
        camModeBT.layer.cornerRadius = 20
        camModeBT.setTitle("카메라 모드 \n 이 기기를 카메라로 사용할 수 있습니다.", for: .normal)
        watchModeBT.layer.cornerRadius = 20
        camModeBT.tintColor = .white
        watchModeBT.tintColor = .white
        camModeBT.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        watchModeBT.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        camModeBT.layer.shadowOpacity = 0.3
        watchModeBT.layer.shadowOpacity = 0.3
        camModeBT.layer.shadowRadius = 5
        watchModeBT.layer.shadowRadius = 5
        
        
        
    }
}
