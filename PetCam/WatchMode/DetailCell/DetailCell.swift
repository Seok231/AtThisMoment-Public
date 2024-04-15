//
//  DetailCell.swift
//  PetCam
//
//  Created by 양윤석 on 4/14/24.
//

import UIKit

class DetailCell: UITableViewCell {

    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var detailLabel: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
