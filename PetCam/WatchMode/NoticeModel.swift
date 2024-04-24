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
}

class NoticeModel {
    var databaseRef = Database.database().reference()
    var noticeList: [NoticeList] = []
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
                
            } catch let error {
                print("get Firebase data error", error)
            }
            
        }

    }
}
