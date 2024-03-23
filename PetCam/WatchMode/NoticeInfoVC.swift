//
//  NoticeInfoVC.swift
//  PetCam
//
//  Created by 양윤석 on 3/12/24.
//

import Foundation
import UIKit

class NoticeInfoVC: UIViewController {
    
    
    @IBOutlet weak var titleLineView: UIImageView!
    @IBOutlet weak var noticeTextView: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    var notice: NoticeList?
    let nvModel = NavigationModel()
    override func viewDidLoad() {
        
        self.view.backgroundColor = UIColor(named: "BackgroundColor")
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 30)
        dateLabel.font = UIFont.boldSystemFont(ofSize: 10)
        noticeTextView.font = UIFont.boldSystemFont(ofSize: 17)
        titleLineView.backgroundColor = .lightGray
        titleLineView.layer.opacity = 0.3
        dateLabel.textColor = .darkGray
//        self.view.backgroundColor = .lightGray
//        self.view.layer.opacity = 0.4
        navigationController?.navigationBar.topItem?.title = "공지사항"
        noticeTextView.isEditable = false
        noticeTextView.backgroundColor = UIColor(named: "BackgroundColor")
        settingNotice()
    }
    func navigationSet() {
        let appearance = nvModel.navigationBaseSet()
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.navigationItem.title = "공지사항"
    }
    func settingNotice() {
        guard let list = notice else {return}
        print(list)
        titleLabel.text = list.title
        dateLabel.text = list.date.description
        noticeTextView.text = list.notice
    }
}
