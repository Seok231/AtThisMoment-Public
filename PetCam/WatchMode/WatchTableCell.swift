//
//  WatchTableCell.swift
//  PetCam
//
//  Created by 양윤석 on 2/17/24.
//

import UIKit

class WatchTableCell: UITableViewCell {

    @IBOutlet weak var offlineLabel: UILabel!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var settingBT: UIButton!
    @IBOutlet weak var batteryStatusBT: UIButton!
//    @IBOutlet weak var onOfLabel: UILabel!
    @IBOutlet weak var camStatusBT: UIButton!
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var camNameLabel: UILabel!
    let viewModel = WatchCamListModel()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
//        contentView.backgroundColor = .gray
        layer.masksToBounds = false
        layer.shadowOpacity = 0.8
        layer.shadowOffset = CGSize(width: -2, height: 2)
        layer.shadowRadius = 3
        layer.masksToBounds = true
        layer.cornerRadius = 10
        contentView.layer.cornerRadius = 10
        infoView.backgroundColor = UIColor(named: "WatchCellInfo")
        
        let imageConf = viewModel.imageConf
        let camStatusImage = UIImage(systemName: "circlebadge.fill", withConfiguration: imageConf)
        let labelFont = UIFont.boldSystemFont(ofSize: 13)
        camStatusBT.setImage(camStatusImage, for: .normal)
        camStatusBT.setTitle("오프라인", for: .normal)
        camStatusBT.setTitleColor(UIColor(named: "FontColor"), for: .normal)
        camStatusBT.tintColor = UIColor(named: "CamStatusRed")
        camStatusBT.isUserInteractionEnabled = false
        camStatusBT.titleLabel?.font = labelFont
        
        camNameLabel.font = labelFont
//        onOfLabel.font = UIFont.boldSystemFont(ofSize: 10)
//        onOfLabel.text = "오프라인"
        offlineLabel.text = "오프라인"
        offlineLabel.font = labelFont
        
        batteryStatusBT.setTitle("--%", for: .normal)
        batteryStatusBT.setImage(UIImage(systemName: "battery.50", withConfiguration: imageConf), for: .normal)
        batteryStatusBT.tintColor = UIColor(named: "FontColor")
        batteryStatusBT.titleLabel?.font = labelFont
        settingBT.setImage(UIImage(systemName: "gearshape.circle"), for: .normal)
        settingBT.setTitle("", for: .normal)
        settingBT.tintColor = UIColor(named: "FontColor")
        
        thumbnailView.backgroundColor = UIColor(named: "CamListCell")
//        thumbnailView.image = UIImage(named: "testImage")
        thumbnailView.contentMode = .scaleAspectFill


    }
    override func prepareForReuse() {
        batteryStatusBT.tintColor = UIColor(named: "FontColor")
    }
    override func layoutSubviews() {
      super.layoutSubviews()
      contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
    }

}
