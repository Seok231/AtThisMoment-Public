//
//  SignalingClient.swift
//  AtThisMoment
//
//  Created by 양윤석 on 5/6/24.
//

import Foundation
import Starscream
import WebRTC

protocol WebSocketProvider: AnyObject {
    var delegate: WebSocketProviderDelegate? { get set }
    func connect()
    func send(data: Data)
}

protocol WebSocketProviderDelegate: AnyObject {
    func webSocketDidConnect(_ webSocket: WebSocketProvider)
    func webSocketDidDisconnect(_ webSocket: WebSocketProvider)
    func webSocket(_ webSocket: WebSocketProvider, didReceiveData data: Data)
}

protocol SignalClientDelegate: AnyObject {
    func signalClientDidConnect(_ signalClient: SignalingClient)
    func signalClientDidDisconnect(_ signalClient: SignalingClient)
    func getOffer(_ signalClient: SignalingClient, clientId id: String)
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription, clientId id: String)
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate, clientId id: String)

}

class SignalingClient {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    var host = true
    var clientConnet = false
    var socket: WebSocket?
    weak var delegate: SignalClientDelegate?

    func connect(hostDeviceId: String, host: Bool) {
        let url = URL(string: "ws://220.121.93.66:70")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let userId = UserInfo.info.uid
        let dId = UserInfo.info.userDeviceID
        let roomId = "\(userId)@\(hostDeviceId)"
        let role = host ? "host" : "client"
        request.setValue(roomId , forHTTPHeaderField: "x-room-id")
        request.setValue(dId, forHTTPHeaderField: "x-user-id")
        request.setValue(role, forHTTPHeaderField: "x-user-role")
        print("roomId", roomId)
        
        socket = WebSocket(request: request)
        self.host = host
        socket?.delegate = self
        socket?.connect()
        
    }
    func close() {
        socket?.disconnect()
    }

    func send(sdp rtcSdp: RTCSessionDescription, uid: String) {
        let message = Message.sdp(SessionDescription(from: rtcSdp), clientID: uid)
        do {
            let dataMessage = try self.encoder.encode(message)
            
            self.socket?.write(data: dataMessage)
        }
        catch {
            debugPrint("Warning: Could not encode sdp: \(error)")
        }
    }
    
    func send(candidate rtcIceCandidate: RTCIceCandidate, uid: String) {
        let message = Message.candidate(IceCandidate(from: rtcIceCandidate), clientID: uid)
        do {
            let dataMessage = try self.encoder.encode(message)
            self.socket?.write(data: dataMessage)
        }
        catch {
            debugPrint("Warning: Could not encode candidate: \(error)")
        }
    }


}
extension SignalingClient: WebSocketDelegate{
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected(let headers):
            print("WebSocket is connected: \(headers)")
            self.delegate?.signalClientDidConnect(self)
        case .disconnected(let reason, let code):
            print("WebSocket is disconnected: \(reason) with code: \(code)")
            self.delegate?.signalClientDidDisconnect(self)
        case .text(let string):
            print("Received text: \(string)")
            if host {
                self.delegate?.getOffer(self, clientId: string)
            }
        case .binary(let data):
            let message: Message
            do {
                message = try self.decoder.decode(Message.self, from: data)
                print(type(of: message))
            }
            catch {
                debugPrint("Warning: Could not decode incoming message: \(error)")
                return
            }
            if clientConnet == false {
                switch message {
                case .candidate(let iceCandidate, let uid):
                    self.delegate?.signalClient(self, didReceiveCandidate: iceCandidate.rtcIceCandidate, clientId: uid)
                case .sdp(let sessionDescription, let uid):
                    self.delegate?.signalClient(self, didReceiveRemoteSdp: sessionDescription.rtcSessionDescription, clientId: uid)
                }
            }
        case .ping(_), .pong(_), .viabilityChanged(_), .reconnectSuggested(_), .cancelled:
            print("Received control message.")
        case .error(let error):
            if let error = error {
                print("WebSocket encountered an error: \(error)")
            }
        case .peerClosed:
            print("peerClosed")
            self.delegate?.signalClientDidDisconnect(self)
        }
    }
    

}
//extension SignalingClient: WebSocketProviderDelegate {
//    func webSocketDidConnect(_ webSocket: WebSocketProvider) {
//        self.delegate?.signalClientDidConnect(self)
//    }
//
//    func webSocketDidDisconnect(_ webSocket: WebSocketProvider) {
//        self.delegate?.signalClientDidDisconnect(self)
//
//        // try to reconnect every two seconds
//        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
//            debugPrint("Trying to reconnect to signaling server...")
//            self.socket?.connect()
//        }
//    }
//
//    func webSocket(_ webSocket: WebSocketProvider, didReceiveData data: Data) {
//        let message: Message
//        do {
//            message = try self.decoder.decode(Message.self, from: data)
//        }
//        catch {
//            debugPrint("Warning: Could not decode incoming message: \(error)")
//            return
//        }
//
//        switch message {
//        case .candidate(let iceCandidate, let uid):
//            self.delegate?.signalClient(self, didReceiveCandidate: iceCandidate.rtcIceCandidate, clientId: uid)
//        case .sdp(let sessionDescription, let uid):
//            self.delegate?.signalClient(self, didReceiveRemoteSdp: sessionDescription.rtcSessionDescription, clientId: uid)
//        }
//
//    }
//}
//
