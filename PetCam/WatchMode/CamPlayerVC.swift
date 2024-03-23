//
//  CamPlayerVC.swift
//  PetCam
//
//  Created by 양윤석 on 2/16/24.
//

import Foundation
import AVFoundation
import UIKit
import AVKit
import Combine

class CamPlayerVC: UIViewController {
    var timer: Timer?
    var tapEventBool = true
    var urlModel = URLModel()
    let fbModel = FirebaseModel.fb
    let moveModel = MoveViewControllerModel()

    var cancellables: Set<AnyCancellable> = []
    private var volumeBool = false
    private var player = AVPlayer()
    private var playerLayer = AVPlayerLayer()
    private var pipPlayerController: AVPictureInPictureController?
    private var playerController = AVPlayerViewController()
    var camInfo: FirebaseCamList? {
        didSet {
            guard let list = camInfo else {return}
            settingPlayerURL(hls: list.hls)
        }
    }
    var listIndex: Int? {
        didSet {
            guard let index = listIndex else {return}
            fbModel.$camList.sink { list in
                self.camNameLabel.text = list[index].camName
                self.batteryLevelLabel.text = list[index].batteryLevel.description + "%"
            }.store(in: &cancellables)
        }
    }
    
    @IBOutlet weak var batteryLevelLabel: UILabel!
    @IBOutlet weak var bottomInfoView: UIView!
    @IBOutlet weak var topInfoView: UIView!
    @IBOutlet weak var volumeBT: UIButton!
    @IBOutlet weak var changePositionBT: UIButton!
    @IBOutlet weak var camNameLabel: UILabel!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var backBT: UIButton!
    @IBOutlet weak var fullModeBT: UIButton!
    @IBAction func backAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    @IBAction func volumeAction(_ sender: Any) {
        if volumeBool {
            player.volume = 0
            volumeBool.toggle()
            volumeBT.setImage(UIImage(systemName: "speaker.slash.fill"), for: .normal)
        } else {
            player.volume = 2
            volumeBool.toggle()
            volumeBT.setImage(UIImage(systemName: "speaker.wave.3.fill"), for: .normal)
        }
    }
    @IBAction func rotation(_ sender: Any) {
        // 현재의 회전 각도 가져오기
        let currentAngle = atan2(playerLayer.transform.m12, playerLayer.transform.m11)
        
        // 90도 회전
        let rotationAngle = currentAngle + .pi / 2
        
        // 회전 애니메이션 적용
        UIView.animate(withDuration: 0.3) {
            self.playerLayer.transform = CATransform3DMakeRotation(rotationAngle, 0, 0, 1)
            self.playerLayer.frame = self.playerView.bounds
        }

    }

    @IBAction func changePosition(_ sender: Any) {
        if let list = camInfo {
            fbModel.changePosition(hls: list.hls)
        }
    }
    
    override func viewDidLoad() {
        layoutSetting()
        playViewInfoTogle()
//        setPlayer()
    }
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    override func viewWillDisappear(_ animated: Bool) {
//        connection.close()
//        stream.close()
    }

    
//    func setPlayer() {
//        stream = SRTStream(connection: connection)
//        hkView = MTHKView(frame: playerView.bounds)
//        hkView.videoGravity = AVLayerVideoGravity.resizeAspect
//        hkView.attachStream(stream)
//        
//        playerView.addSubview(hkView)
//        hkView.transform = CGAffineTransform(scaleX: -1, y: 1)
//        hkView.transform = CGAffineTransform(scaleX: 1, y: -1)
//        stream.play()
//        print("fps",stream.currentFPS)
//        
//
//    }
    private func settingPlayerURL(hls: String) {
        print(urlModel.playerItem(hls: hls))
        player.replaceCurrentItem(with: urlModel.playerItem(hls: hls))
        playerLayer.player = player
        playerLayer.frame = playerView.bounds
        playerView.layer.addSublayer(playerLayer)
        player.play()
        player.volume = 0
        if player.timeControlStatus != .paused {
            print("pause")
        }
    }
    
    @objc func playViewTap(sender: UITapGestureRecognizer) {
        playViewInfoTogle()
    }

    func playViewInfoTogle() {
        if tapEventBool { 
            tapEventTrue()
        } else {
            tapEventFalse()
        }
    }
    func tapEventTrue() {
        UIView.animate(withDuration: 0.15, animations: {
            self.topInfoView.layer.opacity = 1.0
            self.bottomInfoView.layer.opacity = 1.0
        })
        var count = 0
        timer = Timer(timeInterval: 1, repeats: true, block: { _ in
            count += 1
            if self.tapEventBool == false, count > 4 {
                self.playViewInfoTogle()
            }
        })
        RunLoop.current.add(timer!, forMode: .common)
        tapEventBool = false
    }
    
    func tapEventFalse() {
        
        timer?.invalidate()
        UIView.animate(withDuration: 0.15, animations: {
            self.topInfoView.layer.opacity = 0
            self.bottomInfoView.layer.opacity = 0
        })
        self.tapEventBool = true
        
    }
    
    func layoutSetting() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playViewTap(sender: )))
        let btGroundColor = UIColor.mainGreen
        playerView.addGestureRecognizer(tapGesture)
        playerView.backgroundColor = .black
        self.view.backgroundColor = .black
        
//        fullModeBT.setImage(UIImage(systemName: "plus.viewfinder"), for: .normal)

        backBT.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        backBT.setTitle("", for: .normal)
        backBT.tintColor = .white
        fullModeBT.setTitle("", for: .normal)
        fullModeBT.setImage(UIImage(systemName: "rotate.right.fill"), for: .normal)
        fullModeBT.tintColor = .white
//        fullModeBT.backgroundColor = btGroundColor
//        fullModeBT.layer.cornerRadius = fullModeBT.layer.frame.width/2
        camNameLabel.font = UIFont.boldSystemFont(ofSize: 30)
        camNameLabel.textColor = .white
        changePositionBT.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
//        changePositionBT.setTitle("카메라 변경", for: .normal)
        changePositionBT.tintColor = .white
//        changePositionBT.backgroundColor = btGroundColor
//        changePositionBT.layer.cornerRadius = changePositionBT.layer.frame.width / 2
        
        volumeBT.setImage(UIImage(systemName: "speaker.slash.fill"), for: .normal)
        volumeBT.tintColor = .white
        volumeBT.setTitle("", for: .normal)
//        volumeBT.backgroundColor = btGroundColor
//        volumeBT.layer.cornerRadius = volumeBT.layer.frame.width / 2
//        volumeBT.contentVerticalAlignment = .bottom
        
        batteryLevelLabel.text = "--%"
        batteryLevelLabel.font = UIFont.boldSystemFont(ofSize: 20)
        batteryLevelLabel.textColor = .white
        
        topInfoView.layer.backgroundColor = (UIColor.black.cgColor).copy(alpha: 0.5)
        bottomInfoView.layer.backgroundColor = (UIColor.black.cgColor).copy(alpha: 0.5)
//        changePositionBT.semanticContentAttribute = .unspecified
    }

}

