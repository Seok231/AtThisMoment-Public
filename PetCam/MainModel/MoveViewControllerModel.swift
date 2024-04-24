//
//  MoveViewControllerModel.swift
//  PetCam
//
//  Created by 양윤석 on 2/21/24.
//

import Foundation
import UIKit

class MoveViewControllerModel: UIViewController {
    func moveToCamModAlert(move: UIAlertAction) -> UIAlertController {
//        let fbModel = FirebaseModel.fb
        let title = "카메라 모드로 변경하시겠습니까?"
        let message = ""
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        let signOut = UIAlertAction(title: "로그아웃", style: .cancel) { _ in fbModel.signOut() }
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        move.setValue(UIColor(named: "MainGreen"), forKey: "titleTextColor")
        cancel.setValue(UIColor.lightGray, forKey: "titleTextColor")
        alert.addAction(move)
        alert.addAction(cancel)
        return alert
    }
    func signOutAlert(signOut: UIAlertAction) -> UIAlertController {
//        let fbModel = FirebaseModel.fb
        let title = "로그아웃하시겠습니까?"
        let message = ""
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        let signOut = UIAlertAction(title: "로그아웃", style: .cancel) { _ in fbModel.signOut() }
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        signOut.setValue(UIColor(named: "MainGreen"), forKey: "titleTextColor")
        cancel.setValue(UIColor.lightGray, forKey: "titleTextColor")
        alert.addAction(signOut)
        alert.addAction(cancel)
        return alert
    }
    
    func moveToVC (storyboardName: String, className: String) -> UIViewController {
        let streamVC = UIStoryboard.init(name: storyboardName, bundle: nil)

        let nextVC = streamVC.instantiateViewController(withIdentifier: className)
        nextVC.modalTransitionStyle = .crossDissolve
        nextVC.modalPresentationStyle = .overFullScreen
//        self.present(nextVC, animated: true)
        return nextVC
    }
}
