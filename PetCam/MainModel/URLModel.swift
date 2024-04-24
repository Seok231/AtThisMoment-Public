//
//  URL.swift
//  PetCam
//
//  Created by 양윤석 on 2/22/24.
//

import Foundation
import AVFoundation
import FirebaseAuth

class URLModel {
    let fbModel = FirebaseModel.fb
    let userInfo = UserInfo.info
    let stream = StreamingVCModel()
    
    func makeRtmpUrl(hls: String, push: Bool) -> URL {
        if push {
            return URL(string: "rtmp://diddbstjr55.iptime.org/hls/\(hls)")!
        }
        return URL(string: "http://diddbstjr55.iptime.org/hls/\(hls).m3u8")!
    }
    func makeSrtUrl(hls: String, push: Bool) -> URL {
        let hlsId = userInfo.uid + "@\(hls)"
        if push {
            return URL(string: "srt://220.121.93.66:8080?streamid=uplive.yys.com/live/\(hlsId)")!
        } else {
            return URL(string: "srt://220.121.93.66:8080?streamid=live.yys.com/live/\(hlsId)")!
        }
        
    }
    
//    func playerItem(hls: String) -> AVPlayerItem {
////        let url = self.inputURL(hls: hls)
//        let url = makeSrtUrl(hls: hls, push: false)
//        let playerItem = AVPlayerItem(url: url)
//        playerItem.preferredForwardBufferDuration = TimeInterval(1.0)
//        return playerItem
//    }
    
    func checkM3U8(hls: String, completion: @escaping (Bool) -> Void) {
        // URLSession 객체 생성
        let session = URLSession.shared
        let url = makeRtmpUrl(hls: hls, push: true)
        // URLSessionDataTask를 사용하여 요청 생성
        let task = session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                // 요청 중에 오류가 발생한 경우
                print("Error: \(error.localizedDescription)")
                completion(false)
            } else if let httpResponse = response as? HTTPURLResponse {
                // 서버로부터 응답을 성공적으로 받은 경우
                print("Status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    // .m3u8 파일이 정상적으로 작동하는 것으로 간주할 수 있음
                    print("URL is working fine.")
                    completion(true)
                } else {
                    print("URL is not working.")
                    completion(false)
                }
            }
        }
        
        // 요청 시작
        task.resume()
    }
}
