//
//  File.swift
//  PetCam
//
//  Created by 양윤석 on 2/16/24.
//

import Foundation
import UIKit
import Combine

class WatchCamListVC: UIViewController {
    
    @IBOutlet weak var camListTableView: UITableView!
    let urlModel = URLModel()
    let nvModel = NavigationModel()
    let moveView = MoveViewControllerModel()
    let viewModel = WatchCamListModel()
    let fbModel = FirebaseModel.fb
    var linkStatusDict = [String: Bool]()
    var cancellables: Set<AnyCancellable> = []
    let refreshControl = UIRefreshControl()
    let userDeviceID = UIDevice.current.identifierForVendor!.uuidString
    override func viewWillDisappear(_ animated: Bool) {
        print("viewWillDisappear")
        fbModel.removeObseve()
    }
    override func viewWillAppear(_ animated: Bool) {
        print("Will")
    }
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor(named: "BackgroundColor")
        settingTableView()
        navigationSet()
        fbModel.updateCheckCam{
            self.camListTableView.reloadData()
        }
        fbModel.camListUpdate()
        fbModel.$camList.sink { list in
            self.camListTableView.reloadData()
        }.store(in: &cancellables)
        initRefresh()
        print("deviceId", userDeviceID)
    }
    func initRefresh() {
        refreshControl.addTarget(self, action: #selector(refreshTable(refresh:)), for: .valueChanged)
        refreshControl.tintColor = UIColor(named: "MainGreen")
        camListTableView.refreshControl = refreshControl
    }
    @objc func refreshTable(refresh: UIRefreshControl) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print(self.fbModel.camList)
            self.camListTableView.reloadData()
            
            refresh.endRefreshing()
        }
    }
    
    func navigationSet() {
        let appearance = nvModel.navigationBaseSet()
        let changeCamModeBT =  self.navigationItem.makeSFSymbolButton(self, action: #selector(self.moveToCamMode), symbolName: "arrow.triangle.2.circlepath.camera.fill")
        self.navigationItem.rightBarButtonItem = changeCamModeBT
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.navigationItem.title = "모니터링"
    }
    @objc func moveToCamMode() {
        let vc = moveView.moveToVC(storyboardName: "CamMode", className: "StreamingVC")
        self.present(vc, animated: true)
    }
    func settingTableView() {
        camListTableView.backgroundColor = UIColor(named:"BackgroundColor")
        camListTableView.dataSource = self
        camListTableView.delegate = self
        camListTableView.register(UINib(nibName: "WatchTableCell", bundle: nil), forCellReuseIdentifier: "WatchTableCell")
        camListTableView.separatorStyle = .none
        camListTableView.layer.shadowColor = UIColor.black.cgColor //색상
        camListTableView.layer.shadowOpacity = 0.3 //alpha값
        camListTableView.layer.shadowRadius = 5 //반경
        camListTableView.layer.shadowOffset = CGSize(width: 0, height: 10)
    }

}

extension WatchCamListVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        250
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fbModel.camList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = camListTableView.dequeueReusableCell(withIdentifier: "WatchTableCell", for: indexPath) as! WatchTableCell
        let fb = fbModel.camList[indexPath.row]
        let vm = viewModel
        cell.batteryStatusBT.tintColor = UIColor(named: "FontColor")
        let status = vm.checkCam(hls: fb.hls)
        let batteryLevel = vm.batteryLevelString(level: fb.batteryLevel, status: status)
        let batteryImage = vm.batteryImage(level: fb.batteryLevel, status: fb.batteryState, linkStatus: status)
        let camStatus = status ? "온라인" : "오프라인"
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.camNameLabel.text = fb.camName
        cell.settingBT.tag = indexPath.row
        
        cell.settingBT.addTarget(self, action: #selector(cellSetting(sender:)), for: .touchUpInside)
        
//        cell.thumbnailView.isEnabled = status
//        cell.infoView.isUserInteractionEnabled = status
        
        cell.camStatusBT.tintColor = status ? vm.statuseGreenColor : vm.statuseRedColor
        cell.camStatusBT.setTitle(camStatus, for: .normal)
        cell.offlineLabel.isHidden = status
//        cell.thumbnailView.image = status ? UIImage(named: "testImage") : nil
        cell.thumbnailView.backgroundColor = status ? UIColor(named: "MainGreen") : UIColor(named: "CamListCell")
        
        cell.batteryStatusBT.setImage(batteryImage, for: .normal)
        cell.batteryStatusBT.setTitle(batteryLevel, for: .normal)
        return cell
    }

    @objc func cellSetting(sender: UIButton) {
        let list = fbModel.camList[sender.tag]
        guard let settingVC = self.storyboard?.instantiateViewController(withIdentifier: "WatchCamListSettingVC") as? WatchCamListSettingVC else { return }
        
        settingVC.modalPresentationStyle = .pageSheet
        self.present(settingVC, animated: true, completion: nil)
        settingVC.linkStatus = viewModel.linkStatusDict[list.hls]
        settingVC.camList = list
//        self.navigationController?.pushViewController(settingVC, animated: true)
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fb = fbModel.camList[indexPath.row]
        let vm = viewModel
        let status = vm.checkCam(hls: fb.hls)
        
        if status {
            guard let playLiveVC = self.storyboard?.instantiateViewController(withIdentifier: "CamPlayerVC") as? CamPlayerVC else { return }
            
            playLiveVC.modalTransitionStyle = .crossDissolve
            playLiveVC.modalPresentationStyle = .overFullScreen
            self.present(playLiveVC, animated: true, completion: nil)
            
            playLiveVC.camInfo = fbModel.camList[indexPath.row]
            playLiveVC.listIndex = indexPath.row
            
        }

    }
    
}
