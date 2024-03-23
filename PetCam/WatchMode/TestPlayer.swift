//
//  TestPlayer.swift
//  PetCam
//
//  Created by 양윤석 on 3/11/24.
//

import Foundation
import UIKit
import AVFoundation

class TestPlayer: UIViewController {
    @IBOutlet weak var playerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!

    private var player = AVPlayer()
    private var playerLayer = AVPlayerLayer()
    override func viewDidLoad() {
        // UIScrollView 설정
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
        
        // 임의의 동영상 뷰를 생성하고 추가
        let playerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 300))
        playerView.backgroundColor = .black
        playerView.addSubview(playerView)
        
        // 여기서 동영상 플레이어를 초기화하고 설정
        
        // 동영상 뷰의 초기 크기 설정
        playerViewHeight.constant = 300
    }
}

extension TestPlayer: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let minVideoHeight: CGFloat = 100
        let maxVideoHeight: CGFloat = 300
        
        let newHeight = max(maxVideoHeight - offsetY, minVideoHeight)
        playerViewHeight.constant = newHeight
        
        // 동영상 뷰가 최소 크기에 도달하면 스크롤 뷰의 스크롤 가능한 영역을 고정
        if newHeight == minVideoHeight {
            scrollView.isScrollEnabled = false
        } else {
            scrollView.isScrollEnabled = true
        }
    }
    // 스크롤 오프셋에 따라 동영상 뷰의 크기를 조절

}
