//
//  NoticeCell.swift
//  PetCam
//
//  Created by 양윤석 on 3/12/24.
//

import UIKit

class NoticeCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = UIColor(named: "BackgroundColor")
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
//        titleLabel.textColor = .black
        
        dateLabel.font = UIFont.boldSystemFont(ofSize: 10)
        dateLabel.textColor = .darkGray
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
