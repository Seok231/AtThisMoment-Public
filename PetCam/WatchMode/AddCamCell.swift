//
//  AddCamCell.swift
//  PetCam
//
//  Created by 양윤석 on 4/14/24.
//

import UIKit

class AddCamCell: UITableViewCell {

    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        contentView.layer.cornerRadius = 10
//        layer.cornerRadius = 10
        backgroundColor = UIColor(named: "BackgroundColor")
        layer.shadowOpacity = 0.8
        layer.shadowOffset = CGSize(width: -2, height: 2)
        layer.shadowRadius = 3
//        layer.masksToBounds = true
        backgroundColor = .clear
        contentView.layer.cornerRadius = 10
        contentView.backgroundColor = UIColor(named: "WatchCellInfo")
        titleLabel.font = UIFont.boldSystemFont(ofSize: 15)
        titleLabel.textColor = UIColor(named: "FontColor")
        titleLabel.text = "등록된 기기가 없습니다."
        
        detailLabel.text = "CCTV로 사용할 기기에 같은 계정으로 로그인해 주세요."
        detailLabel.font = UIFont.boldSystemFont(ofSize: 10)
        detailLabel.textColor = UIColor(named: "FontColor")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    override func layoutSubviews() {
      super.layoutSubviews()
      contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
    }
    
}
