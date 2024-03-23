//
//  UserInfoModel.swift
//  PetCam
//
//  Created by 양윤석 on 3/19/24.
//

import Foundation
import UIKit
import FirebaseAuth

class UserInfoModel {
//    let fbModel = FirebaseModel()
    func setUserImage(photoURL: URL) -> UIImage? {
        let defaultImage = UIImage(systemName: "person.crop.circle.fill")
        if let image = UserDefaults.standard.data(forKey: photoURL.description) {
            return UIImage(data: image)
        } else {
            guard let data = try? Data(contentsOf: photoURL) else {return defaultImage}
            guard let photoImage = UIImage(data: data) else {return defaultImage}
            
            let imagePng = photoImage.pngData()
            UserDefaults.standard.set(imagePng, forKey: photoURL.description)
            return photoImage
            
        }
        
    }
}
