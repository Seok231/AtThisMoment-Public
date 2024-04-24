//
//  DetailCell.swift
//  PetCam
//
//  Created by 양윤석 on 4/14/24.
//

import UIKit

class DetailCell: UITableViewCell {

    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var detailLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor(named: "BackgroundColor")
        iconView.tintColor = UIColor(named: "FontColor")
        detailLabel.textColor = UIColor(named: "FontColor")
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
