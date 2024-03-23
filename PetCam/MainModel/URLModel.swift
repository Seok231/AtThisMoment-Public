//
//  URL.swift
//  PetCam
//
//  Created by 양윤석 on 2/22/24.
//

import Foundation
import AVFoundation

class URLModel {
    var pushURL = "rtmp://diddbsthttps://velog.io/@diddbstjr55/Swift-SRT-%EC%86%A1%EC%B6%9Cjr55.iptime.org/hls"
    func inputStringURL(hls: String) -> String {
        
        return "http://diddbstjr55.iptime.org/hls/\(hls).m3u8"
        
        
    }
    func inputURL(hls: String) -> URL {
        if hls.count > 50 {
            return URL(string: "https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8")!
        }
        if hls.count < 10 {
            return URL(string: "http://220.121.93.66/chear/ch/ch1/master.m3u8")!
        }
        return URL(string: "http://diddbstjr55.iptime.org/hls/\(hls).m3u8")!
    }
    func makeSrtUrl(hls: String, push: Bool) -> URL {
        if push {
            return URL(string: "srt://220.121.93.66:8080?streamid=uplive.yys.com/live/\(hls)")!
        } else {
            return URL(string: "srt://220.121.93.66:8080?streamid=live.yys.com/live/\(hls)")!
        }
        
    }
    
    func playerItem(hls: String) -> AVPlayerItem {
        let url = self.inputURL(hls: hls)
        let playerItem = AVPlayerItem(url: url)
        playerItem.preferredForwardBufferDuration = TimeInterval(1.0)
        return playerItem
    }
    
    func checkM3U8(hls: String, completion: @escaping (Bool) -> Void) {
        // URLSession 객체 생성
        let session = URLSession.shared
        
        // URLSessionDataTask를 사용하여 요청 생성
        let task = session.dataTask(with: inputURL(hls: hls)) { (data, response, error) in
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
