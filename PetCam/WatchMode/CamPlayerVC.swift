//
//  CamPlayerVC.swift
//  PetCam
//
//  Created by 양윤석 on 2/16/24.
//

import Foundation
import WebRTC
import UIKit
import Combine
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
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var backBT: UIButton!
    @IBOutlet weak var micBT: UIButton!
    @IBOutlet weak var speakerBT: UIButton!
    var timer: Timer?
    var tapEventBool = false
    var torchBool = false
    var onOffmic = false
    var speakerBool = false
    var urlModel = URLModel()
    let fbModel = FirebaseModel.fb
    let moveModel = MoveViewControllerModel()
    let viewModel = PlayerModel()
    let userInfoModel = UserInfo.info
    let signalClient = SignalingClient()
    let webRTCClient = WebRTCClient()
    var observation: NSKeyValueObservation?
    var cancellables: Set<AnyCancellable> = []
    var timerCount = 0
    var loadingView: LottieAnimationView!
    private var volumeBool = false
    var camInfo: FirebaseCamList? {
        didSet {
            guard let list = camInfo else {return}
            setSignalClient(hostDeviceId: list.hls)
            viewModel.currentCamInfo(hls: list.hls) { fb in
                self.changedInfo(list: fb)
            }
        }
    }
    
    func setSignalClient(hostDeviceId: String) {
        signalClient.connect(hostDeviceId: hostDeviceId, host: false)
        signalClient.delegate = self
        
    }
    func setWebRTCClient() {
        webRTCClient.createClientPeerConnection()
        webRTCClient.delegate = self
        webRTCClient.muteAudio()
        webRTCClient.speakerOff()
        
    }

    func changedInfo(list: FirebaseCamList) {
        let level = "\(list.batteryLevel.description)%"
        print("level",level)
        let boltImage = UIImage(systemName: "bolt.fill", withConfiguration: viewModel.imageConf)
        
        
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
        self.camNameLabel.text = list.camName
        
    }
    @IBAction func mic(_ sender: Any) {
        if onOffmic {
            webRTCClient.muteAudio()
            micBT.setImage(UIImage(systemName: "mic.slash"), for: .normal)
            onOffmic.toggle()
        } else {
            webRTCClient.unmuteAudio()
            micBT.setImage(UIImage(systemName: "mic.fill"), for: .normal)
            onOffmic.toggle()
        }
        timerCount = 0
    }
    
    @IBAction func torch(_ sender: Any) {
        guard let camInfo = camInfo else {return}
        if torchBool {
            viewModel.setOffTorch(hls: camInfo.hls)
        } else {
            viewModel.setOnTorch(hls: camInfo.hls)
        }
        timerCount = 0
    }
    
    @IBAction func speaker(_ sender: Any) {
        if speakerBool {
            speakerBT.setImage(UIImage(systemName: "speaker.slash"), for: .normal)
            speakerBool.toggle()
            webRTCClient.speakerOff()
        } else {
            speakerBT.setImage(UIImage(systemName: "speaker.wave.3.fill"), for: .normal)
            speakerBool.toggle()
            webRTCClient.speakerOn()
        }
        timerCount = 0
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
        viewModel.checkAudioPermission()
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
        setWebRTCClient()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.removeObserve()
        timer?.invalidate()
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
            print(self.timerCount)
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
    @objc func camNameTapEvent(sender: UITapGestureRecognizer) {
        guard let info = camInfo else {return}
        let alert = viewModel.chageCamNameAlert(camName: info.camName)
        let save = UIAlertAction(title: "저장", style: .destructive) { [weak self] save in
            if let text = alert.textFields?[0].text {
                self?.camNameLabel.text = text
                let deviceID = info.hls
                self?.viewModel.updateCamName(changeName: text, deviceID: deviceID)
            }
        }
        save.setValue(UIColor(named: "MainGreen"), forKey: "titleTextColor")
        alert.addAction(save)
        self.present(alert, animated: true)
    }
    
    func layoutSetting() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playViewTap(sender: )))
        let timerCountTap = UITapGestureRecognizer(target: self, action: #selector(addTimeTapEvent(sender: )))
        let camNameTap = UITapGestureRecognizer(target: self, action: #selector(camNameTapEvent(sender: )))
        
        topInfoView.addGestureRecognizer(timerCountTap)
        bottomInfoView.addGestureRecognizer(timerCountTap)
        camNameLabel.addGestureRecognizer(camNameTap)
        playerView.addGestureRecognizer(tapGesture)
        
        playerView.backgroundColor = .black
        self.view.backgroundColor = .black

        backBT.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        backBT.setTitle("", for: .normal)
        backBT.tintColor = .white
        camNameLabel.isUserInteractionEnabled = true
        camNameLabel.font = UIFont.boldSystemFont(ofSize: 17)
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
        
        micBT.setTitle("", for: .normal)
        micBT.tintColor = viewModel.tintColor
        micBT.setImage(UIImage(systemName: "mic.slash"), for: .normal)
        
        speakerBT.setTitle("", for: .normal)
        speakerBT.setImage(UIImage(systemName: "speaker.slash"), for: .normal)
        speakerBT.tintColor = viewModel.tintColor
        
        self.backBT.isHidden = true
        playerView.isHidden = true
    }

}

extension CamPlayerVC: SignalClientDelegate{
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        let deviceId = userInfoModel.userDeviceID
        signalClient.socket?.write(string: deviceId)
    }
    
    func signalClientDidDisconnect(_ signalClient: SignalingClient) {
    }
    
    func getOffer(_ signalClient: SignalingClient, clientId id: String) {
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription, clientId id: String) {
        webRTCClient.setClient(remoteSdp: sdp) { error in
            if let error = error as NSError? {
                print("didReceiveCandidate error",error)
            }
            self.webRTCClient.answer { sdp in
                self.signalClient.send(sdp: sdp, uid: id)
            }
        }
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate, clientId id: String) {
        webRTCClient.setClient(remoteCandidate: candidate) { error in
            if let error = error as NSError? {
                print("didReceiveCandidate error",error)
            }
        }
    }
}

extension CamPlayerVC: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        let deviceId = UserInfo.info.userDeviceID
        signalClient.send(candidate: candidate, uid: deviceId)
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        switch state {
        case .connected:
            signalClient.clientConnet = true
            DispatchQueue.main.async {
                let remoteRenderer = RTCMTLVideoView(frame: self.view.frame)
                self.webRTCClient.renderRemoteVideo(to: remoteRenderer)
                self.playerView.addSubview(remoteRenderer)
            }
        case .disconnected:
            print("disconnected")
            let alert = viewModel.disconnectedAlert()
            let disMiss = UIAlertAction(title: "확인", style: .default) { disMiss in
                self.dismiss(animated: true)
            }
            alert.addAction(disMiss)
            DispatchQueue.main.async {
                self.present(alert, animated: true)
            }
            
        @unknown default:
            print("didChangeConnectionState default")
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
    }
    
    func webRTCClient(_ client: WebRTCClient, didAdd stream: RTCMediaStream) {
    }
}
