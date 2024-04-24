//
//  StreamingVC.swift
//  PetCam
//
//  Created by 양윤석 on 2/19/24.
//

import Foundation
import UIKit
import HaishinKit
import SRTHaishinKit
import AVFoundation
import Combine
import Photos


class StreamingVC: UIViewController {
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var torchBT: UIButton!
    @IBOutlet weak var deviceVersionLabel: UILabel!
    @IBOutlet weak var deviceVersionTitle: UILabel!
    @IBOutlet weak var fpsSettingLabel: UILabel!
    @IBOutlet weak var camNameLabel: UILabel!
    @IBOutlet weak var camNameTitle: UILabel!
    @IBOutlet weak var camStatusBT: UIButton!
    @IBOutlet weak var changePositionBT: UIButton!
    @IBOutlet weak var retryPushBT: UIButton!
    @IBOutlet weak var infoViewCloseBT: UIButton!
    @IBOutlet weak var signOutBT: UIButton!
    @IBOutlet weak var changeWatchModeBT: UIButton!
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var infoViewWidths: NSLayoutConstraint!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var infoBT: UIButton!
    @IBOutlet weak var fpsLabel: UILabel!
    @IBOutlet weak var liveView: MTHKView!
    @IBOutlet weak var fpsSG: UISegmentedControl!
    var safeView = UIView()
    var timer: Timer?
    var originalBright = UIScreen.main.brightness
    var safeViewMaxCount = 40
    var safeViewTimer = 0
    var checkPosition: Double?
    private var deviceOrientation = UIDevice.current.orientation
    var stream: SRTStream! = nil
    var connection = SRTConnection()
    var observation: NSKeyValueObservation?
    var fbModel = FirebaseModel.fb
    let userModel = UserInfo.info
    let viewModel = StreamingVCModel()
    let moveModel = MoveViewControllerModel()
    let userInfoModel = UserInfo.info
    let urlModel = URLModel()
    var currentPosition: AVCaptureDevice.Position = .back
    var cancellables: Set<AnyCancellable> = []
    var batteryLevel: Float { UIDevice.current.batteryLevel }
    var batteryState: UIDevice.BatteryState { UIDevice.current.batteryState }
    let queue = DispatchQueue(label: "com.yys.streaming", qos: .userInitiated)

    @objc func fpsSetting(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            stream.frameRate = 15
        } else {
            stream.frameRate = 30
        }
    }
    @IBAction func test(_ sender: Any) {
//        startStreaming()
    }
    
    @IBAction func torch(_ sender: Any) {
        safeViewTimer = 0
        let torchOn = UIImage(systemName: "lightbulb")
        let torchOff = UIImage(systemName: "lightbulb.fill")
        if stream.torch {
            viewModel.setOffTorch()
            torchBT.setImage(torchOn, for: .normal)
            stream.torch.toggle()
        } else {
            viewModel.setOnTorch()
            torchBT.setImage(torchOff, for: .normal)
            stream.torch.toggle()
        }
    }
    @IBAction func changeCamPosition(_ sender: Any) {
        safeViewTimer = 0
        changePosition()
    }
    
    @IBAction func retryPush(_ sender: Any) {
        safeViewTimer = 0
        reStartStreaming()
    }
    func reStartStreaming() {
        stream.close()
        connection.close()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.startStreaming()
            
        }
    }
    @IBAction func infoViewCloseAction(_ sender: Any) {
        UIView.animate(withDuration: 0.3) {
            self.infoViewWidths.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    @IBAction func infoBTAction(_ sender: Any) {
        let newWidth: CGFloat = (infoViewWidths.constant == 0) ? 250.0 : 0.0
        safeViewTimer = 0
        
        UIView.animate(withDuration: 0.3) {
            self.infoViewWidths.constant = newWidth
            self.view.layoutIfNeeded()
        }
    }
    @objc func handleTap(sender: UITapGestureRecognizer) {
        safeViewTimer = 0
        UIView.animate(withDuration: 0.2) {
            self.infoViewWidths.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    @IBAction func changeMode(_ sender: Any) {
        UserDefaults.standard.set("WatchCamListVC", forKey: "Mode")
        let change = UIAlertAction(title: "모드 변경", style: .default) { _ in
            self.stopStreaming()
            let vc = self.moveModel.moveToVC(storyboardName: "Main", className: "WatchTabbar")
            self.timer?.invalidate()
            self.present(vc, animated: true)
            
        }
        let alert = viewModel.moveAlert(moveAction: change)
        self.present(alert, animated: true)
    }
    @IBAction func signOutAction(_ sender: Any) {
        let userInfo = UserInfo.info
        let signOut = UIAlertAction(title: "로그아웃", style: .default) { _ in
            self.timer?.invalidate()
            guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else {return}
            userInfo.signOut()
            sceneDelegate.moveToSignInVC()
            
        }
        let alert = moveModel.signOutAlert(signOut: signOut)
        self.present(alert, animated: true)
        
    }
    @objc func batteryLevelDidChange(_ notification: Notification) {
        let level = Int(batteryLevel*100)
        if level % 5 == 0 {
            viewModel.setCamBatteryLevel(batteryLevel: batteryLevel)
        }    }
    @objc func batteryStateDidChange(_ notification: Notification) {
        viewModel.setCamBatteryState()
    }
    func setSafeView() {
        self.view.bringSubviewToFront(safeView)
        safeView.backgroundColor = .black
        safeView.frame = liveView.bounds
        let safeViewLabel: UILabel = .init()
        safeViewLabel.frame = safeView.bounds
        safeViewLabel.text = "절전모드 작동중"
        safeViewLabel.textColor = .white
        safeViewLabel.font = UIFont.boldSystemFont(ofSize: 20)
        safeView.addSubview(safeViewLabel)
        self.view.addSubview(safeView)
        safeView.isHidden = true
        startTimer()
        safeViewLabel.translatesAutoresizingMaskIntoConstraints = false
        safeViewLabel.topAnchor.constraint(equalTo: liveView.topAnchor, constant: 200).isActive = true
        safeViewLabel.centerXAnchor.constraint(equalTo: liveView.centerXAnchor).isActive = true
        let resetSafeViewTimer = UITapGestureRecognizer(target: self, action: #selector(safeViewEvent(sender:)))
        let offSafeView = UITapGestureRecognizer(target: self, action: #selector(offSafeView(sender: )))
        liveView.addGestureRecognizer(resetSafeViewTimer)
        infoView.addGestureRecognizer(resetSafeViewTimer)
        safeView.addGestureRecognizer(offSafeView)
    }
    func startTimer() {
        timer = Timer(timeInterval: 1, repeats: true, block: { _ in
            self.safeViewTimer += 1
            if  self.safeViewTimer > self.safeViewMaxCount {
                self.originalBright = UIScreen.main.brightness
                self.safeView.isHidden = false
                UIScreen.main.brightness = 0
                self.timer?.invalidate()
            }
        })
        RunLoop.current.add(timer!, forMode: .common)
    }
    @objc func safeViewEvent(sender: UITapGestureRecognizer) {
        safeViewTimer = 0
    }
    @objc func offSafeView(sender: UITapGestureRecognizer) {
        safeViewTimer = 0
        safeView.isHidden = true
        UIScreen.main.brightness = originalBright
        startTimer()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.checkCameraPermission()
        streamBaseSetting()
        streamSetting()
      
        queue.asyncAfter(deadline: .now() + 1) {
            self.startStreaming()
        }
        streamSetting()
////        DispatchQueue.main.async {
            self.settingUI()
////        }
        setCamStatusBT(status: connection.connected)
        observation = connection.observe(\.connected, options: [.old, .new] ){  (srtConnection, change) in
            print("observ")
            guard let value = change.newValue else {return}
            print("Connection status changed",value)
            self.setCamStatusBT(status: value)
        }
        setSafeView()
        setCamInfo()
    }
    override func viewWillAppear(_ animated: Bool) {
//        streamSetting()
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        stopStreaming()
        //        viewModel.setOffTorch()
        viewModel.removeListener()
        self.timer?.invalidate()
    }
    func setCamStatusBT(status: Bool) {
        DispatchQueue.main.async {
            if self.connection.connected  {
                self.camStatusBT.setTitle("온라인", for: .normal)
                self.camStatusBT.tintColor = UIColor(named: "CamStatusGreen")
                self.retryPushBT.isHidden = true
            } else {
                self.camStatusBT.setTitle("오프라인", for: .normal)
                self.camStatusBT.tintColor = UIColor(named: "CamStatusRed")
                self.retryPushBT.isHidden = false
            }
        }
        
    }
    func setCamInfo() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        viewModel.currentCamInfo {
        self.viewModel.currentCamInfo2 { list in
            self.camNameLabel.text = list.camName
            self.observTorch(toggle: list.torch)
            self.setPosition(check: list.position)
            self.checkPosition = list.position
            
        }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelDidChange), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(batteryStateDidChange), name: UIDevice.batteryStateDidChangeNotification, object: nil)
        
        
    }
    func observTorch(toggle: Bool) {
        if toggle {
            stream.torch = toggle
            torchBT.setImage(UIImage(systemName: "lightbulb.fill"), for: .normal)
        } else {
            stream.torch = toggle
            torchBT.setImage(UIImage(systemName: "lightbulb"), for: .normal)
        }
    }
    
    func streamBaseSetting() {
        stream = SRTStream(connection: connection)
        stream.frameRate = 15
        
//        stream.bitrateStrategy = IOStreamVideoAdaptiveNetBitRateStrategy(mamimumVideoBitrate: VideoCodecSettings.default.bitRate)
    }
    func streamSetting() {
//        stream = SRTStream(connection: connection)
//        stream.frameRate = 15
        stream.videoSettings = VideoCodecSettings(
            videoSize: .init(width: 720, height: 1280),
            bitRate: 640 * 1000
        )
        stream.attachAudio(AVCaptureDevice.default(for: .audio))
        stream.attachCamera(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back), track: 0)
        liveView.videoGravity = AVLayerVideoGravity.resizeAspectFill
        liveView.attachStream(stream)
        
        
    }
    func startStreaming() {
        let url = urlModel.makeSrtUrl( hls: viewModel.userDeviceID, push: true)
        print(url.description)

        connection.open(url)
        print("connection",connection.uri)
        
        
        // 카메라 모드 -> 모티터링 모드 -> 카메라 모드
//        queue.asyncAfter(deadline: .now() + 5) {
            print("test")
            self.stream.publish()
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
//            
//        }
        
    
        

        
    }
    func stopStreaming() {
        print("stopStreaming()")
        stream.close()
        connection.close()
        stream.attachCamera(nil, track: 0)
        stream.attachCamera(nil, track: 1)
        stream.attachAudio(nil)
        //        stream.removeObserver(self, forKeyPath: "currentFPS")
        //        connection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
        
        //        NotificationCenter.default.removeObserver(self)
    }
    
    func setPosition(check: Double) {
        print("setPosition")
        guard let cp = checkPosition else{return}
        print(cp, check)
        if check != cp {
            changePosition()
        }
        self.checkPosition = check
    }
    
    func changePosition() {

        let position: AVCaptureDevice.Position = self.currentPosition == .back ? .front : .back
        stream.attachCamera(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position), track: 0) { _, error in
            if let error {
                print("attachVideo error", error)
            }
        }
        self.currentPosition = position
    }
    
    
    func settingUI() {
        UIApplication.shared.isIdleTimerDisabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        

        let titleFont = UIFont.boldSystemFont(ofSize: 13)
        let labelFont = UIFont.boldSystemFont(ofSize: 15)
        
        liveView.addGestureRecognizer(tapGesture)
        
        infoView.layer.shadowOpacity = 0.8
        infoView.layer.shadowOffset = CGSize(width: 2, height: 2)
        infoView.layer.shadowRadius = 3
        
        liveView.isUserInteractionEnabled = true
        camStatusBT.setImage(UIImage(systemName: "circlebadge.fill"), for: .normal)
        camStatusBT.setTitle("오프라인", for: .normal)
        camStatusBT.tintColor = UIColor(named: "CamStatusRed")
        camStatusBT.setTitleColor(.white, for: .normal)
//        camStatusBT.isUserInteractionEnabled = false
        infoBT.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        infoBT.setTitle("", for: .normal)
        infoBT.tintColor = .white
        infoViewCloseBT.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        infoViewCloseBT.setTitle("", for: .normal)
        infoViewCloseBT.tintColor = .black
        changeWatchModeBT.setImage(UIImage(systemName: "text.justify"), for: .normal)
        changeWatchModeBT.setTitle("모니터링 모드로 전환", for: .normal)
        changeWatchModeBT.tintColor = .black
        changeWatchModeBT.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        retryPushBT.setImage(UIImage(systemName: "arrow.counterclockwise.circle.fill"), for: .normal)
        retryPushBT.setTitle("재접속", for: .normal)
        retryPushBT.tintColor = UIColor(named: "CamStatusYellow")
        retryPushBT.setTitleColor(.white, for: .normal)
        
        changePositionBT.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera.fill"), for: .normal)
        changePositionBT.setTitle("", for: .normal)
        changePositionBT.tintColor = .white
        changePositionBT.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)

        
        // infoView
        camNameTitle.text = "카메라 이름"
        camNameTitle.font = titleFont
        camNameTitle.textColor = .lightGray
        camNameLabel.font = labelFont
        camNameLabel.textColor = .black
        fpsLabel.text = "0FPS"
        fpsLabel.textColor = .white
        fpsLabel.isHidden = true
        fpsSettingLabel.font = titleFont
        fpsSettingLabel.textColor = .lightGray
        fpsSettingLabel.text = "FPS"
        //        fpsSettingLabel.isHidden = true
        
        fpsSG.backgroundColor = .lightGray
        fpsSG.addTarget(self, action: #selector(fpsSetting(_:)), for: .valueChanged)
        fpsSG.isHidden = false
        
        deviceVersionTitle.text = "카메라 버전"
        deviceVersionTitle.font = titleFont
        deviceVersionTitle.textColor = .lightGray
        
        deviceVersionLabel.text = viewModel.deviceVersion
        deviceVersionLabel.font = labelFont
        deviceVersionLabel.textColor = .black
        
        torchBT.tintColor = .white
        torchBT.setTitle("", for: .normal)
        torchBT.setImage(UIImage(systemName: "lightbulb"), for: .normal)
        
        userModel.$info.sink { info in
            guard let name = info["name"] as? String else {return}
            self.userNameLabel.text = name
        }.store(in: &cancellables)
        userNameLabel.textColor = .black
        userNameLabel.font = UIFont.boldSystemFont(ofSize: 20)
        userModel.$name.sink { name in
            self.userNameLabel.text = name
        }.store(in: &cancellables)
        
        userEmailLabel.text = userModel.email
        userEmailLabel.font = UIFont.boldSystemFont(ofSize: 13)
        userEmailLabel.textColor = .gray
        infoView.backgroundColor = .white
        infoViewWidths.constant = 0
        //        greenColorView.backgroundColor = UIColor(named: "MainGreen")
        if #available(iOS 15.0, *) {
            changeWatchModeBT.configuration?.imagePadding = 10
        } else {
            changeWatchModeBT.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        }
        
        signOutBT.setTitle("로그아웃", for: .normal)
        signOutBT.backgroundColor = .lightGray
        signOutBT.tintColor = .lightGray
        signOutBT.layer.cornerRadius = 10
        signOutBT.setTitleColor(.white, for: .normal)
        let userInfoModel = UserInfoVCModel()
        let logo = userInfoModel.checkAuthProviderImage()
        logoImageView.image = logo


    }
}

