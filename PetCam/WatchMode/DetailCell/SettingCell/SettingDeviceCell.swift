//
//  SettingDeviceCell.swift
//  PetCam
//
//  Created by 양윤석 on 4/14/24.
//

import UIKit

class SettingDeviceCell: UITableViewCell {

    @IBOutlet weak var deviceVersionLabel: UILabel!
    @IBOutlet weak var deviceModelNameLabel: UILabel!
    @IBOutlet weak var deviceNameLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = UIColor(named: "BackgroundColor")
        contentView.layer.cornerRadius = 5
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: -1, height: 1)
        layer.shadowRadius = 2
        selectionStyle = .none
        let titleFont = UIFont.boldSystemFont(ofSize: 20)
        let subFont = UIFont.boldSystemFont(ofSize: 10)
        deviceNameLabel.font = titleFont
        deviceModelNameLabel.font = subFont
        deviceVersionLabel.font = subFont
        deviceNameLabel.textColor = UIColor(named: "FontColor")
        deviceModelNameLabel.textColor = .gray
        deviceVersionLabel.textColor = .gray
        
        
        
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
