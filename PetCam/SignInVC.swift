//
//  ViewController.swift
//  PetCam
//
//  Created by 양윤석 on 2/16/24.
//

import UIKit
import GoogleSignIn
import FirebaseAuth
import FirebaseCore

class SignInVC: UIViewController {
    let fbModel = FirebaseModel.fb
    let moveVC = MoveViewControllerModel()
    @IBOutlet weak var googleSignIn: GIDSignInButton!
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
        {
            guard let clientID = FirebaseApp.app()?.options.clientID else { 
                print("ClientID")
                return }

            // Create Google Sign In configuration object.
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            GIDSignIn.sharedInstance.signIn(withPresenting: self) {
                [unowned self] result, error in
            guard error == nil else {return}
                guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                    print("test")
                    return
                }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
                Auth.auth().signIn(with: credential) { result, error in
                    
                    self.fbModel.creatUser()
                    if let auth = Auth.auth().currentUser {
                        print("credential", auth.uid)
                    }
                    self.present(self.moveVC.moveToVC(storyboardName: "Main", className: "SelectModeVC"), animated: true)
                }
            }
    }
    override func viewWillAppear(_ animated: Bool) {
        
    }

    override func viewDidAppear(_ animated: Bool) {
        userInfo()
    }
    func userInfo() {
        if let auth = Auth.auth().currentUser {
            print("signin : ", auth.uid)
            
            self.present(moveVC.moveToVC(storyboardName: "Main", className: "SelectModeVC"), animated: true)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Google SignInBT Event
        let tapImageViewRecognizer = UITapGestureRecognizer(target: self, action:#selector(imageTapped(tapGestureRecognizer:)))
        //이미지뷰가 상호작용할 수 있게 설정
        googleSignIn.isUserInteractionEnabled = true
        //이미지뷰에 제스처인식기 연결
        googleSignIn.addGestureRecognizer(tapImageViewRecognizer)
    }
    
    
}
