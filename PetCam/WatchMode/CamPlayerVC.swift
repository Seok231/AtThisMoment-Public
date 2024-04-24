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
    deinit {
        print("CamPlayerVC deinit")
    }
    @IBOutlet weak var torchBT: UIButton!
    @IBOutlet weak var loadingBackView: UIView!
    @IBOutlet weak var batteryLevelBT: UIButton!
    @IBOutlet weak var bottomInfoView: UIView!
    @IBOutlet weak var topInfoView: UIView!
    @IBOutlet weak var changePositionBT: UIButton!
    @IBOutlet weak var camNameLabel: UILabel!
    @IBOutlet weak var playerView: MTHKView!
    @IBOutlet weak var backBT: UIButton!
    var timer: Timer?
    var tapEventBool = false
    var torchBool = false
    var urlModel = URLModel()
    let fbModel = FirebaseModel.fb
    let moveModel = MoveViewControllerModel()
    let viewModel = PlayerModel()
    var stream: SRTStream?
    var connection:SRTConnection = SRTConnection()
    var observation: NSKeyValueObservation?
    var cancellables: Set<AnyCancellable> = []
    var timerCount = 0
    var loadingView: LottieAnimationView!
    var hhls: String?
    private var volumeBool = false
    var camInfo: FirebaseCamList? {
        didSet {
            guard let list = camInfo else {return}
            setPlayer(hls: list.hls)
            hhls = list.hls
            viewModel.currentCamInfo(hls: list.hls) { fb in
                self.changedInfo(list: fb)
            }
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
        guard let camInfo = camInfo else {return}
        if torchBool {
            viewModel.setOffTorch(hls: camInfo.hls)
        } else {
            viewModel.setOnTorch(hls: camInfo.hls)
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
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewDidLoad() {
        layoutSetting()
        playViewInfoTogle()

        loadingBackView.backgroundColor = .clear
        loadingView = LottieAnimationView(name: "loading")
        loadingView.frame = loadingBackView.bounds
        loadingView.play()
        loadingView.loopMode = .loop
        loadingBackView.addSubview(loadingView)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.loadingView.stop()
            self.loadingBackView.isHidden = true
            self.backBT.isHidden = false
            self.playerView.isHidden = false
            
        }
        
        
//        observation = connection.observe(\.connected, options: [.old, .new] ){  (srtConnection, change) in
//            guard let value = change.newValue else {return}
//            
//        }

        
    }
    override func viewDidDisappear(_ animated: Bool) {
//        stream?.close()
//        connection.close()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        
//        stream?.publish()
//        stream?.attachAudio(nil)
//        stream?.attachCamera(nil)
        print("b")
        stream?.close()
        connection.close()
        stream = nil
        viewModel.removeObserve()
////        netStreamSwitcher.close()
//        pipView.attachStream(nil)
    }

    
    func setPlayer(hls: String) {
        let url = urlModel.makeSrtUrl(hls: hls, push: false)
        print("URL", url)
        stream = SRTStream(connection: connection)
        connection.open(url)
//        netStreamSwitcher.uri = url.description
//        print(connection.uri ?? "")
//        pipView.frame = playerView.bounds
//        
//        pipView.videoGravity = .resizeAspect
//        playerView.addSubview(pipView)
//        playerView.attachStream(stream)
        playerView.attachStream(stream)
        stream?.play()
//        netStreamSwitcher.open(.playback)
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
//        timer = Timer(timeInterval: 1, repeats: true, block: { _ in
//            self.timerCount += 1
//            if self.tapEventBool == true, self.timerCount > 5 {
//                self.playViewInfoTogle()
//            }
//        })
//        RunLoop.current.add(timer!, forMode: .common)
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
        topInfoView.addGestureRecognizer(timerCountTap)
        bottomInfoView.addGestureRecognizer(timerCountTap)
        playerView.addGestureRecognizer(tapGesture)
        playerView.backgroundColor = .black
        self.view.backgroundColor = .black

        backBT.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        backBT.setTitle("", for: .normal)
        backBT.tintColor = .white
        camNameLabel.font = UIFont.boldSystemFont(ofSize: 20)
        camNameLabel.textColor = .white
        changePositionBT.tintColor = .white
        changePositionBT.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
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
        
        self.backBT.isHidden = true
        playerView.isHidden = true
    }

}
