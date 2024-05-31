//
//  NoticeCell.swift
//  PetCam
//
//  Created by 양윤석 on 3/12/24.
//

import UIKit

class NoticeCell: UITableViewCell {

    
    @IBOutlet weak var sideBarView: UIView!
    @IBOutlet weak var thumbnailView: UIImageView!
//    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        self.backgroundColor = UIColor(named: "BackgroundColor")
        self.backgroundColor = .clear
        layer.shadowOpacity = 0.8
        layer.shadowOffset = CGSize(width: -2, height: 2)
        layer.shadowRadius = 3
        layer.masksToBounds = true
        layer.cornerRadius = 10
        contentView.layer.cornerRadius = 10
        
        sideBarView.backgroundColor = UIColor(named: "CamListCell")
        titleLabel.font = UIFont.boldSystemFont(ofSize: 15)
//        dateLabel.font = UIFont.boldSystemFont(ofSize: 10)
//        dateLabel.textColor = .darkGray
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 10, left: 13, bottom: 10, right: 13))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
