//
//  NoticeModel.swift
//  PetCam
//
//  Created by 양윤석 on 3/12/24.
//

import Foundation
import FirebaseDatabase
import UIKit

struct NoticeList: Codable {
    let date: Double
    let notice: String
    let title: String
    let titleDate: String
    let image: String
    let url: String
}

class NoticeModel {
    var databaseRef = Database.database().reference()
    var noticeList: [NoticeList] = []
    var imageDict: [String:UIImage] = [:]
    var fbModel = FirebaseModel.fb
    func currentNotices(completion: @escaping () -> Void) {
        let path = "PetCam/Notices/"
        databaseRef.child(path).getData { error, snapData in
            guard let dict = snapData?.value as? [String:Any] else {return}
            let data = try! JSONSerialization.data(withJSONObject: Array(dict.values), options: [])
            do {
                let decoder = JSONDecoder()
                let list = try decoder.decode([NoticeList].self, from: data)
                self.noticeList = list.sorted(by: {$0.date > $1.date})
                completion()
//                self.setImage(list: self.noticeList) {
//                    print("completion()")
//                    completion()
//                }
                
                
                
            } catch let error {
                print("get Firebase data error", error)
            }
            
        }

    }
    
    func setImage(list: [NoticeList], completion: @escaping () -> Void) {
        var imgList: [String: UIImage] = [:]
        for i in list {
            let imageURL = i.image
            if let image = ImageCachManager.shared.object(forKey: imageURL as NSString) {
//                imageDict[imageURL] = image
                imgList[imageURL] = image
                print("object", imageDict)
                
                
            } else {
                fbModel.downloadImage(urlString: imageURL) { image in
                    guard let img = image else {
                        print("get downloadImage error setImage()")
                        return
                    }
                    ImageCachManager.shared.setObject(img, forKey: imageURL as NSString)
//                    self.imageDict[imageURL] = img
                    imgList[imageURL] = img
                    print("setObject",imgList)
                }
            }
        }
        imageDict = imgList
        print("setImage", imageDict)
        completion()

        
    }
    
    func testImage() -> UIImage {
        let defaultImage = UIImage(systemName: "person.crop.circle.fill")!
        let url = URL(string: "https://drive.google.com/file/d/10tX4gbDuAPoDUM5AdVj9K1_qfmWFGrqf/view?usp=sharing")!
        guard let data = try? Data(contentsOf: url) else {return defaultImage}
        guard let photoImage = UIImage(data: data) else {return defaultImage}
        
        let imagePng = photoImage.pngData()
//        UserDefaults.standard.set(imagePng, forKey: photoURL.description)
        return photoImage
    }
    
    
}
