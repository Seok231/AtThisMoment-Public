//
//  WebRTCClient.swift
//  AtThisMoment
//
//  Created by 양윤석 on 5/6/24.
//

import Foundation
import Starscream
import WebRTC

protocol WebRTCClientDelegate: AnyObject {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate)
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState)
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data)
    func webRTCClient(_ client: WebRTCClient, didAdd stream: RTCMediaStream)
}

class WebRTCClient: NSObject {
    var peerConnection: RTCPeerConnection?
    var localStream: RTCMediaStream?
    var peerConnections = [String: RTCPeerConnection]()
//    var websocketService: WebSocketService?
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()
    weak var delegate: WebRTCClientDelegate?
    private let rtcAudioSession =  RTCAudioSession.sharedInstance()
    private let audioQueue = DispatchQueue(label: "audio")
    private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue]
    var camCapturer: RTCCameraVideoCapturer?
    private var videoCapturer: RTCVideoCapturer?
    private var localVideoTrack: RTCVideoTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    private var localDataChannel: RTCDataChannel?
    private var remoteDataChannel: RTCDataChannel?
    
    func createHostPeerConnection(for peerID: String, local: Bool) -> RTCPeerConnection? {
        let config = RTCConfiguration()
        let iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        config.iceServers = iceServers
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        guard let peerConnection = WebRTCClient.factory.peerConnection(with: config, constraints: constraints, delegate: nil) else {
            fatalError("Could not create new RTCPeerConnection")
        }

        // 피어 ID로 딕셔너리에 추가
        

        if local {
//            let videoTrack = createVideoTrack()
            let audioTrack = createAudioTrack()
            let streamId = ["stream0"]
    //        peerConnection.add(videoTrack, streamIds: streamId)
            
            guard let localVideoTrack = localVideoTrack else {
                print("get localVideoTrack error ")
                return peerConnection
            }
            peerConnection.add(localVideoTrack, streamIds: streamId)
            peerConnection.add(audioTrack, streamIds: streamId)
        }
        
        peerConnection.delegate = self
        peerConnections[peerID] = peerConnection
        return peerConnection
    }
    
    func createClientPeerConnection() {
        let config = RTCConfiguration()
        let iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        config.iceServers = iceServers
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil,optionalConstraints: nil)
        guard let peerConnection = WebRTCClient.factory.peerConnection(with: config, constraints: constraints, delegate: nil) else {
            fatalError("Could not create new RTCPeerConnection")
        }
        
        self.peerConnection = peerConnection
        let streamId = "stream"
        let audioTrack = createAudioTrack()
        self.peerConnection?.add(audioTrack, streamIds: [streamId])
        speakerOff()
        self.peerConnection?.delegate = self
        
    }
    
    func closePeerConnection(for peerID: String) {
         peerConnections[peerID]?.close()
         peerConnections.removeValue(forKey: peerID)
     }

     // 미디어 트랙 추가
     private func createMediaSenders(for peerConnection: RTCPeerConnection) {
         let streamId = "stream"
         
         // 오디오 트랙 추가
         let audioTrack = createAudioTrack()
         peerConnection.add(audioTrack, streamIds: [streamId])
         
         // 비디오 트랙 추가
         let videoTrack = createVideoTrack()
         self.localVideoTrack = videoTrack
         peerConnection.add(videoTrack, streamIds: [streamId])
     }

     // 오디오 트랙 생성
     private func createAudioTrack() -> RTCAudioTrack {
         let audioConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
         let audioSource = WebRTCClient.factory.audioSource(with: audioConstraints)
         let audioTrack = WebRTCClient.factory.audioTrack(with: audioSource, trackId: "audio0")
         return audioTrack
     }

     // 비디오 트랙 생성
    private func createVideoTrack() -> RTCVideoTrack {
        let videoSource = WebRTCClient.factory.videoSource()
        
        #if targetEnvironment(simulator)
        self.videoCapturer = RTCFileVideoCapturer(delegate: videoSource)
        #else
        self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        #endif
        
        let videoTrack = WebRTCClient.factory.videoTrack(with: videoSource, trackId: "video0")
        return videoTrack
    }
    func startLocalCameraCapture(to renderer: RTCVideoRenderer, position: AVCaptureDevice.Position) {
        let videoSource = WebRTCClient.factory.videoSource()
        self.camCapturer = RTCCameraVideoCapturer(delegate: videoSource)

        // 로컬 비디오 트랙을 생성하여 유지
        self.localVideoTrack = WebRTCClient.factory.videoTrack(with: videoSource, trackId: "video0")
        self.localVideoTrack?.add(renderer)

        // 카메라 선택 및 캡처 시작
        guard
            let camera = RTCCameraVideoCapturer.captureDevices().first(where: { $0.position == position }),
            let format = RTCCameraVideoCapturer.supportedFormats(for: camera).last,
            let fps = format.videoSupportedFrameRateRanges.first?.maxFrameRate
        else {
            print("No suitable camera found")
            return
        }

        self.camCapturer?.startCapture(with: camera, format: format, fps: Int(fps))
    }
    func chagePeersCamPosition2(renderer: RTCVideoRenderer, position: AVCaptureDevice.Position) {
        let videoSource = WebRTCClient.factory.videoSource()
        self.camCapturer = RTCCameraVideoCapturer(delegate: videoSource)

//        camCapturer?.stopCapture()
        // 로컬 비디오 트랙을 생성하여 유지
        self.localVideoTrack = WebRTCClient.factory.videoTrack(with: videoSource, trackId: "video0")
        self.localVideoTrack?.add(renderer)

        // 카메라 선택 및 캡처 시작
        
        guard
            let camera = RTCCameraVideoCapturer.captureDevices().first(where: { $0.position == position }),
            let format = RTCCameraVideoCapturer.supportedFormats(for: camera).last,
            let fps = format.videoSupportedFrameRateRanges.first?.maxFrameRate
        else {
            print("No suitable camera found")
            return
        }

        self.camCapturer?.startCapture(with: camera, format: format, fps: Int(fps))
        guard let track = localVideoTrack else {return}
        for (peerID, peerConnection) in peerConnections {
            if let transceiver = peerConnection.transceivers.first(where: { $0.mediaType == .video }) {
                transceiver.sender.track = track
            }
        }
    }
    func chagePeersCamPosition() {
        guard let track = localVideoTrack else {return}
        for (peerID, peerConnection) in peerConnections {
            if let transceiver = peerConnection.transceivers.first(where: { $0.mediaType == .video }) {
                transceiver.sender.track = track
            }
        }
    }
    
    func stopCameraCapture() {
        camCapturer?.stopCapture()
    }
    
    func closeHost() {
        for (peerID, peerConnection) in peerConnections {
            peerConnection.close()
        }
        peerConnections.removeAll()
        stopCameraCapture()
    }
    
    func closeClient() {
        peerConnection?.close()
    }

    
    
    func renderRemoteVideo(to renderer: RTCVideoRenderer) {
        
        self.remoteVideoTrack = self.peerConnection?.transceivers.first { $0.mediaType == .video }?.receiver.track as? RTCVideoTrack
        self.remoteVideoTrack?.add(renderer)
    }
    
    
    
    private func configureAudioSession() {
        self.rtcAudioSession.lockForConfiguration()
        do {
            try self.rtcAudioSession.setCategory(AVAudioSession.Category.playback)
            try self.rtcAudioSession.setMode(AVAudioSession.Mode.default)
        } catch let error {
            debugPrint("Error changeing AVAudioSession category: \(error)")
        }
        self.rtcAudioSession.unlockForConfiguration()
    }
    
    private func createMediaSenders() {
        let streamId = "stream"
        
        // Audio
        let audioTrack = self.createAudioTrack()
        self.peerConnection?.add(audioTrack, streamIds: [streamId])
        
        // Video
        let videoTrack = self.createVideoTrack()
        self.localVideoTrack = videoTrack
        self.peerConnection?.add(videoTrack, streamIds: [streamId])
//        self.remoteVideoTrack = self.peerConnection?.transceivers.first { $0.mediaType == .video }?.receiver.track as? RTCVideoTrack
        
        // Data
//        if let dataChannel = createDataChannel() {
//            dataChannel.delegate = self
//            self.localDataChannel = dataChannel
//        }
    }
    func checkCameraPermission(){
       AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
           if granted {
               print("Camera: 권한 허용")
           } else {
               print("Camera: 권한 거부")
           }
       })
        AVCaptureDevice.requestAccess(for: .audio, completionHandler: { (granted: Bool) in
            if granted {
                print("Audio: 권한 허용")
            } else {
                print("Audio: 권한 거부")
            }
        })

    }

//    func setupPeerConnection() {
//        let configuration = RTCConfiguration()
//        configuration.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
//        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
//        peerConnection = RTCPeerConnectionFactory().peerConnection(with: configuration, constraints: constraints, delegate: self)
//    }


    func setHost(remoteSdp: RTCSessionDescription,id: String ,completion: @escaping (Error?) -> ()) {
        guard let peer = peerConnections[id] else {
            print("get peerConnections[id] error")
            return
        }
        peer.setRemoteDescription(remoteSdp, completionHandler: completion)
        peerConnections[id] = peer
        
    }
    func setHost(remoteCandidate: RTCIceCandidate,clientId: String, completion: @escaping (Error?) -> ()) {
        guard let peer = peerConnections[clientId] else {
            print("get peerConnections[clientId] Ice error")
            return
        }
        peer.add(remoteCandidate, completionHandler: completion)
        peerConnections[clientId] = peer
    }
    func setClient(remoteSdp: RTCSessionDescription,completion: @escaping (Error?) -> ()) {
        self.peerConnection?.setRemoteDescription(remoteSdp, completionHandler: completion)
        
    }
    func setClient(remoteCandidate: RTCIceCandidate, completion: @escaping (Error?) -> ()) {
        self.peerConnection?.add(remoteCandidate, completionHandler: completion)
    }

}
extension WebRTCClient {
    func testSendOffer(peerConnection: RTCPeerConnection,completion: @escaping(RTCSessionDescription)-> Void) {
        peerConnection.offer(for: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)) {(sdp, error) in
            guard let sdp = sdp else { return }
            peerConnection.setLocalDescription(sdp, completionHandler: { (error) in
                // 오퍼를 시그널링 서버(WebSocket)를 통해 전송
                completion(sdp)
//                self?.websocketService?.send(message: sdp.sdp)
            })
        }
    }
    
    func createAndSendOffer(completion: @escaping(RTCSessionDescription)-> Void) {
        peerConnection?.offer(for: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)) { [weak self] (sdp, error) in
            guard let sdp = sdp else { return }
            self?.peerConnection?.setLocalDescription(sdp, completionHandler: { (error) in
                // 오퍼를 시그널링 서버(WebSocket)를 통해 전송
                completion(sdp)
//                self?.websocketService?.send(message: sdp.sdp)
            })
        }
    }


    func answer( completion: @escaping (_ sdp: RTCSessionDescription) -> Void)  {
        let constrains = RTCMediaConstraints(mandatoryConstraints: nil,optionalConstraints: nil)
        peerConnection?.answer(for: constrains) { (sdp, error) in
            guard let sdp = sdp else {
                print("sdp error")
                return
            }
            
            self.peerConnection?.setLocalDescription(sdp, completionHandler: { (error) in
                completion(sdp)
            })
        }
    }
}
extension WebRTCClient {
    private func setTrackEnabled<T: RTCMediaStreamTrack>(_ type: T.Type, isEnabled: Bool) {
        peerConnection?.transceivers
            .compactMap { return $0.sender.track as? T }
            .forEach { $0.isEnabled = isEnabled }
    }
    private func setSelfTrackEnabled<T: RTCMediaStreamTrack>(_ type: T.Type, isEnabled: Bool) {
        peerConnection?.transceivers
            .compactMap { return $0.receiver.track as? T }
            .forEach { $0.isEnabled = isEnabled }
    }
}

// MARK: - Video control
extension WebRTCClient {
    func hideVideo() {
        self.setVideoEnabled(false)
    }
    func showVideo() {
        self.setVideoEnabled(true)
    }
    private func setVideoEnabled(_ isEnabled: Bool) {
        setTrackEnabled(RTCVideoTrack.self, isEnabled: isEnabled)
    }
}
extension WebRTCClient {
    func configureAudioSessionForReceivingOnly() {
        rtcAudioSession.lockForConfiguration()
        do {
            try rtcAudioSession.setCategory(.playback) // `playback` 모드로 설정
            try rtcAudioSession.setMode(.default)
        } catch let error {
            debugPrint("Error configuring audio session: \(error)")
        }
        rtcAudioSession.unlockForConfiguration()
    }
    func muteAudio() {
        self.setAudioEnabled(false)
    }
    
    func unmuteAudio() {
        self.setAudioEnabled(true)
    }
    
    func speakerOn() {
        setSpeakerEnabled(true)
    }
    
    func speakerOff() {
        setSpeakerEnabled(false)
    }
    
    private func setAudioEnabled(_ isEnabled: Bool) {
        setTrackEnabled(RTCAudioTrack.self, isEnabled: isEnabled)
    }
    private func setSpeakerEnabled(_ isEnabled: Bool) {
        setSelfTrackEnabled(RTCAudioTrack.self, isEnabled: isEnabled)
    }
}



extension WebRTCClient: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        debugPrint("peerConnection new signaling state: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        debugPrint("peerConnection did add stream")
        self.delegate?.webRTCClient(self, didAdd: stream)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        debugPrint("peerConnection did remove stream")
        
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        debugPrint("peerConnection should negotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        debugPrint("peerConnection new connection state: \(newState)")
        self.delegate?.webRTCClient(self, didChangeConnectionState: newState)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        debugPrint("peerConnection new gathering state: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.delegate?.webRTCClient(self, didDiscoverLocalCandidate: candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        debugPrint("peerConnection did remove candidate(s)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        debugPrint("peerConnection did open data channel")
        self.remoteDataChannel = dataChannel
    }
}
