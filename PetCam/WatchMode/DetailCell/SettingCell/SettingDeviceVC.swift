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
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        tableView.backgroundColor = UIColor(named: "BackgroundColor")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "SettingDeviceCell", bundle: nil), forCellReuseIdentifier: "SettingDeviceCell")
        
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
        
        return cell
    }
    
    
}
