//
//  SettingDeviceVC.swift
//  PetCam
//
//  Created by 양윤석 on 4/14/24.
//

import Foundation
import UIKit

class SettingDeviceVC: UIViewController {
    let fbModel = FirebaseModel.fb
    @IBOutlet weak var deviceCountZeroLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        tableView.backgroundColor = UIColor(named: "BackgroundColor")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "SettingDeviceCell", bundle: nil), forCellReuseIdentifier: "SettingDeviceCell")
        deviceCountZeroLabel.text = "등록된 기기가 없습니다."
        deviceCountZeroLabel.font = UIFont.boldSystemFont(ofSize: 20)
        deviceCountZeroLabel.textColor = .gray
        if fbModel.camList.count == 0 {
            deviceCountZeroLabel.isHidden = false
        } else {
            deviceCountZeroLabel.isHidden = true
        }
        
    }
}
extension SettingDeviceVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fbModel.camList.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingDeviceCell", for: indexPath) as! SettingDeviceCell
        let fb =  fbModel.camList[indexPath.row]
        cell.deviceNameLabel.text = fb.camName
        cell.deviceModelNameLabel.text = fb.deviceModel
        cell.deviceVersionLabel.text = fb.deviceVersion
        
        return cell
    }
        
}


