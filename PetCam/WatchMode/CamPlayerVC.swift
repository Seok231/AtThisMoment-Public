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
import HaishinKit
import SRTHaishinKit
import Lottie


class CamPlayerVC: UIViewController {
    @IBOutlet weak var torchBT: UIButton!
    @IBOutlet weak var loadingBackView: UIView!
    @IBOutlet weak var batteryLevelBT: UIButton!
    @IBOutlet weak var bottomInfoView: UIView!
    @IBOutlet weak var topInfoView: UIView!
    @IBOutlet weak var volumeBT: UIButton!
    @IBOutlet weak var changePositionBT: UIButton!
    @IBOutlet weak var camNameLabel: UILabel!
    @IBOutlet weak var playerView: UIImageView!
    @IBOutlet weak var backBT: UIButton!
    @IBOutlet weak var fullModeBT: UIButton!
    var timer: Timer?
    var tapEventBool = false
    var torchBool = false
    var urlModel = URLModel()
    let fbModel = FirebaseModel.fb
    let moveModel = MoveViewControllerModel()
    let viewModel = PlayerModel()
    var stream: SRTStream! = nil
    lazy var connection = SRTConnection()
    var cancellables: Set<AnyCancellable> = []
    var timerCount = 0
    var loadingView: LottieAnimationView!
    private var volumeBool = false
//    private var player = AVPlayer()
//    private var playerLayer = AVPlayerLayer()
//    private var pipPlayerController: AVPictureInPictureController?
//    private var playerController = AVPlayerViewController()
    var camInfo: FirebaseCamList? {
        didSet {
            guard let list = camInfo else {return}
//            settingPlayerURL(hls: list.hls)
            setPlayer(hls: list.hls)
        }
    }
    var listIndex: Int? {
        didSet {
            guard let index = listIndex else {return}
            fbModel.$camList.sink { list in
                if list.count == 0 { print("count - 0")
                    return
                }
                self.viewModel.camInfo = list[index]
                guard let cam = self.viewModel.camInfo else {return}
                self.changedInfo(list: cam)
            }.store(in: &cancellables)
        }
    }
    func changedInfo(list: FirebaseCamList) {
        let level = "\(list.batteryLevel.description)%"
        print("level",level)
        let boltImage = UIImage(systemName: "bolt.fill", withConfiguration: viewModel.imageConf)
        
        self.camNameLabel.text = list.camName
        guard let status =  fbModel.checkCamList[list.hls] else {return}
        
        if status == 1 {
            batteryLevelBT.setTitle(level, for: .normal)
            if list.batteryState == "Charging" {
                batteryLevelBT.setImage(boltImage, for: .normal)
            } else {
                batteryLevelBT.setImage(nil, for: .normal)
            }
        }
        torchBool = list.torch
        if torchBool{
            torchBT.setImage(UIImage(systemName: "lightbulb.fill"), for: .normal)
        } else {
            torchBT.setImage(UIImage(systemName: "lightbulb"), for: .normal)
        }
        
    }
    @IBAction func torch(_ sender: Any) {
        guard let list = viewModel.camInfo else {return}
        if torchBool {
            viewModel.setOffTorch(hls: list.hls)
        } else {
            viewModel.setOnTorch(hls: list.hls)
        }
    }
    

    @IBAction func backAction(_ sender: Any) {
        self.dismiss(animated: true,completion: nil)
    }

    @IBAction func changePosition(_ sender: Any) {
        if let list = camInfo {
            fbModel.changePosition(hls: list.hls)
        }
        timerCount = 0
    }
    
    override func viewDidLoad() {
        layoutSetting()
        playViewInfoTogle()
//        setPlayer()
        loadingBackView.backgroundColor = .clear
        loadingView = LottieAnimationView(name: "loading")
        loadingView.frame = loadingBackView.bounds
        loadingView.play()
        loadingView.loopMode = .loop
        loadingBackView.addSubview(loadingView)
        DispatchQueue.main.asyncAfter(deadline: .now()+1.5) {
            self.loadingView.stop()
            self.loadingBackView.isHidden = true
        }
        
    }
    override func viewDidAppear(_ animated: Bool) {
//        NotificationCenter.default.removeObserver(self)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("viewWillDisappear")
        stream.close()
        connection.close()
        stream.attachAudio(nil)
        stream.attachCamera(nil, channel: 0)
        stream.attachCamera(nil, channel: 1)
        stream = nil
        
    }

    
    func setPlayer(hls: String) {
        stream = SRTStream(connection: connection)
        connection.open(urlModel.makeSrtUrl(hls: hls, push: false),mode: .caller)
        let hkView = MTHKView(frame: playerView.bounds)
        hkView.videoGravity = AVLayerVideoGravity.resizeAspect
        hkView.attachStream(stream)
        playerView.addSubview(hkView)
        stream.play()
        hkView.accessibilityTraits = .playsSound
    }
    private func settingPlayerURL(hls: String) {
//        print(urlModel.playerItem(hls: hls))
//        
//        player.replaceCurrentItem(with: urlModel.playerItem(hls: hls))
//        
//        playerLayer.player = player
//        playerLayer.frame = playerView.bounds
//        playerView.layer.addSublayer(playerLayer)
//        player.play()
//        player.volume = 0
//        if player.timeControlStatus != .paused {
//            print("pause")
//        }
    }
    
    @objc func playViewTap(sender: UITapGestureRecognizer) {
        playViewInfoTogle()
    }

    func playViewInfoTogle() {
        if tapEventBool { 
            tapEventFalse()
        } else {
            tapEventTrue()
        }
    }
    func tapEventTrue() {
        UIView.animate(withDuration: 0.15, animations: {
            self.topInfoView.layer.opacity = 1.0
            self.bottomInfoView.layer.opacity = 1.0
        })
        timerCount = 0
        timer = Timer(timeInterval: 1, repeats: true, block: { _ in
            self.timerCount += 1
            if self.tapEventBool == true, self.timerCount > 5 {
                self.playViewInfoTogle()
            }
        })
        RunLoop.current.add(timer!, forMode: .common)
        tapEventBool.toggle()
    }
    func tapEventFalse() {
        timer?.invalidate()
        UIView.animate(withDuration: 0.15, animations: {
            self.topInfoView.layer.opacity = 0
            self.bottomInfoView.layer.opacity = 0
        })
        tapEventBool.toggle()
    }
    @objc func addTimeTapEvent(sender: UITapGestureRecognizer) {
        if tapEventBool {
            print("timerCount = 0")
            timerCount = 0
        }
    }
    
    func layoutSetting() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playViewTap(sender: )))
        let timerCountTap = UITapGestureRecognizer(target: self, action: #selector(addTimeTapEvent(sender: )))
//        let btGroundColor = UIColor.mainGreen
        topInfoView.addGestureRecognizer(timerCountTap)
        bottomInfoView.addGestureRecognizer(timerCountTap)
        playerView.addGestureRecognizer(tapGesture)
        playerView.backgroundColor = .black
        self.view.backgroundColor = .black

        backBT.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        backBT.setTitle("", for: .normal)
        backBT.tintColor = .white
//        fullModeBT.setTitle("", for: .normal)
//        fullModeBT.setImage(UIImage(systemName: "rotate.right.fill"), for: .normal)
//        fullModeBT.tintColor = .white
//        fullModeBT.backgroundColor = btGroundColor
//        fullModeBT.layer.cornerRadius = fullModeBT.layer.frame.width/2
        camNameLabel.font = UIFont.boldSystemFont(ofSize: 20)
        camNameLabel.textColor = .white
        changePositionBT.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
//        changePositionBT.setTitle("카메라 변경", for: .normal)
        changePositionBT.tintColor = .white
//        changePositionBT.backgroundColor = btGroundColor
//        changePositionBT.layer.cornerRadius = changePositionBT.layer.frame.width / 2
        
        volumeBT.setImage(UIImage(systemName: "speaker.slash.fill"), for: .normal)
        volumeBT.tintColor = .white
        volumeBT.setTitle("", for: .normal)
        volumeBT.isHidden = true
//        volumeBT.backgroundColor = btGroundColor
//        volumeBT.layer.cornerRadius = volumeBT.layer.frame.width / 2
//        volumeBT.contentVerticalAlignment = .bottom
        
//        batteryLevelLabel.text = "--%"
//        batteryLevelLabel.font = UIFont.boldSystemFont(ofSize: 10)
//        batteryLevelLabel.textColor = .white
        batteryLevelBT.setTitleColor(viewModel.tintColor, for: .normal)
        batteryLevelBT.tintColor = viewModel.tintColor
        batteryLevelBT.setTitle("--%", for: .normal)
        batteryLevelBT.titleLabel?.font = viewModel.labelFont
        topInfoView.isUserInteractionEnabled = true
        bottomInfoView.isUserInteractionEnabled = true
        topInfoView.layer.backgroundColor = (UIColor.black.cgColor).copy(alpha: 0.5)
        bottomInfoView.layer.backgroundColor = (UIColor.black.cgColor).copy(alpha: 0.5)
        
        torchBT.setImage(UIImage(systemName: "lightbulb"), for: .normal)
        torchBT.setTitle("", for: .normal)
        torchBT.tintColor = .white
    }

}

