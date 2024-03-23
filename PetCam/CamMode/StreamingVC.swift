//
//  StreamingVC.swift
//  PetCam
//
//  Created by 양윤석 on 2/19/24.
//

import Foundation
import UIKit
import HaishinKit
import AVFoundation
import Combine


class StreamingVC: UIViewController {
    
    @IBOutlet weak var deviceVersionLabel: UILabel!
    @IBOutlet weak var deviceVersionTitle: UILabel!
    @IBOutlet weak var fpsSettingLabel: UILabel!
    @IBOutlet weak var camNameLabel: UILabel!
    @IBOutlet weak var camNameTitle: UILabel!
    @IBOutlet weak var camStatusBT: UIButton!
    @IBOutlet weak var changePositionBT: UIButton!
//    @IBOutlet weak var greenColorView: UIView!
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
    private var deviceOrientation = UIDevice.current.orientation
    private var stream: RTMPStream! = nil
    private var connection = RTMPConnection()
    private var retryCount: Int = 0
    private let maxRetryCount: Int = 5
    var fbModel = FirebaseModel.fb
    let viewModel = StreamingVCModel()
    let moveModel = MoveViewControllerModel()
    let urlModel = URLModel()
    var currentPosition: AVCaptureDevice.Position = .front
    var cancellables: Set<AnyCancellable> = []
    var batteryLevel: Float { UIDevice.current.batteryLevel }
    var batteryState: UIDevice.BatteryState { UIDevice.current.batteryState }
    @objc func fpsSetting(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            stream.frameRate = 15
        } else {
            stream.frameRate = 30
        }
    }

    @IBAction func changeCamPosition(_ sender: Any) {
        changePosition()
    }
    @IBAction func changeMode(_ sender: Any) {
        let selectVC = moveModel.moveToVC(storyboardName: "Main", className: "SelectModeVC")
        self.present(selectVC, animated: true)
//        self.dismiss(animated: true)
    }
    @IBAction func retryPush(_ sender: Any) {
        startStreaming()
    }
    @IBAction func infoViewCloseAction(_ sender: Any) {
        UIView.animate(withDuration: 0.3) {
            self.infoViewWidths.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    @IBAction func infoBTAction(_ sender: Any) {
        let newWidth: CGFloat = (infoViewWidths.constant == 0) ? 250.0 : 0.0

        UIView.animate(withDuration: 0.3) {
            self.infoViewWidths.constant = newWidth
            self.view.layoutIfNeeded()
        }
    }
    @objc func handleTap(sender: UITapGestureRecognizer) {
        
        UIView.animate(withDuration: 0.3) {
            self.infoViewWidths.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func signOutAction(_ sender: Any) {
        let signOut = UIAlertAction(title: "로그아웃", style: .default) { _ in
            self.fbModel.signOut()
            let vc = self.moveModel.moveToVC(storyboardName: "Main", className: "SignInVC")
            self.present(vc, animated: true)
            
        }
        let alert = moveModel.signOutAlert(signOut: signOut)
        self.present(alert, animated: true)
        
    }
    @objc func batteryLevelDidChange(_ notification: Notification) {
        let level = Int(batteryLevel*100)
        if level % 5 == 0 {
            viewModel.setCamBatteryLevel(batteryLevel: batteryLevel)
        }
    }
    @objc func batteryStateDidChange(_ notification: Notification) {
        viewModel.setCamBatteryState(batteryState: batteryState)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        print("1")
        viewModel.checkCameraPermission()
        setCamInfo()
        streamSetting()
        startStreaming()
        settingUI()
        viewModel.currentPosition {
            print("currnetPosition")
            self.changePosition()
        }
//        NotificationCenter.default.addObserver(self, selector: #selector(self.detectOrientation), name: NSNotification.Name("UIDeviceOrientationDidChangeNotification"), object: nil)
    }
    override func viewWillDisappear(_ animated: Bool) {
        stopStreaming()
        viewModel.removeListener()
    }
  
    func settingUI() {
        UIApplication.shared.isIdleTimerDisabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        let titleFont = UIFont.boldSystemFont(ofSize: 13)
        let labelFont = UIFont.boldSystemFont(ofSize: 15)
        
        liveView.addGestureRecognizer(tapGesture)
        liveView.isUserInteractionEnabled = true
        camStatusBT.setImage(UIImage(systemName: "circlebadge.fill"), for: .normal)
        camStatusBT.setTitle("오프라인", for: .normal)
        camStatusBT.tintColor = UIColor(named: "CamStatusRed")
        camStatusBT.setTitleColor(.white, for: .normal)
        camStatusBT.isUserInteractionEnabled = false
        infoBT.setImage(UIImage(named: "ellipsis"), for: .normal)
        infoBT.setTitle("", for: .normal)
        infoBT.tintColor = .white
        infoViewCloseBT.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        infoViewCloseBT.setTitle("", for: .normal)
        infoViewCloseBT.tintColor = .black
        changeWatchModeBT.setImage(UIImage(systemName: "text.justify"), for: .normal)
        changeWatchModeBT.setTitle("시청 모드로 전환", for: .normal)
        changeWatchModeBT.tintColor = .black
        changeWatchModeBT.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        retryPushBT.setImage(UIImage(systemName: "arrow.counterclockwise.circle.fill"), for: .normal)
        retryPushBT.setTitle("재접속", for: .normal)
        retryPushBT.tintColor = UIColor(named: "MainGreen")
        retryPushBT.setTitleColor(.white, for: .normal)
        
        changePositionBT.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera.fill"), for: .normal)
        changePositionBT.setTitle("", for: .normal)
        changePositionBT.tintColor = .white
        changePositionBT.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        
        signOutBT.setTitle("로그아웃", for: .normal)
        signOutBT.backgroundColor = .lightGray
        signOutBT.tintColor = .lightGray
        signOutBT.layer.cornerRadius = 10
        signOutBT.setTitleColor(.white, for: .normal)
        
        userNameLabel.textColor = .black
        userNameLabel.font = labelFont
        userNameLabel.text = viewModel.userName
        userEmailLabel.text = viewModel.userEmail
        userEmailLabel.font = UIFont.boldSystemFont(ofSize: 15)
        userEmailLabel.textColor = .gray
        infoView.backgroundColor = .white
        infoViewWidths.constant = 0
//        greenColorView.backgroundColor = UIColor(named: "MainGreen")
        
        fpsLabel.text = "0FPS"
        fpsLabel.textColor = .white
        if #available(iOS 15.0, *) {
            changeWatchModeBT.configuration?.imagePadding = 10
        } else {
            changeWatchModeBT.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        }
        
        // infoView
        camNameTitle.text = "카메라 이름"
        camNameTitle.font = titleFont
        camNameTitle.textColor = .lightGray
        
        camNameLabel.font = labelFont
        camNameLabel.textColor = .black
        
        fpsSettingLabel.font = titleFont
        fpsSettingLabel.textColor = .lightGray
        fpsSettingLabel.text = "FPS"
        
        fpsSG.addTarget(self, action: #selector(fpsSetting(_:)), for: .valueChanged)
        deviceVersionTitle.text = "카메라 버전"
        deviceVersionTitle.font = titleFont
        deviceVersionTitle.textColor = .lightGray
        
        deviceVersionLabel.text = viewModel.deviceVersion
        deviceVersionLabel.font = labelFont
        deviceVersionLabel.textColor = .black
    }
    
    func setCamInfo() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        viewModel.currentCamInfo2(batteryLevel: batteryLevel, batteryState: batteryState) {
            let list = self.viewModel.camInfo
            print("camInfo",list)
            self.camNameLabel.text = list["camName"] as? String
            
        }

        NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelDidChange), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(batteryStateDidChange), name: UIDevice.batteryStateDidChangeNotification, object: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if Thread.isMainThread {
//            self.fps = Int(stream.currentFPS)
            fpsLabel.text = "\(stream.currentFPS.description)FPS"
            if connection.connected {
                camStatusBT.tintColor = UIColor(named: "CamStatusGreen")
                camStatusBT.setTitle("온라인", for: .normal)
                retryPushBT.isHidden = true
            } else {
                camStatusBT.tintColor = UIColor(named: "CamStatusRed")
                camStatusBT.setTitle("오프라인", for: .normal)
                retryPushBT.isHidden = false
            }
        }
    }
    func streamSetting() {
        stream = RTMPStream(connection: connection)
        stream.attachAudio(AVCaptureDevice.default(for: .audio))
        stream.attachCamera(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back), channel: 0)
        connection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
        stream.addObserver(self, forKeyPath: "currentFPS", options: .new, context: nil)
        liveView.videoGravity = AVLayerVideoGravity.resizeAspectFill
        liveView.attachStream(stream)
        stream.frameRate = 15
        stream.videoSettings = VideoCodecSettings(
            videoSize: .init(width: 720, height: 1280)
          )
        stream.bitrateStrategy = IOStreamVideoAdaptiveNetBitRateStrategy(mamimumVideoBitrate: VideoCodecSettings.default.bitRate)
    }
    func startStreaming() {
        connection.connect(viewModel.pushURL)
//        stream.publish(viewModel.userDeviceID)
        stream.publish(viewModel.pushID)
    }
    
    func stopStreaming() {
        connection.close()
        stream.close()
        stream.removeObserver(self, forKeyPath: "currentFPS")
        connection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
        stream.attachAudio(nil)
        stream.attachCamera(nil, channel: 0)
        stream.attachCamera(nil, channel: 1)
        NotificationCenter.default.removeObserver(self)
    }
    func changePosition() {
        let position: AVCaptureDevice.Position = self.currentPosition == .back ? .front : .back
        stream.attachCamera(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position), channel: 0) { _, error in
          if let error {
            print("attachVideo error", error)
          }
        }
        self.currentPosition = position
    }
    @objc func detectOrientation() {
        // 기기방향 가로
        if (UIDevice.current.orientation == .landscapeLeft) || (UIDevice.current.orientation == .landscapeRight) {
            deviceOrientation = UIDeviceOrientation.landscapeLeft
            stream.videoSettings = VideoCodecSettings(
                videoSize: .init(width: 1280, height: 720))
//            stream.videoOrientation = deviceOrientation
            print(deviceOrientation)
//            stream.close()
//            startStreaming()
            
        }
        //기기방향 세로
        else if (UIDevice.current.orientation == .portrait) || (UIDevice.current.orientation == .portraitUpsideDown) {
            deviceOrientation = UIDeviceOrientation.portrait
            stream.videoSettings = VideoCodecSettings(
                videoSize: .init(width: 720, height: 1280))
            print(deviceOrientation)
//            stream.close()
//            startStreaming()
        }
        if let orientation = DeviceUtil.videoOrientation(by: UIDevice.current.orientation) {
            stream.videoOrientation = orientation
        }
    }
    
    @objc
    private func rtmpStatusHandler(_ notification: Notification) {
        let e = Event.from(notification)
//        print(e)
        guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
            return
        }
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            retryCount = 0
//            stream.publish(viewModel.userDeviceID)
            stream.publish(viewModel.pushID)
        case RTMPConnection.Code.connectFailed.rawValue, RTMPConnection.Code.connectClosed.rawValue:
            guard retryCount <= maxRetryCount else {
                return
            }
            Thread.sleep(forTimeInterval: pow(2.0, Double(retryCount)))
            print("Restart RTMP")
            connection.connect(viewModel.pushURL)
            retryCount += 1
        default:
            break
        }
    }

}
