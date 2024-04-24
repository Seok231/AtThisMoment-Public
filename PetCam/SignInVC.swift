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

class SignInVC: UIViewController {
    let moveVC = MoveViewControllerModel()
    fileprivate var currentNonce: String?
    @IBOutlet weak var backgroundView: UIImageView!
    @IBOutlet weak var appleSignInView: UIImageView!
    @IBOutlet weak var googleSignIn: UIImageView!
    

    @objc func appleEvent(tapGestureRecognizer: UITapGestureRecognizer) {
        startSignInWithAppleFlow()
    }
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer){
        startSignInWithGoogle()
    }
    override func viewDidAppear(_ animated: Bool) {
        
        moveToVC()
    }
    func moveToVC() {
        if let auth = Auth.auth().currentUser {
            print("signin : ", auth.uid)
            
            self.present(moveVC.moveToVC(storyboardName: "Main", className: "WatchTabbar"), animated: true)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundView.image = UIImage(named: "main")
        
        // Google SignInBT Event
        let tapImageViewRecognizer = UITapGestureRecognizer(target: self, action:#selector(imageTapped(tapGestureRecognizer:)))
        //이미지뷰가 상호작용할 수 있게 설정
        googleSignIn.isUserInteractionEnabled = true
        //이미지뷰에 제스처인식기 연결
        googleSignIn.addGestureRecognizer(tapImageViewRecognizer)
        googleSignIn.image = UIImage(named: "googleBT")
        googleSignIn.layer.cornerRadius = 20
        
        let apple = UITapGestureRecognizer(target: self, action: #selector(appleEvent(tapGestureRecognizer:)))
        appleSignInView.isUserInteractionEnabled = true
        appleSignInView.addGestureRecognizer(apple)
//        appleBT.setImage(UIImage(named: "appleBTW"), for: .normal)
//        appleBT.setTitle("", for: .normal)
        appleSignInView.image = UIImage(named: "appleBT")
    }
}


extension SignInVC {
    func startSignInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            return }

        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: self) {
            [unowned self] result, error in
        guard error == nil else {return}
            guard let user = result?.user, let idToken = user.idToken?.tokenString else {return}
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            Auth.auth().signIn(with: credential) { result, error in
                guard let result = result else{
                    print("get userInfo error")
                    return
                }
                
                guard let name = result.user.displayName else
                { print("displayName error")
                    return}
                let auth = Auth.auth().currentUser
                let userInfo = UserInfo.info
                
                
                userInfo.userInfoInit(user: result.user)
                userInfo.creatUser(name: name, user: result.user)
                
                self.present(self.moveVC.moveToVC(storyboardName: "Main", className: "WatchTabbar"), animated: true)
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
            guard let code = appleIDCredential.authorizationCode, let codeString = String(data: code, encoding: .utf8) else {
                print("Authorization code is missing or not decodable")
                return
            }
            
            // 여기에서 서버로 토큰 갱신 요청을 보냅니다.
            fetchRefreshToken(from: codeString)
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)

            
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    print ("Error Apple sign in: %@", error)
                    return
                }
                guard let result = result else {return}
                let userInfo = UserInfo.info
                let fullName = appleIDCredential.fullName
                userInfo.userInfoInit(user: result.user)
                self.setAppleIDName(personNameComponents: fullName, result: result)
 
                self.present(self.moveVC.moveToVC(storyboardName: "Main", className: "WatchTabbar"), animated: true)
            }
        }
    }
    func setAppleIDName(personNameComponents: PersonNameComponents?, result: AuthDataResult?) {
        guard let components = personNameComponents else {return}
        guard let givenName = components.givenName else {return}
        guard let familyName = components.familyName else {return}
        let name = givenName + familyName
        let auth = Auth.auth().currentUser
        let changeRequest = auth?.createProfileChangeRequest()
        changeRequest?.displayName = name
        changeRequest?.commitChanges(completion: { error in
            if let er = error {
                print("changeRequest error", er)
            }
        })
        guard let user = result?.user else{
            print("get userInfo error")
            return
        }
        let userInfo = UserInfo.info
        userInfo.creatUser(name: name, user: user)
        
        userInfo.name = name
    }
    func setUserInfo() {
        
    }

    func fetchRefreshToken(from code: String) {
        guard let url = URL(string: "http://diddbstjr55.iptime.org:8002/refresh_token?code=\(code)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let refreshToken = jsonResponse["refresh_token"] as? String {
                    // 토큰을 UserDefaults에 저장합니다.
                    UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
                    print("Refresh token saved: \(refreshToken)")
                }
            } catch let parsingError {
                print("Error parsing JSON: \(parsingError)")
            }
        }
        
        task.resume()
    }

}
extension SignInVC : ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
