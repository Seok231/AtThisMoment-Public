//
//  NoticeVC.swift
//  PetCam
//
//  Created by 양윤석 on 3/12/24.
//

import Foundation
import UIKit
import SafariServices

class NoticeVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    let nvModel = NavigationModel()
    let viewModel = NoticeModel()
    let moveModel = MoveViewControllerModel()
    let refreshControl = UIRefreshControl()
    override func viewDidLoad() {
        navigationSet()
        setTableView()

        viewModel.currentNotices {
            print("viewModel.currentNotices")
            self.tableView.reloadData()
        }
    }
    
    func setTableView() {
        initRefresh()
        tableView.register(UINib(nibName: "NoticeCell", bundle: nil), forCellReuseIdentifier: "NoticeCell")
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor(named: "BackgroundColor")
        tableView.separatorStyle = .none
        tableView.layer.shadowColor = UIColor.black.cgColor
        tableView.layer.shadowOpacity = 0.3 //alpha값
        tableView.layer.shadowRadius = 5 //반경
        tableView.layer.shadowOffset = CGSize(width: 0, height: 10)
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
        self.navigationController?.navigationBar.tintColor = UIColor(named: "MainGreen")
    }
}

extension NoticeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.noticeList.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        260
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoticeCell", for: indexPath) as! NoticeCell
        let list = viewModel.noticeList[indexPath.row]
        if indexPath.row == 0 {
            let image = UIImage(named: "settingImage")
            cell.thumbnailView.image = image
        } else {
            let image = UIImage(named: "mainImage")
            cell.thumbnailView.image = image
        }

        
        cell.titleLabel.text = list.title
//        cell.dateLabel.text = list.titleDate
        cell.selectionStyle = .none
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let stringURL = viewModel.noticeList[indexPath.row].url
        guard let url = URL(string: stringURL) else { return }
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }
    
    
}
