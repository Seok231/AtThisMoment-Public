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
import AuthenticationServices
import CryptoKit
import SRTHaishinKit

class SignInVC: UIViewController {
//    let fbModel = FirebaseModel.fb

    let moveVC = MoveViewControllerModel()
    @IBOutlet weak var signInAppleBT: ASAuthorizationAppleIDButton!
    fileprivate var currentNonce: String?
    @IBOutlet weak var appleSignInBT: UIButton!
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
                    let fbModel = FirebaseModel.fb
                    fbModel.signIn()
                    fbModel.creatUser()
                    self.present(self.moveVC.moveToVC(storyboardName: "Main", className: "SelectModeVC"), animated: true)
                }
            }
    }
    @IBAction func appleSignIn(_ sender: Any) {
        startSignInWithAppleFlow()
    }
    override func viewWillAppear(_ animated: Bool) {
//        userInfo()
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
        
        
        let bt = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        signInAppleBT = bt
    }
    
    
}

extension SignInVC: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
            
            
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    print ("Error Apple sign in: %@", error)
                    return
                }
                // User is signed in to Firebase with Apple.
                // ...
                let changeRequest = result?.user.createProfileChangeRequest()
                let fullName = appleIDCredential.fullName
//                print("fullName",fullName?.givenName)
                changeRequest?.displayName = (fullName?.givenName ?? "") + (fullName?.familyName ?? "")
                changeRequest?.commitChanges(completion: { error in
                    if let er = error {
                        print("changeRequest error", er)
                    }
                })
                
                let fbModel = FirebaseModel.fb
                fbModel.signIn()
                fbModel.creatUser()
                if let auth = Auth.auth().currentUser {
                    print("credential", auth.uid)
                    print("displayName", auth.displayName ?? "")
                }
                self.present(self.moveVC.moveToVC(storyboardName: "Main", className: "SelectModeVC"), animated: true)
            }
        }
    }
}

//Apple Sign in
extension SignInVC {
    func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
}

extension SignInVC : ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

