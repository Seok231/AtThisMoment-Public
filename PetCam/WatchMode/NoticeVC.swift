//
//  NoticeVC.swift
//  PetCam
//
//  Created by 양윤석 on 3/12/24.
//

import Foundation
import UIKit

class NoticeVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    let nvModel = NavigationModel()
    let viewModel = NoticeModel()
    let moveModel = MoveViewControllerModel()
    let refreshControl = UIRefreshControl()
    override func viewDidLoad() {
        navigationSet()
        initRefresh()
        tableView.register(UINib(nibName: "NoticeCell", bundle: nil), forCellReuseIdentifier: "NoticeCell")
        tableView.dataSource = self
        tableView.delegate = self
        viewModel.currentNotices {
            self.tableView.reloadData()
        }
        tableView.backgroundColor = UIColor(named: "BackgroundColor")

    }
    
    func initRefresh() {
        refreshControl.addTarget(self, action: #selector(refreshTable(refresh:)), for: .valueChanged)
        refreshControl.tintColor = UIColor(named: "MainGreen")
        tableView.refreshControl = refreshControl
    }
    @objc func refreshTable(refresh: UIRefreshControl) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.viewModel.currentNotices {
                self.tableView.reloadData()
            }
            
            
            refresh.endRefreshing()
        }
    }
    func navigationSet() {
        let appearance = nvModel.navigationBaseSet()
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.navigationItem.title = "공지사항"
        self.navigationController?.navigationBar.tintColor = UIColor(named: "FontColor")
    }
}

extension NoticeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.noticeList.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoticeCell", for: indexPath) as! NoticeCell
        let list = viewModel.noticeList[indexPath.row]
        cell.titleLabel.text = list.title
        cell.dateLabel.text = list.titleDate
        cell.selectionStyle = .none
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vc = moveModel.moveToVC(storyboardName: "Main", className: "NoticeInfoVC") as? NoticeInfoVC else {return}
        
        self.navigationController?.pushViewController(vc, animated: true)
        vc.notice = viewModel.noticeList[indexPath.row]
    }
    
    
}
