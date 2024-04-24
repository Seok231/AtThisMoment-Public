//
//  SceneDelegate.swift
//  PetCam
//
//  Created by 양윤석 on 2/16/24.
//

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    let userModel = UserInfo.info
    // SceneDelegate.swift
    func moveToSignInVC() {
        guard let windowScene = window?.windowScene else { return }
        
        // 초기 뷰 컨트롤러 설정
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let initialViewController = storyboard.instantiateViewController(withIdentifier: "SignInVC") as? SignInVC else { return }
        
        // 새로운 루트 뷰 컨트롤러를 설정하여 앱을 처음 상태로 리셋
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = initialViewController
        window?.makeKeyAndVisible()
        
        // 필요한 경우 사용자 정보 싱글톤 초기화
//        UserManager.shared.resetUser()
    }


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

            // 새 UIWindow 생성
        let window = UIWindow(windowScene: windowScene)
        var storyboard = UIStoryboard(name: "Main", bundle: nil)
        var vc: UIViewController
        let mode = UserDefaults.standard.string(forKey: "Mode")
        

        if Auth.auth().currentUser == nil {
            vc = storyboard.instantiateViewController(withIdentifier: "SignInVC")
            window.rootViewController = vc
            self.window = window
            window.makeKeyAndVisible()
            guard let _ = (scene as? UIWindowScene) else { return }
            return
        }
//        userModel.getUserInfo()
        let userModel = UserInfo.info
        if mode == "StreamingVC" {
            storyboard = UIStoryboard(name: "CamMode", bundle: nil)
            vc = storyboard.instantiateViewController(withIdentifier: "StreamingVC")
            
        } else {
            vc = storyboard.instantiateViewController(withIdentifier: "WatchTabbar")
        }
        window.rootViewController = vc
        self.window = window
        window.makeKeyAndVisible()
        
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }


}

