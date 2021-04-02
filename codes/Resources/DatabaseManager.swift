//
//  DatabaseManager.swift
//  Study_Match
//
//  on 2020/10/28.
//  Copyright © 2020 yusho. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseDatabase
import FirebaseAuth
import MessageKit

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    private let firestore = Firestore.firestore()
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}



// MARK: - Account Management

extension DatabaseManager {
    
    /// realtime databaseに登録されているかどうかをチェック
    // ruleをtrueにした
    public func userExists(with email: String,
                           completion: @escaping ((Bool) -> Void)) {
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        database.child("users/\(safeEmail)/email").observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    
    // conversaionIdが２個できないように"\(mySafeEmail)-\(partnerSafeEmail)"をチェック
    // お互いの会話履歴がない状態で、同時にチャットルームを開いた時のため
    public func checkTowConversation(with conversationId: String, partnerEmail: String, completion: @escaping (Bool) -> Void) {
        
        let path = "allConversations/\(partnerEmail)/\(conversationId)"
        database.child(path).observeSingleEvent(of: .value) { (snapshot) in
            if let _ = snapshot.value as? [String: Any] {
                completion(true)
                return
            }
            completion(false)
        }
    }
    
    ///profile pictureをusersに入れる
    public func insertProfileToUsers(with email: String, url: String, completion: @escaping (Bool) -> Void) {
        let path = "users/\(email)/info"
        database.child(path).updateChildValues(["picture": url]) { (error, _) in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    
    public func fetchFollowMember(friendEmail: String, completion: @escaping (Result<[String], Error>) -> Void) {
        
        let path = "users/\(friendEmail)/フォロー"
        
        database.child(path).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let friendsMember = snapshot.value as? [String] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(friendsMember))
        })
    }
    
    
    // 新規登録後の最初に users/\(safeMyEmail)/uidに自分のuidをセットする
    // realtimeのルールのため
    public func insertUID(myEmail: String,  completion: @escaping (Bool) -> Void) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        database.child("users/\(myEmail)/uid").setValue(uid) { [weak self](error, _) in
            guard error == nil else {
                completion(false)
                return
            }
            let myPath = "users/\(myEmail)/フォロワー"
            self?.database.child(myPath).setValue(["nil"])
            let emailPath = "users/\(myEmail)/email"
            self?.database.child(emailPath).setValue(myEmail)
            self?.firestore.collection("posts_individual").document(myEmail).setData(["uid": uid])
            completion(true)
        }
    }
    
    /// 新規登録して、ユーザーの情報をprofileInfoを保存
    public func insertProfileInfo(myEmail: String, info: ProfileInfo, isPreviousInfo: ProfileInfo?, completion: @escaping (Bool) -> Void) {
        
        
        let path = "users/\(myEmail)/info"
        
        if let previousInfo = isPreviousInfo,
           previousInfo.university != "" {
            let previousPath = "search/\(info.age)/fac-dep/\(previousInfo.university)/\(previousInfo.faculty)/\(previousInfo.department)/\(myEmail)"
            database.child(previousPath).removeValue()
            let uniMemberPath = "search/\(info.age)/university-member/\(previousInfo.university)/\(myEmail)"
            database.child(uniMemberPath).removeValue()
        }
    

        if info.university != "" {
            let searchUniversityPath = "search/\(info.age)/fac-dep/\(info.university)/\(info.faculty)/\(info.department)/\(myEmail)"
            let uniMemberPath = "search/\(info.age)/university-member/\(info.university)/\(myEmail)"
            
            let date1 = Date()
            let format = DateFormatter()
            format.dateFormat = "yyMMdd HHmmss"
            format.timeZone   = TimeZone(identifier: "Asia/Tokyo")
            let dateString = format.string(from: date1)
            let dataUni = [
                "time": dateString,
                "email": myEmail
            ]
            database.child(searchUniversityPath).updateChildValues(dataUni)
            database.child(uniMemberPath).updateChildValues(dataUni)
        }
        
        
        let data: [String: String] = [
            "name": info.name,
            "picture": info.picutre,
            "introduction": info.introduction,
            "age": info.age,
            "university": info.university,
            "faculty": info.faculty,
            "department": info.department,
            "friendCount": info.friendCount,
        ]
        database.child(path).updateChildValues(data) { (error, _) in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    // 自分の検索結果の順番を上げる
    public func reloadMySearch(myEmail: String, info: ProfileInfo) {
        if info.university != "" {
            let date1 = Date()
            let format = DateFormatter()
            format.dateFormat = "yyMMdd HHmmss"
            format.timeZone   = TimeZone(identifier: "Asia/Tokyo")
            let dateString = format.string(from: date1)
            let dataUni = [
                "time": dateString,
                "email": myEmail
            ]
            
            let previousPath = "search/\(info.age)/fac-dep/\(info.university)/\(info.faculty)/\(info.department)/\(myEmail)"
            database.child(previousPath).setValue(dataUni)
            let uniMemberPath = "search/\(info.age)/university-member/\(info.university)/\(myEmail)"
            database.child(uniMemberPath).setValue(dataUni)
        }
        
    }
    
    
    
    public func fetchSearchPath(searchPath: String, isOnlyUni: Bool, age: String, completion: @escaping (Result<[String], Error>) -> Void) {
        
        if isOnlyUni == true {
            let pathUni = "search/\(age)/university-member/\(searchPath)/"
            database.child(pathUni).observeSingleEvent(of: .value) { (snapshot) in
                guard let membersNode = snapshot.value as? [String: Any] else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                
                var emailArray = [[String: String]]()
                for memberNode in membersNode {
                    if let member = memberNode.value as? [String: String] {
                        guard let email = member["email"],
                              let time = member["time"] else {
                            return
                        }
                        emailArray.append(["email": email, "time": time])
                    }
                }
                
                emailArray.sort { (a, b) -> Bool in
                    a["time"] ?? "" > b["time"] ?? ""
                }
                var emailArray1 = [String]()
                for email1 in emailArray {
                    emailArray1.append(email1["email"] ?? "")
                }
                completion(.success(emailArray1))
            }
            return
        }
        else {
            let path = "search/\(age)/fac-dep/\(searchPath)/"
            database.child(path).observeSingleEvent(of: .value) { (snapshot) in
                guard let searchValues = snapshot.value as? [String: Any] else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                
                var emailArray = [[String: String]]()
                for searchvalue in searchValues {
                    if let faculyNode  = searchvalue.value as? [String: String] {
                        guard let email = faculyNode["email"],
                              let time = faculyNode["time"] else {
                            return
                        }
                        emailArray.append(["email": email, "time": time])
                    }
                    else {
                        if let facultyNodes = searchvalue.value as? [String: Any] {
                            for facultyNode in facultyNodes {
                                if let departmentNode = facultyNode.value as? [String: String] {
                                    guard let email = departmentNode["email"],
                                          let time = departmentNode["time"] else {
                                        return
                                    }
                                    emailArray.append(["email": email, "time": time])
                                }
                            }
                        }
                    }
                }
                
                emailArray.sort { (a, b) -> Bool in
                    a["time"] ?? "" > b["time"] ?? ""
                }
                var emailArray1 = [String]()
                for email1 in emailArray {
                    emailArray1.append(email1["email"] ?? "")
                }
                completion(.success(emailArray1))
            }
        }
        
    }
    
    
    // FriendProfileVCのプロファイルの情報をfetch
    public func fetchUserInfo(userEmail: String, completion: @escaping (Result<ProfileInfo, Error>) -> Void) {
        let path = "users/\(userEmail)/info"
        database.child(path).observeSingleEvent(of: .value) { (snapshot) in
            guard let info = snapshot.value as? [String: String] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            guard let name = info["name"],
                  let picture = info["picture"],
                  let introduction = info["introduction"],
                  let age = info["age"],
                  let faculty = info["faculty"],
                  let university = info["university"],
                  let department = info["department"],
                  let count = info["friendCount"] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let userInfo = ProfileInfo(name: name, picutre: picture, introduction: introduction, age: age, university: university, faculty: faculty, department: department, friendCount: count)
            completion(.success(userInfo))
        }
    }
    
        
    public enum DatabaseError: Error {
        case failedToFetch
    }
        
}









// MARK: - Sending Message / conversations

extension DatabaseManager {
    
    // conversations Nodeを作る
    public func createNewConversation(with partnerSafeEmail: String, partnerName: String, firstMessage: Message, conversationId: String, completion: @escaping (Bool) -> Void) {
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String,
            let myName = UserDefaults.standard.value(forKey: "name") as? String else {
                return
        }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(let photoItem):
            if let urlString = photoItem.url?.absoluteString {
                message = urlString
            }
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        let newConversationData: [String: Any] = [
            "id": conversationId,
            "partner_email": partnerSafeEmail,
            "partner_name": partnerName,
            "my_name": myName, // could functions
            "partner_notification": true, // could functions need both
            "my_notification": true,
            "latest_message": [
                "date": dateString,
                "message": message,
                "sender": safeMyEmail,
                "is_read": true
            ]
        ]
        
        let recipient_newConversationData: [String: Any] = [
            "id": conversationId,
            "partner_email": safeMyEmail,
            "partner_name": myName,
            "my_name": partnerName, // could functions
            "partner_notification": true,
            "my_notification": true,
            "latest_message": [
                "date": dateString,
                "message": message,
                "sender": safeMyEmail,
                "is_read": false
            ]
        ]
        
        //  自分のemailのノードに追加＆createする
        database.child("all_users/\(safeMyEmail)/conversations/\(conversationId)").updateChildValues(newConversationData)
        //  相手のemailのノードに追加＆createする
        database.child("all_users/\(partnerSafeEmail)/conversations/\(conversationId)").updateChildValues(recipient_newConversationData) { [weak self](error, _) in
            guard error == nil else {
                completion(false)
                return
            }
            self?.finishCreateNewConversation(firstMessage: firstMessage, message: message, partnerName: partnerName, partnerEmail: partnerSafeEmail, mySafeEmail: safeMyEmail, dateString: dateString, conversationId: conversationId, completion: completion)
        }
    }
    
    
    private func finishCreateNewConversation(firstMessage: Message, message: String, partnerName: String, partnerEmail: String, mySafeEmail: String, dateString: String, conversationId: String, completion: @escaping (Bool) -> Void) {

        
        let conversationNode: [String: Any] = [
            "id": firstMessage.messageId,
            "content": message,
            "sender_email": mySafeEmail,
            "date": dateString,
            "type": firstMessage.kind.messageKingString,
            "is_Read": false
        ]
        
        
//        let value = [
//            conversationNode
//        ]
        
        database.child("allConversations/\(partnerEmail)/\(conversationId)/\(dateString)").updateChildValues(conversationNode)
        database.child("allConversations/\(mySafeEmail)/\(conversationId)/\(dateString)").updateChildValues(conversationNode, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    
    // ConversationVCで表示されるcell情報を取得
    public func getAllConversations(for mySafeEmail: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        
        database.child("all_users/\(mySafeEmail)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [String: Any] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            var conversationArray = [Conversation]()
            for currentConversation in value {
                if let dictionary = currentConversation.value as? [String: Any],
                   let conversationId = dictionary["id"] as? String,
                   let partnerName = dictionary["partner_name"] as? String,
                   let partnerEmail = dictionary["partner_email"] as? String,
                   let myNotification = dictionary["my_notification"] as? Bool,
                   let latestMessage = dictionary["latest_message"] as? [String: Any],
                   let dateString = latestMessage["date"] as? String,
                   let isRead = latestMessage["is_read"] as? Bool,
                   let message = latestMessage["message"] as? String {
                    
                    let date = ChatViewController.dateFormatter.date(from: dateString)
                    guard let rowDate = date else {
                        return
                    }
                    let latestMessage1 = LatestMessage(date: rowDate, text: message, isRead: isRead)
                    let conversation = Conversation(id: conversationId, partner_name: partnerName, partner_email: partnerEmail, notification: myNotification, latest_message: latestMessage1)
                    conversationArray.append(conversation)
                }
                
            }
            completion(.success(conversationArray))
        })
    }
    
    
    
    // messagesを読み取り、ChatVCに表示
    public func getAllMessagesForConversation(with conversationId: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                return
        }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        database.child("allConversations/\(safeMyEmail)/\(conversationId)").observe(.value) { (snapshot) in
            guard let values = snapshot.value as? [String: Any] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            var messages = [Message]()
            for value in values {
                if let dictionary = value.value as? [String: Any],
                   let email = dictionary["sender_email"] as? String,
                   let content = dictionary["content"] as? String,
                   let sentDateString = dictionary["date"] as? String,
                   let sentDate = ChatViewController.dateFormatter.date(from: sentDateString),
                   let type = dictionary["type"] as? String,
                   let isRead = dictionary["is_Read"] as? Bool,
                   let messageId = dictionary["id"] as? String {
                    
                    let sender = Sender(photoURL: "", senderId: email, displayName: "other")
                    var kind: MessageKind?
                    if type == "photo" {
                        guard let url = URL(string: content),
                              let placeholder = UIImage(systemName: "plus") else {
                            return
                        }
                        let media = Media(url: url,
                                          image: nil,
                                          placeholderImage: placeholder,
                                          size: CGSize(width: 250, height: 250))
                        kind = .photo(media)
                    }
                    else {
                        kind = .text(content)
                    }
                    guard let finalKind = kind else {
                        return
                    }
                    messages.append(Message(sender: sender, messageId: messageId, sentDate: sentDate, isRead: isRead, kind: finalKind))
                }
            }
            
            messages = messages.sorted(by: { (a, b) -> Bool in
                a.sentDate < b.sentDate
            })
            
            completion(.success(messages))
        }
    }
    
    
    // 特定のconversation Nodeにmessageを送る
    public func sendMessage(to conversationId: String, safePartnerEmail: String, recievedName: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                return
        }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)

        var message = ""
        let messageDate = newMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        switch newMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(let photoItem):
            if let urlString = photoItem.url?.absoluteString {
                message = urlString
            }
            break
        case .video(let videoItem):
            if let urlString = videoItem.url?.absoluteString {
                message = urlString
            }
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        let conversationMyNode: [String: Any] = [
            "id": newMessage.messageId,
            "content": message,
            "sender_email": safeMyEmail,
            "date": dateString,
            "type": newMessage.kind.messageKingString,
            "is_Read": false
        ]
        
        let conversationPartnerNode: [String: Any] = [
            "id": newMessage.messageId,
            "content": message,
            "sender_email": safeMyEmail,
            "date": dateString,
            "type": newMessage.kind.messageKingString,
            "is_Read": true
        ]
        
//        let dataNode = [
//            conversationNode
//        ]
//
//            currentMessageNode.append(conversationNode)
//
        database.child("allConversations/\(safeMyEmail)/\(conversationId)/\(dateString)").updateChildValues(conversationMyNode)
        database.child("allConversations/\(safePartnerEmail)/\(conversationId)/\(dateString)").updateChildValues(conversationPartnerNode, withCompletionBlock: { [weak self] error, _ in
            guard error == nil,
                  let strongSelf = self else {
                completion(false)
                return
            }
            
            let newData: [String: Any] = [
                "date": dateString,
                "message": message,
                "sender": safeMyEmail,
                "is_read": true
            ]
            let partner_newData: [String: Any] = [
                "date": dateString,
                "message": message,
                "sender": safeMyEmail,
                "is_read": false
            ]
            
            strongSelf.database.child("all_users/\(safeMyEmail)/conversations/\(conversationId)/latest_message").updateChildValues(newData)
            strongSelf.database.child("all_users/\(safePartnerEmail)/conversations/\(conversationId)/latest_message").updateChildValues(partner_newData)
            
            completion(true)
            
        })
    }
    
    
    
    // post → profileのchatStartButtonを押した時に、conversation履歴があるかどうか
    public func checkExistConversation(partnerEmail: String, safeMyEmail: String, completion: @escaping (Result<String, Error>) -> Void) {
        let path = "all_users/\(safeMyEmail)/conversations"
        database.child(path).observeSingleEvent(of: .value) { (snapshot) in
            guard let conversationNode = snapshot.value as? [String: Any] else {
                completion(.success("nil"))
                return
            }
            
            for conversation in conversationNode {
                guard let value = conversation.value as? [String: Any],
                      let email = value["partner_email"] as? String,
                      let conversationId = value["id"] as? String else {
                    completion(.failure(DatabaseError.failedToFetch))
                    print("failed to convert (guard let else)")
                    return
                }
                if partnerEmail == email {
                    //自分との会話履歴が存在
                    completion(.success(conversationId))
                    return
                }
            }
            // 自分との会話履歴がなく、初めてメッセージを送信準備する場合
            completion(.success("nil"))
        }
    }
    
    
    
    
    // 既読しました(ChatVC)
    public func iReadMessage(conversationId: String, partnerEmail: String, date: Date) {

        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        format.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let dateString = format.string(from: date)
        
        let path = "allConversations/\(partnerEmail)/\(conversationId)/\(dateString)"
        let data: [String: Bool] = [
            "is_Read": true
        ]
        database.child(path).updateChildValues(data)
    }
    // 既読しました(ConversationVC)
    public func iReadConversation(conversationId: String) {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: email)
        let path = "all_users/\(safeMyEmail)/conversations/\(conversationId)/latest_message"
        database.child(path).observeSingleEvent(of: .value) { [weak self](snapshot) in
            guard let value = snapshot.value as? [String: Any] else {
                return
            }
            if let isRead = value["is_read"] as? Bool {
                if isRead == false {
                    let data: [String: Bool] = [
                        "is_read": true
                    ]
                    self?.database.child(path).updateChildValues(data)
                }
            }
            
        }
    }
    
    
    // スワイプでチャットルームの削除
    public func deleteConversation(conversationId: String, completion: @escaping (Bool) -> Void) {
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{ return }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        database.child("all_users/\(safeEmail)/conversations/\(conversationId)/latest_message").removeValue()
        database.child("allConversations/\(safeEmail)/\(conversationId)").removeValue()
        completion(true)
    }

    //通知オフ
    public func notificationOffConversation(partnerEmail: String, conversationId: String) {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{ return }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        database.child("all_users/\(partnerEmail)/conversations/\(conversationId)/").updateChildValues(["partner_notification": false])
        database.child("all_users/\(safeEmail)/conversations/\(conversationId)/").updateChildValues(["my_notification": false])
    }
    
    //通知オン
    public func notificationOnConversation(partnerEmail: String, conversationId: String) {
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{ return }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        database.child("all_users/\(partnerEmail)/conversations/\(conversationId)/").updateChildValues(["partner_notification": true])
        database.child("all_users/\(safeEmail)/conversations/\(conversationId)/").updateChildValues(["my_notification": true])
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
 
    
    
    
    
    
    // MARK: - POST コミュニティ
    
    // 投稿する
    public func insertPostInfo(post: Post, dateForCollection: String, whichTable: Int, isAll: Bool, isUni: Bool, isFac: Bool, completion: @escaping (Bool) -> (Void)) {
        
        var year = "none"
        var uni = "none"
        var fac = "none"
        if let year1 = UserDefaults.standard.value(forKey: "year") as? String { year = year1 }
        if let uni1 = UserDefaults.standard.value(forKey: "uni") as? String { uni = uni1 }
        if let fac1 = UserDefaults.standard.value(forKey: "fac") as? String { fac = fac1 }
        
        var photo: [String] = ["nil"]
        if let photourl = post.photoUrl {
            let count = photourl.count
            if count == 1 {
                photo = [photourl[0]]
            }
            else if count == 2 {
                photo = [photourl[0], photourl[1]]
            }
            else if count == 3 {
                photo = [photourl[0], photourl[1], photourl[2]]
            }
            else if count == 4 {
                photo = [photourl[0], photourl[1], photourl[2], photourl[3]]
            }
        }
        
        
        let data: [String: Any] = [
            "postId": post.postId,
            "name": post.postName,
            "email": post.postEmail,
            "time": post.postTime,
            "message": post.postMessage,
            "good": post.good,
            "goodList": post.goodList,
            "remessage": post.remessage,
            "remessageList": post.remessagePostArray,
            "isRemessage": ["nil"],
            "comment": post.comment,
            "isComment": "nil",
            "photoUrl": photo,
            "task": ["nil"]
        ]
        
        
        firestore.collection("posts_individual").document(post.postEmail).collection("all_posts").document(post.postId).setData(data)
        
        if isAll == true {
            firestore.collection("posts_all").document("all_users").collection(dateForCollection).document(post.postId).setData(data) { (err) in
                guard err == nil else {
                    completion(false)
                    return
                }
                
                if isUni == false && isFac == false {
                    completion(true)
                }
            }
        }
        
//        if isUni == true {
//            guard year != "none" else { return }
//            guard uni != "none" else { return }
//            firestore.collection("posts_uni").document("\(uni)\(year)").collection(dateForCollection).document(post.postId).setData(data) { (err) in
//                guard err == nil else {
//                    completion(false)
//                    return
//                }
//                if isFac == false {
//                    completion(true)
//                }
//            }
//        }
        
        if isFac == true {
            guard year != "none" else { return }
            guard fac != "none" else { return }
            firestore.collection("posts_fac").document("\(uni)\(year)\(fac)").collection(dateForCollection).document(post.postId).setData(data) { (err) in
                
                guard err == nil else {
                    completion(false)
                    return
                }
                completion(true)
            }
        }
        
        
    }
    
    
    
    
    // 投稿する(task)
    public func insertShareTask(post: Post, dateForCollection: String, completion: @escaping (Bool) -> (Void)) {
        
        var year = "none"
        var uni = "none"
        var fac = "none"
        if let year1 = UserDefaults.standard.value(forKey: "year") as? String { year = year1 }
        if let uni1 = UserDefaults.standard.value(forKey: "uni") as? String { uni = uni1 }
        if let fac1 = UserDefaults.standard.value(forKey: "fac") as? String { fac = fac1 }
        
        
        var photo: [String] = ["nil"]
        if let photourl = post.photoUrl {
            let count = photourl.count
            if count == 1 {
                photo = [photourl[0]]
            }
            else if count == 2 {
                photo = [photourl[0], photourl[1]]
            }
            else if count == 3 {
                photo = [photourl[0], photourl[1], photourl[2]]
            }
            else if count == 4 {
                photo = [photourl[0], photourl[1], photourl[2], photourl[3]]
            }
        }
        
        
        let task: [String: Any] = [
            "taskId": post.shareTask?.taskId ?? "",
            "taskName": post.shareTask?.taskName ?? "",
            "taskLimit": post.shareTask?.taskLimit ?? "",
            "timeSchedule": post.shareTask?.timeSchedule ?? "",
            "documentPath": post.shareTask?.documentPath ?? "",
            "memberCount": post.shareTask?.memberCount ?? 0,
            "makedEmail": post.shareTask?.makedEmail ?? "",
            "doneMember": post.shareTask?.doneMember ?? [""],
            "gettingMember": post.shareTask?.gettingMember ?? [""],
            "wantToTalkMember": post.shareTask?.wantToTalkMember ?? [""]
        ]
        
        
        let data: [String: Any] = [
            "postId": post.postId,
            "name": post.postName,
            "email": post.postEmail,
            "time": post.postTime,
            "message": post.postMessage,
            "good": post.good,
            "goodList": post.goodList,
            "remessage": post.remessage,
            "remessageList": post.remessagePostArray,
            "isRemessage": ["nil"],
            "comment": post.comment,
            "isComment": "nil",
            "photoUrl": photo,
            "task": task
        ]
        
        
        firestore.collection("posts_individual").document(post.postEmail).collection("all_posts").document(post.postId).setData(data)
        
        guard year != "none" else { return }
        guard fac != "none" else { return }
        firestore.collection("posts_fac").document("\(uni)\(year)\(fac)").collection(dateForCollection).document(post.postId).setData(data) { (err) in
            
            guard err == nil else {
                completion(false)
                return
            }
            completion(true)
        }
        
        
    }
    
    
    
    
    
    
    // remessageの投稿
    public func insertRemessagePostInfo(post: Post, parentPost: Post, whichTable: Int, dateForCollection: String, isRemessage: Bool, isCommet: Bool, completion: @escaping (Bool) -> (Void)) {
        // isRemessage → リメッセージの投稿, isComment → コメントの投稿, isCommentOfComment → コメントの返信の親postId
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else { return }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        var photo: [String] = ["nil"]
        if let photourl = post.photoUrl {
            let count = photourl.count
            if count == 1 { photo = [photourl[0]] }
            else if count == 2 { photo = [photourl[0], photourl[1]] }
            else if count == 3 { photo = [photourl[0], photourl[1], photourl[2]] }
            else if count == 4 { photo = [photourl[0], photourl[1], photourl[2], photourl[3]] }
        }
        
        /*
         【流れ】
         ① (コメントやリピートをする時、その親投稿を取得する)
         ② 親投稿を取得したら、親投稿を編集（comment+1 / remessage+1）
         ③ 親投稿を更新
         ④ 自分の投稿をデータベースへ送る
         ⑤ 親投稿の人へ通知を送る
         
         バッチ機能使えば正確だし、更新回数が減るんじゃない？
         */
        
        
        
        // ① コメントやリピートをする時、その親投稿を取得する
        let dateString = parentPost.postTime
        
        let nowDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let postDate = formatter.date(from: dateString) ?? nowDate
        
        let changeFormatter = DateFormatter()
        changeFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyMM", options: 0, locale: nil)
        let beforeString = changeFormatter.string(from: postDate)
        let parentPostDay = beforeString.replacingOccurrences(of: "-", with: "")
        
        
        // documentId
        var postName = ""
        var docName = ""
        
        if whichTable == 0 { postName = "posts_all" }
        if whichTable == 1 { postName = "posts_fac" }
        var year = "none"
        var uni = "none"
        var fac = "none"
        if let year1 = UserDefaults.standard.value(forKey: "year") as? String { year = year1 }
        if let uni1 = UserDefaults.standard.value(forKey: "uni") as? String { uni = uni1 }
        if let fac1 = UserDefaults.standard.value(forKey: "fac") as? String { fac = fac1 }
        
        if whichTable == 0 { docName = "all_users" }
        if whichTable == 1 { docName = "\(uni)\(year)\(fac)" }

        // 親投稿もリピートやコメントをしているかもしれない
        var parentPostIsRemessage = "nil"
        if let pIsRemessage = parentPost.isRemessage {
            let pIsRemessagePostId = pIsRemessage.parentPostId
            parentPostIsRemessage = pIsRemessagePostId //親の親postId
        }

        
        // ③ 親投稿を更新
        // remessageの場合
        if isRemessage == true {
            
            //もし親投稿のisCommentがnilでなかったら、それはコメント
            if let commentOfcomment = parentPost.isComment {
                
                var grandPostId = ""
                var grandPostDay = ""
                if commentOfcomment.contains("|!|") == true {
                    // 3回目以上
                    let stringArray = commentOfcomment.components(separatedBy: "|!|")
                    guard stringArray.count == 2 else {
                        return
                    }
                    grandPostId = stringArray[0]
                    grandPostDay = String(grandPostId.suffix(4))
                }
                else {
                    // 2回目
                    grandPostDay = String(commentOfcomment.suffix(4))
                    grandPostId = commentOfcomment
                }
                
                firestore.collection("comment_posts").document(grandPostDay).collection(grandPostId).document(parentPost.postId).updateData(["remessageList": FieldValue.arrayUnion([safeMyEmail])])
                firestore.collection("comment_posts").document(grandPostDay).collection(grandPostId).document(parentPost.postId).updateData(["remessage": FieldValue.increment(Int64(1))], completion: { [weak self](err) in
                    
                    guard err == nil else {
                        completion(false)
                        return
                    }
                    
                    // ④ 自分の投稿をデータベースへ送る
                    var postRemessage = [String: Any]()
                    var remessageList = parentPost.remessagePostArray
                    remessageList.append(safeMyEmail)
                    if isRemessage == true {
                        postRemessage = [
                            "postMessage": parentPost.postMessage,
                            "postId": parentPost.postId,
                            "postEmail": parentPost.postEmail,
                            "postName": parentPost.postName,
                            "postTime": parentPost.postTime,
                            "good": parentPost.good,
                            "goodList": parentPost.goodList,
                            "remessage": parentPost.remessage + 1,
                            "remessageList": remessageList,
                            "isRemessage": parentPostIsRemessage,
                            "comment": parentPost.comment,
                            "isComment": parentPost.isComment ?? "nil",
                            "postUrl": parentPost.photoUrl ?? ["nil"]
                        ]
                    }
                    let data: [String: Any] = [
                        "postId": post.postId,
                        "name": post.postName,
                        "email": post.postEmail,
                        "time": post.postTime,
                        "message": post.postMessage,
                        "good": post.good,
                        "goodList": post.goodList,
                        "remessage": post.remessage,
                        "remessageList": post.remessagePostArray,
                        "isRemessage": postRemessage,
                        "comment": post.comment,
                        "isComment": "nil",
                        "photoUrl": photo
                    ]
                    
                    
                    // ④ 自分の投稿をデータベースへ送る
                    self?.firestore.collection("posts_individual").document(post.postEmail).collection("all_posts").document(post.postId).setData(data)
                    self?.firestore.collection(postName).document(docName).collection(dateForCollection).document(post.postId).setData(data) { [weak self](err) in
                        guard err == nil else {
                            completion(false)
                            return
                        }
                        
                        // ⑤ 親投稿の人へ通知を送る
                        if safeMyEmail != parentPost.postEmail {
                            let ndate: [String: Any] = [
                                "model": "repeat",
                                "id": post.postId,
                                "friendEmail": [safeMyEmail],
                                "is_read": false,
                                "time": post.postTime,
                                "whichTable": whichTable,
                                "textView": post.postMessage
                            ]
                            let notificationPath = "notification/\(parentPost.postEmail)/\(post.postTime)"
                            self?.database.child(notificationPath).updateChildValues(ndate)
                        }
                        
                        completion(true)
                        return
                    }
                })
                
            }
            else {
                // 1回目のrepeat
                firestore.collection("posts_individual").document(parentPost.postEmail).collection("all_posts").document(parentPost.postId).updateData(["remessageList": FieldValue.arrayUnion([safeMyEmail])])
                firestore.collection("posts_individual").document(parentPost.postEmail).collection("all_posts").document(parentPost.postId).updateData(["remessage": FieldValue.increment(Int64(1))])
                print(parentPost.postId)
                firestore.collection(postName).document(docName).collection(parentPostDay).document(parentPost.postId).updateData(["remessageList": FieldValue.arrayUnion([safeMyEmail])])
                firestore.collection(postName).document(docName).collection(parentPostDay).document(parentPost.postId).updateData(["remessage": FieldValue.increment(Int64(1))], completion: { [weak self](err) in
                    
                    guard err == nil else {
                        completion(false)
                        return
                    }
                    
                    // ④ 自分の投稿をデータベースへ送る
                    var postRemessage = [String: Any]()
                    var remessageList = parentPost.remessagePostArray
                    remessageList.append(safeMyEmail)
                    if isRemessage == true {
                        var shareData = [String: Any]()
                        if let task = parentPost.shareTask {
                            shareData = [
                                "taskId": task.taskId ,
                                "taskName": task.taskName,
                                "taskLimit": task.taskLimit,
                                "timeSchedule": task.timeSchedule,
                                "documentPath": task.documentPath,
                                "memberCount": task.memberCount,
                                "makedEmail": task.makedEmail,
                                "doneMember": task.doneMember,
                                "gettingMember": task.gettingMember,
                                "wantToTalkMember": task.wantToTalkMember,
                            ]
                        }
                        
                        postRemessage = [
                            "postMessage": parentPost.postMessage,
                            "postId": parentPost.postId,
                            "postEmail": parentPost.postEmail,
                            "postName": parentPost.postName,
                            "postTime": parentPost.postTime,
                            "good": parentPost.good,
                            "goodList": parentPost.goodList,
                            "remessage": parentPost.remessage + 1,
                            "remessageList": remessageList,
                            "isRemessage": parentPostIsRemessage,
                            "comment": parentPost.comment,
                            "isComment": "nil",
                            "postUrl": parentPost.photoUrl ?? ["nil"],
                            "shareTask": shareData,
                        ]
                    }
                    let data: [String: Any] = [
                        "postId": post.postId,
                        "name": post.postName,
                        "email": post.postEmail,
                        "time": post.postTime,
                        "message": post.postMessage,
                        "good": post.good,
                        "goodList": post.goodList,
                        "remessage": post.remessage,
                        "remessageList": post.remessagePostArray,
                        "isRemessage": postRemessage,
                        "comment": post.comment,
                        "isComment": "nil",
                        "photoUrl": photo,
                    ]
                    
                    
                    // ④ 自分の投稿をデータベースへ送る
                    self?.firestore.collection("posts_individual").document(post.postEmail).collection("all_posts").document(post.postId).setData(data)
                    self?.firestore.collection(postName).document(docName).collection(dateForCollection).document(post.postId).setData(data) { [weak self](err) in
                        guard err == nil else {
                            completion(false)
                            return
                        }
                        
                        // ⑤ 親投稿の人へ通知を送る
                        if safeMyEmail != parentPost.postEmail {
                            let ndate: [String: Any] = [
                                "model": "repeat",
                                "id": post.postId,
                                "friendEmail": [safeMyEmail],
                                "is_read": false,
                                "time": post.postTime,
                                "whichTable": whichTable,
                                "textView": post.postMessage
                            ]
                            let notificationPath = "notification/\(parentPost.postEmail)/\(post.postTime)"
                            self?.database.child(notificationPath).updateChildValues(ndate)
                        }
                        
                        completion(true)
                        return
                    }
                })
            }
            
        }
        
        
        
        
        
        
        
        
        // ③ 親投稿を更新
        // commentの場合
        if isCommet == true {
            //もし親投稿のisCommentがnilでなかったら、それはコメント
            /*
                UserPostでtableVieeHeaderに表示させるために
                isComment = "\(親の投稿id) |!| \(親の親の投稿id)"
            */
            
            if let commentOfcomment = parentPost.isComment {
                // 2回目以上のコメント
                /*
                    2回目の投稿は親(1回目)投稿のisCommentが"\(親の投稿id)"
                    3回目の投稿は親(2回目)投稿のisCommentが"\(親の投稿id) |!| \(親の親の投稿id)"
                 
                 */
                
                var grandPostId = ""
                var grandPostDay = ""
                if commentOfcomment.contains("|!|") == true {
                    // 3回目以上
                    let stringArray = commentOfcomment.components(separatedBy: "|!|")
                    guard stringArray.count == 2 else {
                        return
                    }
                    grandPostId = stringArray[0]
                    grandPostDay = String(grandPostId.suffix(4))
                }
                else {
                    // 2回目
                    grandPostDay = String(commentOfcomment.suffix(4))
                    grandPostId = commentOfcomment
                }
                
                firestore.collection("comment_posts").document(grandPostDay).collection(grandPostId).document(parentPost.postId).updateData(["comment": FieldValue.increment(Int64(1))], completion: { [weak self](err) in
                    
                    guard err == nil else {
                        completion(false)
                        return
                    }
                    
                    var myIsComment = ""
                    if commentOfcomment.contains("|!|") == true {
                        // 3回目以上
                        let stringArray = commentOfcomment.components(separatedBy: "|!|")
                        guard stringArray.count == 2 else {
                            return
                        }
                        grandPostId = stringArray[0]
                        myIsComment = "\(parentPost.postId)|!|\(grandPostId)"
                    }
                    else {
                        // 2回目
                        myIsComment = "\(parentPost.postId)|!|\(commentOfcomment)"
                    }
                    
                    
                    // ④ 自分の投稿をデータベースへ送る
                    let data: [String: Any] = [
                        "postId": post.postId,
                        "name": post.postName,
                        "email": post.postEmail,
                        "time": post.postTime,
                        "message": post.postMessage,
                        "good": post.good,
                        "goodList": post.goodList,
                        "remessage": post.remessage,
                        "remessageList": post.remessagePostArray,
                        "isRemessage": ["nil"],
                        "comment": post.comment,
                        "isComment": myIsComment,
                        "photoUrl": photo
                    ]
                    
                    
                    // ④ 自分の投稿をデータベースへ送る
                    self?.firestore.collection("comment_posts").document(parentPostDay).collection(parentPost.postId).document(post.postId).setData(data)
                    
                    completion(true)
                    // ⑤ 親投稿の人へ通知を送る
                    if safeMyEmail != parentPost.postEmail {
                        let ndate: [String: Any] = [
                            "model": "replay",
                            "id": "\(post.postId)|!|\(parentPost.postId)",
                            "friendEmail": [safeMyEmail],
                            "is_read": false,
                            "time": post.postTime,
                            "whichTable": whichTable,
                            "textView": post.postMessage
                        ]
                        let notificationPath = "notification/\(parentPost.postEmail)/\(post.postTime)"
                        self?.database.child(notificationPath).updateChildValues(ndate)
                        return
                    }
                })
                
            }
            
            
            // 1回目のコメント
            else {
                // if let commentOfcomment = parentPost.isComment
                // このif letが失敗した時の処理
                // 普通の投稿をコメントする時に走る
                
                // ③ 親投稿を更新
                firestore.collection("posts_individual").document(parentPost.postEmail).collection("all_posts").document(parentPost.postId).updateData(["comment": FieldValue.increment(Int64(1))])
                firestore.collection(postName).document(docName).collection(parentPostDay).document(parentPost.postId).updateData(["comment": FieldValue.increment(Int64(1))], completion: { [weak self](err) in
                    
                    
                    guard err == nil else {
                        completion(false)
                        return
                    }
                    
                    let myIsComment = parentPost.postId
                    
                    // ④ 自分の投稿をデータベースのデータを作る
                    let data: [String: Any] = [
                        "postId": post.postId,
                        "name": post.postName,
                        "email": post.postEmail,
                        "time": post.postTime,
                        "message": post.postMessage,
                        "good": post.good,
                        "goodList": post.goodList,
                        "remessage": post.remessage,
                        "remessageList": post.remessagePostArray,
                        "isRemessage": ["nil"],
                        "comment": post.comment,
                        "isComment": myIsComment,
                        "photoUrl": photo
                    ]
                    
                    
                    // ④ 自分の投稿をデータベースへ送る
                    self?.firestore.collection("comment_posts").document(parentPostDay).collection(parentPost.postId).document(post.postId).setData(data) { [weak self](err) in
                        
                        guard err == nil else {
                            completion(false)
                            return
                        }
                        
                        // ⑤ 親投稿の人へ通知を送る
                        if safeMyEmail != parentPost.postEmail {
                            let ndate: [String: Any] = [
                                "model": "replay",
                                "id": "\(post.postId)|!|\(parentPost.postId)",
                                "friendEmail": [safeMyEmail],
                                "is_read": false,
                                "time": post.postTime,
                                "whichTable": whichTable,
                                "textView": post.postMessage
                            ]
                            let notificationPath = "notification/\(parentPost.postEmail)/\(post.postTime)"
                            self?.database.child(notificationPath).updateChildValues(ndate)
                        }
                        
                        completion(true)
                        return
                    }
                })
            }
        }
        
        
    }
    
    
    
    
    
    
    
    // 取得
    
    // 投稿内容をfetch
    // 全体の投稿をfetch
    public func fetchPostInfo(whichTable: Int, nowPostCount: Int, completion: @escaping (Result<[Post], Error>) -> (Void)) {
        
        let fetchCount = 50
        let format = DateFormatter()
        format.dateFormat = "yyMM"
        format.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        
        if let fetchDate = UserDefaults.standard.value(forKey: "fetch_date_all") as? Date {
            // tableviewを上に引っ張って、もっと投稿をみたい時
            // 過去の投稿
            let newDay = format.string(from: fetchDate)
            firestore.collection("posts_all").document("all_users").collection(newDay).order(by: "time", descending: true).limit(to: nowPostCount + fetchCount).getDocuments() { [weak self] (querySnapshot, err) in
                guard err == nil, let strongSelf = self else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                //ブロックは省く
                var blockArray = [String]()
                if let array = UserDefaults.standard.value(forKey: "blocked") as? [String] { blockArray.append(contentsOf: array) }
                if let array = UserDefaults.standard.value(forKey: "amIBlocked") as? [String] { blockArray.append(contentsOf: array) }
                
                var postArray = [Post]()
                for document in querySnapshot!.documents {
                    let dic = document.data()
                    let postCell = strongSelf.convertPost(data: dic)
                    postArray.append(postCell)
                    for blockEmail in blockArray {
                        if postCell.postEmail == blockEmail {
                            postArray.removeLast()
                        }
                    }
                }
                
                // なんかわからないけど、一番最初の投稿よりさらにfetchすると真っ白になる
                if postArray.count != 0 {
                    completion(.success(postArray))
                }
                
                if postArray.count < nowPostCount + fetchCount { //投稿を50個fetchできなかったら、１ヶ月前の投稿をfetchせず、用意
                    // 月が変わった時に呼ばれやすい
                    let preday = Calendar.current.date(byAdding: .month, value: -1, to: fetchDate)!
                    UserDefaults.standard.setValue(preday, forKey: "fetch_date_all")
                }
                return
            }
        }
        // end [if let fetchDate = UserDefaults.standard.value(forKey: "fetch_date_all")]
        
        
        
        else {
            // アプリを開いて初めての処理
            let date = Date()
            var nowDay = format.string(from: date)
            firestore.collection("posts_all").document("all_users").collection(nowDay).order(by: "time", descending: true).limit(to: fetchCount).getDocuments(completion: { [weak self] (querySnapshot, err) in
                
                guard let strongSelf = self else { return }
                //ブロックは省く
                var blockArray = [String]()
                if let array = UserDefaults.standard.value(forKey: "blocked") as? [String] { blockArray.append(contentsOf: array) }
                if let array = UserDefaults.standard.value(forKey: "amIBlocked") as? [String] { blockArray.append(contentsOf: array) }
                
                var postArray = [Post]()
                for document in querySnapshot!.documents {
                    let dic = document.data()
                    let postCell = strongSelf.convertPost(data: dic)
                    postArray.append(postCell)
                    for blockEmail in blockArray {
                        if postCell.postEmail == blockEmail {
                            postArray.removeLast()
                        }
                    }
                }
                
                if postArray.count < fetchCount {
                    // 日付が変わった時に呼ばれやすい
                    // １日前のcollectionから情報を取得
                    let preday = Calendar.current.date(byAdding: .month, value: -1, to: date)!
                    nowDay = format.string(from: preday)
                    strongSelf.firestore.collection("posts_all").document("all_users").collection(nowDay).order(by: "time", descending: true).limit(to: fetchCount - 20).getDocuments() { (querySnapshot, err) in
                        
                        guard err == nil else {
                            completion(.failure(DatabaseError.failedToFetch))
                            return
                        }
                        var dayAgoPosts = [Post]()
                        for document in querySnapshot!.documents {
                            let dic = document.data()
                            let postCell = strongSelf.convertPost(data: dic)
                            dayAgoPosts.append(postCell)
                            for blockEmail in blockArray {
                                if postCell.postEmail == blockEmail {
                                    dayAgoPosts.removeLast()
                                }
                            }
                        }
                        postArray.append(contentsOf: dayAgoPosts)
                        
                        completion(.success(postArray))
                        UserDefaults.standard.setValue(preday, forKey: "fetch_date_all")
                        return
                    }
                }
                else {
                    completion(.success(postArray))
                    UserDefaults.standard.setValue(date, forKey: "fetch_date_all")
                    return
                }
            })
        }
        
    }
    
    
    // 全体の新しい投稿をfetch
    public func fetchNewPostInfo(whichTable: Int, nowPostCount: Int, latestPostTime: String, completion: @escaping (Result<[Post], Error>) -> (Void)) {
        
        let fetchCount = 50 //ここの値を変えるときは、CommunityVCのfetchNewPostsの値も変える
        
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyMM"
        format.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        let nowDay = format.string(from: date)
        
        Firestore.firestore().collection("posts_all").document("all_users").collection(nowDay).order(by: "time", descending: true).limit(to: fetchCount).whereField("time", isGreaterThan: latestPostTime).getDocuments(completion: { [weak self] (querySnapshot, err) in
            
            guard err == nil, let strongSelf = self else {
                return
            }
            
            //ブロックは省く
            var blockArray = [String]()
            if let array = UserDefaults.standard.value(forKey: "blocked") as? [String] { blockArray.append(contentsOf: array) }
            if let array = UserDefaults.standard.value(forKey: "amIBlocked") as? [String] { blockArray.append(contentsOf: array) }
            
            var postArray = [Post]()
            for document in querySnapshot!.documents {
                let dic = document.data()
                let postCell = strongSelf.convertPost(data: dic)
                postArray.append(postCell)
                for blockEmail in blockArray {
                    if postCell.postEmail == blockEmail {
                        postArray.removeLast()
                    }
                }
            }
            
            completion(.success(postArray))
            UserDefaults.standard.setValue(date, forKey: "fetch_date_all")
            return
        })
    }
    
    
    
    // 学部の投稿をfetch
    // post-facultyノードをfetch
    public func fetchFacultyPostInfo(whichTable: Int, nowPostCount: Int, completion: @escaping (Result<[Post], Error>) -> (Void)) {
        
        let fetchCount = 50
        guard let year = UserDefaults.standard.value(forKey: "year") as? String else { return }
        guard let uni = UserDefaults.standard.value(forKey: "uni") as? String else { return }
        guard let fac = UserDefaults.standard.value(forKey: "fac") as? String else { return }
        guard year != "none" else { return }
        guard uni != "none" else { return }
        guard fac != "none" else { return }
        
        let format = DateFormatter()
        format.dateFormat = "yyMM"
        format.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        
        if let fetchDate = UserDefaults.standard.value(forKey: "fetch_date_faculty") as? Date {
            // tableviewを上に引っ張って、もっと投稿をみたい時
            // more fetch
            let newDay = format.string(from: fetchDate)
            firestore.collection("posts_fac").document("\(uni)\(year)\(fac)").collection(newDay).order(by: "time", descending: true).limit(to: nowPostCount + fetchCount).getDocuments() { [weak self] (querySnapshot, err) in
                guard let strongSelf = self else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                
                //ブロックは省く
                var blockArray = [String]()
                if let array = UserDefaults.standard.value(forKey: "blocked") as? [String] { blockArray.append(contentsOf: array) }
                if let array = UserDefaults.standard.value(forKey: "amIBlocked") as? [String] { blockArray.append(contentsOf: array) }
                
                var postArray = [Post]()
                for document in querySnapshot!.documents {
                    let dic = document.data()
                    let postCell = strongSelf.convertPost(data: dic)
                    postArray.append(postCell)
                    for blockEmail in blockArray {
                        if postCell.postEmail == blockEmail {
                            postArray.removeLast()
                        }
                    }
                }
                
                // なんかわからないけど、一番最初の投稿よりさらにfetchすると真っ白になる
                if postArray.count != 0 {
                    completion(.success(postArray))
                }
                
                if postArray.count < nowPostCount + fetchCount { //投稿を50個fetchできなかったら、１ヶ月前の投稿をfetchせず、用意
                    // 月が変わった時に呼ばれやすい
                    let preday = Calendar.current.date(byAdding: .month, value: -1, to: fetchDate)!
                    UserDefaults.standard.setValue(preday, forKey: "fetch_date_faculty")
                }
                
                return
            }
        }
        // end [if let fetchDate = UserDefaults.standard.value(forKey: "fetch_date_faculty")]
        
        
        
        else {
            // アプリを開いて初めての処理
            let date = Date()
            var nowDay = format.string(from: date)
            firestore.collection("posts_fac").document("\(uni)\(year)\(fac)").collection(nowDay).order(by: "time", descending: true).limit(to: fetchCount).getDocuments(completion: { [weak self] (querySnapshot, err) in
                
                guard let strongSelf = self else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                
                //ブロックは省く
                var blockArray = [String]()
                if let array = UserDefaults.standard.value(forKey: "blocked") as? [String] { blockArray.append(contentsOf: array) }
                if let array = UserDefaults.standard.value(forKey: "amIBlocked") as? [String] { blockArray.append(contentsOf: array) }
                
                var postArray = [Post]()
                for document in querySnapshot!.documents {
                    let dic = document.data()
                    let postCell = strongSelf.convertPost(data: dic)
                    postArray.append(postCell)
                    for blockEmail in blockArray {
                        if postCell.postEmail == blockEmail {
                            postArray.removeLast()
                        }
                    }
                }
                
                if postArray.count < fetchCount {
                    // 日付が変わった時に呼ばれやすい
                    // １日前のcollectionから情報を取得
                    let preday = Calendar.current.date(byAdding: .month, value: -1, to: date)!
                    nowDay = format.string(from: preday)
                    strongSelf.firestore.collection("posts_fac").document("\(uni)\(year)\(fac)").collection(nowDay).order(by: "time", descending: true).limit(to: fetchCount - 20).getDocuments() { (querySnapshot, err) in
                        
                        guard err == nil else {
                            completion(.failure(DatabaseError.failedToFetch))
                            return
                        }
                        var dayAgoPosts = [Post]()
                        for document in querySnapshot!.documents {
                            let dic = document.data()
                            let postCell = strongSelf.convertPost(data: dic)
                            dayAgoPosts.append(postCell)
                            for blockEmail in blockArray {
                                if postCell.postEmail == blockEmail {
                                    dayAgoPosts.removeLast()
                                }
                            }
                        }
                        postArray.append(contentsOf: dayAgoPosts)
                        
                        completion(.success(postArray))
                        UserDefaults.standard.setValue(preday, forKey: "fetch_date_faculty")
                        return
                    }
                }
                else {
                    completion(.success(postArray))
                    UserDefaults.standard.setValue(date, forKey: "fetch_date_faculty")
                    return
                }
            })
        }
        
    }
    
    
    
    
    public func fetchNewFacultyPostInfo(whichTable: Int, nowPostCount: Int, latestPostTime: String, completion: @escaping (Result<[Post], Error>) -> (Void)) {
        
        let fetchCount = 50 //ここの値を変えるときは、CommunityVCのfetchNewPostsの値も変える
        guard let year = UserDefaults.standard.value(forKey: "year") as? String else { return }
        guard let uni = UserDefaults.standard.value(forKey: "uni") as? String else { return }
        guard let fac = UserDefaults.standard.value(forKey: "fac") as? String else { return }
        guard year != "none" else { return }
        guard uni != "none" else { return }
        guard fac != "none" else { return }

        
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyMM"
        format.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        let nowDay = format.string(from: date)
        
        firestore.collection("posts_fac").document("\(uni)\(year)\(fac)").collection(nowDay).order(by: "time", descending: true).limit(to: fetchCount).whereField("time", isGreaterThan: latestPostTime).getDocuments(completion: { [weak self] (querySnapshot, err) in
            
            guard err == nil, let strongSelf = self else {
                return
            }
            
            //ブロックは省く
            var blockArray = [String]()
            if let array = UserDefaults.standard.value(forKey: "blocked") as? [String] { blockArray.append(contentsOf: array) }
            if let array = UserDefaults.standard.value(forKey: "amIBlocked") as? [String] { blockArray.append(contentsOf: array) }
            
            var postArray = [Post]()
            for document in querySnapshot!.documents {
                let dic = document.data()
                let postCell = strongSelf.convertPost(data: dic)
                postArray.append(postCell)
                for blockEmail in blockArray {
                    if postCell.postEmail == blockEmail {
                        postArray.removeLast()
                    }
                }
            }
            
            completion(.success(postArray))
            UserDefaults.standard.setValue(date, forKey: "fetch_date_faculty")
            return
        })
    }
    
    
    
    
    // プロフィール画面でもっと投稿を見たいとき
    public func fetchIndividualPostInfo(nowPostCount: Int, friendEmail: String, completion: @escaping (Result<[Post], Error>) -> (Void)) {
        
        let fetchCount = 50
        // tableviewを上に引っ張って、もっと投稿をみたい時
        // more fetch
        firestore.collection("posts_individual").document(friendEmail).collection("all_posts").order(by: "time", descending: true).limit(to: nowPostCount + fetchCount).getDocuments() { [weak self] (querySnapshot, err) in
            guard err == nil, let strongSelf = self else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            var postArray = [Post]()
            for document in querySnapshot!.documents {
                let dic = document.data()
                postArray.append(strongSelf.convertPost(data: dic))
            }
            
            // なんかわからないけど、一番最初の投稿よりさらにfetchすると真っ白になる
            if postArray.count != 0 {
                completion(.success(postArray))
            }
            
            return
        }
    }
        
    
    
    
    
    
    
    private func convertPost(data: [String: Any]) -> Post {
        
        if let postId = data["postId"] as? String,
           let postMessage = data["message"] as? String,
           let postEmail = data["email"] as? String,
           let postName = data["name"] as? String,
           let postTime = data["time"] as? String,
           let good = data["good"] as? Int,
           let goodList = data["goodList"] as? [String],
           let remessage = data["remessage"] as? Int,
           let remessageList = data["remessageList"] as? [String],
           let comment = data["comment"] as? Int,
           let isComment = data["isComment"] as? String,
           let photoUrls = data["photoUrl"] as? [String]
        {
            
            var finalPhotoUrl: [String]?
            var finalIsRemessage: Remessage?
            var finalIsComment: String?
            if photoUrls[0] != "nil" {
                finalPhotoUrl = photoUrls
            }
            if isComment != "nil" {
                finalIsComment = isComment
            }
            
            if let isRemessage = data["isRemessage"] as? [String: Any] {
                if let ParentId = isRemessage["postId"] as? String,
                      let Message1 = isRemessage["postMessage"] as? String,
                      let Mail = isRemessage["postEmail"] as? String,
                      let Name = isRemessage["postName"] as? String,
                      let Time = isRemessage["postTime"] as? String,
                      let Good = isRemessage["good"] as? Int,
                      let GoodList = isRemessage["goodList"] as? [String],
                      let ReMessage = isRemessage["remessage"] as? Int,
                      let RemessageList = isRemessage["remessageList"] as? [String],
                      let reremessage = isRemessage["isRemessage"] as? String,
                      let Comment = isRemessage["comment"] as? Int,
                      let PhotoUrl = isRemessage["postUrl"] as? [String]
                {
                    
                    var isCommentFinal: String?
                    if let isRemessageComment = isRemessage["isComment"] as? String {
                        isCommentFinal = isRemessageComment
                    }
                    
                    var finalRemessagePhotoUrl: [String]?
                    var finalReremessage: String?
                    var finalComment: String?
                    if PhotoUrl[0] != "nil" {
                        finalRemessagePhotoUrl = PhotoUrl
                    }
                    if reremessage != "nil" {
                        finalReremessage = reremessage
                    }
                    if let IsComment = isCommentFinal {
                        finalComment = IsComment
                    }
                    
                    if let taskArray = isRemessage["shareTask"] as? [String: Any] {
                        if let taskId = taskArray["taskId"] as? String,
                              let taskName = taskArray["taskName"] as? String,
                              let taskLimit = taskArray["taskLimit"] as? String,
                              let timeSchedule = taskArray["timeSchedule"] as? String,
                              let documentPath = taskArray["documentPath"] as? String,
                              let memberCount = taskArray["memberCount"] as? Int,
                              let makedEmail = taskArray["makedEmail"] as? String,
                              let doneMember = taskArray["doneMember"] as? [String],
                              let gettingMember = taskArray["gettingMember"] as? [String],
                              let wantToTalkMember = taskArray["wantToTalkMember"] as? [String]
                        {
                            
                            let task = BullutinTask(taskId: taskId, taskName: taskName, taskLimit: taskLimit, timeSchedule: timeSchedule, documentPath: documentPath, memberCount: memberCount, makedEmail: makedEmail, doneMember: doneMember, gettingMember: gettingMember, wantToTalkMember: wantToTalkMember)
                            
                            let remessageObject = Remessage(parentPostId: ParentId, postMessage: Message1, postEmail: Mail, postName: Name, postTime: Time, good: Good, goodList: GoodList, remessage: ReMessage, remessagePostArray: RemessageList, isRemessage: finalReremessage, comment: Comment, isComment: finalComment, photoUrl: finalRemessagePhotoUrl, shareTask: task)
                            
                            finalIsRemessage = remessageObject
                            let remessagepost = Post(postId: postId, postMessage: postMessage, postEmail: postEmail, postName: postName, postTime: postTime, good: good, goodList: goodList, remessage: remessage, remessagePostArray: remessageList, isRemessage: finalIsRemessage, comment: comment, isComment: finalIsComment, photoUrl: finalPhotoUrl)
                            
                            return remessagepost
                        }
                    }
                    
                    let remessageObject = Remessage(parentPostId: ParentId, postMessage: Message1, postEmail: Mail, postName: Name, postTime: Time, good: Good, goodList: GoodList, remessage: ReMessage, remessagePostArray: RemessageList, isRemessage: finalReremessage, comment: Comment, isComment: finalComment, photoUrl: finalRemessagePhotoUrl, shareTask: nil)
                    
                    finalIsRemessage = remessageObject
                    let remessagepost = Post(postId: postId, postMessage: postMessage, postEmail: postEmail, postName: postName, postTime: postTime, good: good, goodList: goodList, remessage: remessage, remessagePostArray: remessageList, isRemessage: finalIsRemessage, comment: comment, isComment: finalIsComment, photoUrl: finalPhotoUrl)
                    
                    return remessagepost
                }
                return Post(postId: "", postMessage: "", postEmail: "", postName: "", postTime: "", good: 0, goodList: [""], remessage: 0, remessagePostArray: ["0_nil"], isRemessage: nil, comment: 0, isComment: nil, photoUrl: nil)
                
            } // if let isRemessage = data["isRemessage"]
            
            
            if let taskArray = data["task"] as? [String: Any] {
                if let taskId = taskArray["taskId"] as? String,
                      let taskName = taskArray["taskName"] as? String,
                      let taskLimit = taskArray["taskLimit"] as? String,
                      let timeSchedule = taskArray["timeSchedule"] as? String,
                      let documentPath = taskArray["documentPath"] as? String,
                      let memberCount = taskArray["memberCount"] as? Int,
                      let makedEmail = taskArray["makedEmail"] as? String,
                      let doneMember = taskArray["doneMember"] as? [String],
                      let gettingMember = taskArray["gettingMember"] as? [String],
                      let wantToTalkMember = taskArray["wantToTalkMember"] as? [String]
                {
                    
                    let task = BullutinTask(taskId: taskId, taskName: taskName, taskLimit: taskLimit, timeSchedule: timeSchedule, documentPath: documentPath, memberCount: memberCount, makedEmail: makedEmail, doneMember: doneMember, gettingMember: gettingMember, wantToTalkMember: wantToTalkMember)
                    return Post(postId: postId, postMessage: postMessage, postEmail: postEmail, postName: postName, postTime: postTime, good: good, goodList: goodList, remessage: remessage, remessagePostArray: remessageList, isRemessage: nil, comment: comment, isComment: finalIsComment, photoUrl: finalPhotoUrl, shareTask: task)
                }
            }
            
            let remessagepost = Post(postId: postId, postMessage: postMessage, postEmail: postEmail, postName: postName, postTime: postTime, good: good, goodList: goodList, remessage: remessage, remessagePostArray: remessageList, isRemessage: finalIsRemessage, comment: comment, isComment: finalIsComment, photoUrl: finalPhotoUrl, shareTask: nil)
            return remessagepost
        }
        return Post(postId: "", postMessage: "", postEmail: "", postName: "", postTime: "", good: 0, goodList: [""], remessage: 0, remessagePostArray: ["0_nil"], isRemessage: nil, comment: 0, isComment: nil, photoUrl: nil, shareTask: nil)
    }
    
    
    
    
    // repeatTableViewをタップしてUserPostになった時、さらにremessageがある場合
    // "\(whichTable)/\(id)のNodeを取得。一つのpostIdを取得できる
    public func fetchPostId(whichTable: Int, postId: String, completion: @escaping (Result<Post, Error>) -> Void) {
        
        /*
         |!|が含まれていたら、
         postId = "\(postId)_\(自分の投稿日)|!|\(親postId)_\(親の投稿日)"
         
         |!|が含まれていなかったら、
         postId = "\(postId)_\(自分の投稿日)
         */
        
        
        if postId.contains("|!|") {
            let stringArray = postId.components(separatedBy: "|!|")
            guard stringArray.count == 2 else {
                return
            }
            let myPostId = stringArray[0]
            let parentPostId = stringArray[1]
            let parentPostDay = String(parentPostId.suffix(4))
            Firestore.firestore().collection("comment_posts").document(parentPostDay).collection(parentPostId).document(myPostId).getDocument { [weak self](snapshot, err) in
                
                guard err == nil,
                      let dic = snapshot?.data() else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                let tagetPost = self?.convertPost(data: dic)
                guard let rowPost = tagetPost else {
                    return
                }
                completion(.success(rowPost))
                
            }
            
        }
        else {
            let postDay = String(postId.suffix(4))
            
            // documentId
            var postName = ""
            var docName = ""
            
            if whichTable == 0 { postName = "posts_all" }
            if whichTable == 1 { postName = "posts_fac" }
            var year = "none"
            var uni = "none"
            var fac = "none"
            if let year1 = UserDefaults.standard.value(forKey: "year") as? String { year = year1 }
            if let uni1 = UserDefaults.standard.value(forKey: "uni") as? String { uni = uni1 }
            if let fac1 = UserDefaults.standard.value(forKey: "fac") as? String { fac = fac1 }
            
            if whichTable == 0 { docName = "all_users" }
            if whichTable == 1 { docName = "\(uni)\(year)\(fac)" }
            
            firestore.collection(postName).document(docName).collection(postDay).document(postId).getDocument { [weak self](snapshot, err) in
                
                guard err == nil,
                      let dic = snapshot?.data() else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                let tagetPost = self?.convertPost(data: dic)
                guard let rowPost = tagetPost else {
                    return
                }
                completion(.success(rowPost))
            }
        }
        
    }
    
    
    public func fetchCommentArray(whichTable: Int, parentPost: Post, completion: @escaping (Result<[Post], Error>) -> Void) {
        
        let dateString = parentPost.postTime
        let nowDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let postDate = formatter.date(from: dateString) ?? nowDate
        
        let changeFormatter = DateFormatter()
        changeFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyMM", options: 0, locale: nil)
        let beforeString = changeFormatter.string(from: postDate)
        let parentPostDay = beforeString.replacingOccurrences(of: "-", with: "")
        
        Firestore.firestore().collection("comment_posts").document(parentPostDay).collection(parentPost.postId).getDocuments() { [weak self](querySnapshot, err) in
            guard err == nil,
                  let strongSelf = self else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            var postArray = [parentPost]
            var postSortArray = [Post]()
            for document in querySnapshot!.documents {
                let dic = document.data()
                postSortArray.append(strongSelf.convertPost(data: dic))
            }
            postSortArray.sort { (a, b) -> Bool in
                a.good > b.good
            }
            for post in postSortArray {
                postArray.append(post)
            }
            completion(.success(postArray))
        }
    }
    
    
    
    // profileに表示するpostを表示する
    public func fetchFriendPosts(friendEmail: String, nowPostCount: Int, completion: @escaping (Result<[Post], Error>) -> Void) {
        
        let fetchCount = 10
        let moreFetch = 50
        
        if nowPostCount == 0 {
            //初めての処理
            firestore.collection("posts_individual").document(friendEmail).collection("all_posts").order(by: "time", descending: true).limit(to: fetchCount).getDocuments(completion: { [weak self] (querySnapshot, err) in
                
                guard err == nil, let strongSelf = self else {
                    return
                }
                var postArray = [Post]()
                for document in querySnapshot!.documents {
                    let dic = document.data()
                    postArray.append(strongSelf.convertPost(data: dic))
                }
                
                completion(.success(postArray))
                return
            })
        }
        
        
        else {
            firestore.collection("posts_individual").document(friendEmail).collection("all_posts").order(by: "time", descending: true).limit(to: nowPostCount + moreFetch).getDocuments(completion: { [weak self] (querySnapshot, err) in
                
                guard err == nil, let strongSelf = self else {
                    return
                }
                var postArray = [Post]()
                for document in querySnapshot!.documents {
                    let dic = document.data()
                    postArray.append(strongSelf.convertPost(data: dic))
                }
                
                completion(.success(postArray))
                return
            })
        }
        
        
    }
    
    
    // いいねを押したらgoodListに登録する
    public func insertMyGoodList(targetPost: Post, whichTable: Int, whichVC: Int, uni: String?, year: String?, fac: String?, completion: @escaping (Bool) -> Void) {
        // whichVC==0はCommunityVCから、whichVC==1はUserPost(comment)から、whichVC==2はFriendProfileから
        // whichVC==4はgoodを消す whichVC==5はコメントのgoodを消す
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        // 相手に通知する
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        format.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        let dateString = format.string(from: date)
        let notificationPath = "notification/\(targetPost.postEmail)/\(dateString)"
        
        // targetPost date
        let postDay = String(targetPost.postId.suffix(4))
        var notificationId = targetPost.postId
        if let comment = targetPost.isComment {
            notificationId = comment
        }
        
        
        if whichVC == 1 || whichVC == 5 { // コメントの場合
            
            guard let grandPostId = targetPost.isComment else {
                completion(false)
                return
            }
            if targetPost.isComment?.contains("|!|") == true {
                
                let stringArray = grandPostId.components(separatedBy: "|!|")
                guard stringArray.count == 2 else {
                    return
                }
                let rGrandPostId = stringArray[0]
                let grandPostDay = String(rGrandPostId.suffix(4))
                if whichVC == 5 {
                    // コメントのいいねを削除
                    firestore.collection("comment_posts").document(grandPostDay).collection(rGrandPostId).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(-1))])
                    firestore.collection("comment_posts").document(grandPostDay).collection(rGrandPostId).document(targetPost.postId).updateData(["goodList": FieldValue.arrayRemove([safeMyEmail])])
                    completion(true)
                    return
                }
                else {
                    firestore.collection("comment_posts").document(grandPostDay).collection(rGrandPostId).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(1))])
                    firestore.collection("comment_posts").document(grandPostDay).collection(rGrandPostId).document(targetPost.postId).updateData(["goodList": FieldValue.arrayUnion([safeMyEmail])])
                    //相手のnotificationに入れる
                    if safeMyEmail != targetPost.postEmail {
                        let ndate: [String: Any] = [
                            "model": "good",
                            "id": "\(targetPost.postId)|!|\(grandPostId)",
                            "friendEmail": [safeMyEmail],
                            "is_read": false,
                            "time": dateString,
                            "whichTable": 1,
                            "textView": targetPost.postMessage
                        ]
                        database.child(notificationPath).updateChildValues(ndate)
                        completion(true)
                        return
                    }
                    return
                }
                
            }
            else {
                let grandPostDay = String(grandPostId.suffix(4))
                
                if whichVC == 5 {
                    // コメントのいいねを削除
                    firestore.collection("comment_posts").document(grandPostDay).collection(grandPostId).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(-1))])
                    firestore.collection("comment_posts").document(grandPostDay).collection(grandPostId).document(targetPost.postId).updateData(["goodList": FieldValue.arrayRemove([safeMyEmail])])
                    completion(true)
                    return
                }
                else {
                    firestore.collection("comment_posts").document(grandPostDay).collection(grandPostId).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(1))])
                    firestore.collection("comment_posts").document(grandPostDay).collection(grandPostId).document(targetPost.postId).updateData(["goodList": FieldValue.arrayUnion([safeMyEmail])])
                    //相手のnotificationに入れる
                    if safeMyEmail != targetPost.postEmail {
                        let ndate: [String: Any] = [
                            "model": "good",
                            "id": "\(targetPost.postId)|!|\(grandPostId)",
                            "friendEmail": [safeMyEmail],
                            "is_read": false,
                            "time": dateString,
                            "whichTable": 1,
                            "textView": targetPost.postMessage
                        ]
                        database.child(notificationPath).updateChildValues(ndate)
                        completion(true)
                        return
                    }
                    return
                }
            }
        } // コメントの終了
        
        
        if let rUni = uni,
           let rYear = year,
           let rfac = fac {
            // プロファイルからいいね
            // targetPostのwhichTableを取得する
            let before5 = targetPost.postId.suffix(5)
            let doubleTable = before5.prefix(1)
            
            var postName = ""
            var docName = ""
            var postName2 = ""
            var docName2 = ""
            var postName3 = ""
            var docName3 = ""
            var insertTable = 2
            
            
            if doubleTable == "0" { postName = "posts_all"; docName = "all_users"; insertTable = 0 }
            if doubleTable == "1" { postName = "posts_uni"; docName = "\(rUni)\(rYear)"; insertTable = 1 }
            if doubleTable == "2" { postName = "posts_fac"; docName = "\(rUni)\(rYear)\(rfac)" }
            // 学部と大学などの二つを投稿した場合
            if doubleTable == "3" { // 全体と大学
                postName = "posts_uni"; docName = "\(rUni)\(rYear)"; insertTable = 1
                postName2 = "posts_all"; docName2 = "all_users";
                if whichVC == 4 {
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(-1))])
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayRemove([safeMyEmail])])

                }
                else {
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(1))])
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayUnion([safeMyEmail])])
                }
            }
            if doubleTable == "4" { // 全体と学部
                postName = "posts_fac"; docName = "\(rUni)\(rYear)\(rfac)"
                postName2 = "posts_all"; docName2 = "all_users"
                if whichVC == 4 {
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(-1))])
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayRemove([safeMyEmail])])
                }
                else {
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(1))])
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayUnion([safeMyEmail])])
                }
            }
            if doubleTable == "5" { // 学部と大学
                postName = "posts_fac"; docName = "\(rUni)\(rYear)\(rfac)"
                postName2 = "posts_uni"; docName2 = "\(rUni)\(rYear)"
                if whichVC == 4 {
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(-1))])
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayRemove([safeMyEmail])])
                }
                else {
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(1))])
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayUnion([safeMyEmail])])
                }
            }
            if doubleTable == "6" { // ３つとも
                postName = "posts_fac"; docName = "\(rUni)\(rYear)\(rfac)"
                postName2 = "posts_fac"; docName2 = "\(rUni)\(rYear)\(rfac)"
                postName3 = "posts_fac"; docName3 = "\(rUni)\(rYear)\(rfac)"
                if whichVC == 4 {
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(-1))])
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayRemove([safeMyEmail])])
                    firestore.collection(postName3).document(docName3).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(-1))])
                    firestore.collection(postName3).document(docName3).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayRemove([safeMyEmail])])
                }
                else {
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(1))])
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayUnion([safeMyEmail])])
                    firestore.collection(postName3).document(docName3).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(1))])
                    firestore.collection(postName3).document(docName3).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayUnion([safeMyEmail])])
                }
            }
            
            
            if whichVC == 4 {
                // remove good
                firestore.collection("posts_individual").document(targetPost.postEmail).collection("all_posts").document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(-1))])
                firestore.collection("posts_individual").document(targetPost.postEmail).collection("all_posts").document(targetPost.postId).updateData(["goodList": FieldValue.arrayRemove([safeMyEmail])])
                firestore.collection(postName).document(docName).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(-1))])
                firestore.collection(postName).document(docName).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayRemove([safeMyEmail])])
                completion(true)
                return
            }
            else {
                // add good
                guard whichVC != 1 else { return }
                firestore.collection("posts_individual").document(targetPost.postEmail).collection("all_posts").document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(1))])
                firestore.collection("posts_individual").document(targetPost.postEmail).collection("all_posts").document(targetPost.postId).updateData(["goodList": FieldValue.arrayUnion([safeMyEmail])])
                firestore.collection(postName).document(docName).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(1))])
                firestore.collection(postName).document(docName).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayUnion([safeMyEmail])])
                
                //相手のnotificationに入れる
                if safeMyEmail != targetPost.postEmail {
                    let ndate: [String: Any] = [
                        "model": "good",
                        "id": notificationId,
                        "friendEmail": [safeMyEmail],
                        "is_read": false,
                        "time": dateString,
                        "whichTable": insertTable,
                        "textView": targetPost.postMessage
                    ]
                    database.child(notificationPath).updateChildValues(ndate)
                    completion(true)
                    return
                }
            }
            
        } // プロファイルからのいいねの処理
        
        
        
        
        else {
            // プロファイル以外からいいね
            guard whichVC != 1, // comment
                  whichVC != 2, // profile
                  whichVC != 5 else { // comment delete
                return
            }
            
            let before5 = targetPost.postId.suffix(5)
            let doubleTable = before5.prefix(1)
            
            var postName = ""
            var docName = ""
            var postName2 = ""
            var docName2 = ""
            var postName3 = ""
            var docName3 = ""
            
            var year = "none"
            var uni = "none"
            var fac = "none"
            if let year1 = UserDefaults.standard.value(forKey: "year") as? String { year = year1 }
            if let uni1 = UserDefaults.standard.value(forKey: "uni") as? String { uni = uni1 }
            if let fac1 = UserDefaults.standard.value(forKey: "fac") as? String { fac = fac1 }
            
            
            if doubleTable == "0" { postName = "posts_all"; docName = "all_users" }
//            if doubleTable == "1" { postName = "posts_uni"; docName = "\(uni)\(year)" }
            if doubleTable == "1" { postName = "posts_fac"; docName = "\(uni)\(year)\(fac)" }
            
            // 学部と大学などの二つを投稿した場合
            if doubleTable == "3" { // 全体と大学
                postName = "posts_uni"; docName = "\(uni)\(year)"
                postName2 = "posts_all"; docName2 = "all_users"
                if whichVC == 4 {
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(-1))])
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayRemove([safeMyEmail])])

                }
                else {
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(1))])
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayUnion([safeMyEmail])])
                }
            }
            if doubleTable == "4" { // 全体と学部
                postName = "posts_fac"; docName = "\(uni)\(year)\(fac)"
                postName2 = "posts_all"; docName2 = "all_users"
                if whichVC == 4 {
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(-1))])
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayRemove([safeMyEmail])])
                }
                else {
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(1))])
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayUnion([safeMyEmail])])
                }
            }
            if doubleTable == "5" { // 学部と大学
                postName = "posts_fac"; docName = "\(uni)\(year)\(fac)"
                postName2 = "posts_uni"; docName2 = "\(uni)\(year)"
                if whichVC == 4 {
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(-1))])
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayRemove([safeMyEmail])])
                }
                else {
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(1))])
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayUnion([safeMyEmail])])
                }
            }
            if doubleTable == "6" { // ３つとも
                postName = "posts_fac"; docName = "\(uni)\(year)\(fac)"
                postName2 = "posts_fac"; docName2 = "\(uni)\(year)\(fac)"
                postName3 = "posts_fac"; docName3 = "\(uni)\(year)\(fac)"
                if whichVC == 4 {
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(-1))])
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayRemove([safeMyEmail])])
                    firestore.collection(postName3).document(docName3).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(-1))])
                    firestore.collection(postName3).document(docName3).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayRemove([safeMyEmail])])
                }
                else {
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(1))])
                    firestore.collection(postName2).document(docName2).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayUnion([safeMyEmail])])
                    firestore.collection(postName3).document(docName3).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(1))])
                    firestore.collection(postName3).document(docName3).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayUnion([safeMyEmail])])
                }
            }
            
            
            
            if whichVC == 4 {
                // remove good
                firestore.collection("posts_individual").document(targetPost.postEmail).collection("all_posts").document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(-1))])
                firestore.collection("posts_individual").document(targetPost.postEmail).collection("all_posts").document(targetPost.postId).updateData(["goodList": FieldValue.arrayRemove([safeMyEmail])])
                firestore.collection(postName).document(docName).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(-1))])
                firestore.collection(postName).document(docName).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayRemove([safeMyEmail])])
                completion(true)
                return
            }
            else {
                // add good
                firestore.collection("posts_individual").document(targetPost.postEmail).collection("all_posts").document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(1))])
                firestore.collection("posts_individual").document(targetPost.postEmail).collection("all_posts").document(targetPost.postId).updateData(["goodList": FieldValue.arrayUnion([safeMyEmail])])
                firestore.collection(postName).document(docName).collection(postDay).document(targetPost.postId).updateData(["good": FieldValue.increment(Int64(1))])
                firestore.collection(postName).document(docName).collection(postDay).document(targetPost.postId).updateData(["goodList": FieldValue.arrayUnion([safeMyEmail])])
                //相手のnotificationに入れる
                if safeMyEmail != targetPost.postEmail {
                    let ndate: [String: Any] = [
                        "model": "good",
                        "id": notificationId,
                        "friendEmail": [safeMyEmail],
                        "is_read": false,
                        "time": dateString,
                        "whichTable": whichTable,
                        "textView": targetPost.postMessage
                    ]
                    database.child(notificationPath).updateChildValues(ndate)
                    completion(true)
                    return
                }
            }
            
        }
        
        
    }
    
    
    // 自分が押したいいねの取得
//    public func fetchGoodInfo(completion: @escaping (Result<[String], Error>) -> Void) {
//        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
//            return
//        }
//        let email = DatabaseManager.safeEmail(emailAddress: myEmail)
//
//        let path = "users/\(email)/goodList"
//        database.child(path).observeSingleEvent(of: .value) { (snapshot) in
//            guard let goodList = snapshot.value as? [String] else {
//                completion(.failure(DatabaseError.failedToFetch))
//                return
//            }
//            completion(.success(goodList))
//        }
//
//    }
    
    // 通報(post)
    public func alertPost(postId: String, whichTable: Int, completion: @escaping (Bool) -> Void) {
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let email = DatabaseManager.safeEmail(emailAddress: myEmail)
        let postDay = String(postId.suffix(4))
        
        let path = "alert/投稿記事/\(postDay)/\(postId)/\(email)"
        let data: [String: String] = [
            "1": "\(whichTable)"
        ]
        database.child(path).updateChildValues(data)
        completion(true)
    }
    
    //通報(friendProfileVC)
    public func alertForFriendVC(myEmail: String, friendEmail: String, message: String, completion: @escaping (Bool) -> Void) {
        
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        format.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        let dateString = format.string(from: date)
        
        let path = "alert/連絡した人/\(dateString)/\(friendEmail)"
        database.child(path).updateChildValues(["sender": myEmail, "content": message])
            completion(true)
    }
    
    
    // 通知
    public func notification(completion: @escaping (Result<[NotificationModel], Error>) -> Void) {
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let path = "notification/\(safeMyEmail)"
        database.child(path).observe(.value) { [weak self](snapshot) in
            guard let notificationNode = snapshot.value as? [String: Any] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            var notificationArray = [NotificationModel]()
            for notification in notificationNode {
                guard let value = notification.value as? [String: Any],
                      let friendEmail = value["friendEmail"] as? [String],
                      let isRead = value["is_read"] as? Bool,
                      let postId = value["id"] as? String,
                      let model = value["model"] as? String,
                      let time = value["time"] as? String,
                      let whichTable = value["whichTable"] as? Int,
                      let textView = value["textView"] as? String else {
                    completion(.failure(DatabaseError.failedToFetch))
                    print("notificationに表示するものにerror in [for]")
                    return
                }
                let notificationChild = NotificationModel(friendEmail: friendEmail, isRead: isRead, postId: postId, model: model, time: time, whichTable: whichTable, textView: textView)
                notificationArray.append(notificationChild)
            }
            
            notificationArray = notificationArray.sorted { (a, b) -> Bool in
                return a.time > b.time
            }
            
            
            var i = 0
            var isContinue = false
            
            for notification in notificationArray {
                if i == 0 {
                    i += 1
                    continue
                }
                var privious = notificationArray[i-1]
                if privious.model == "good" && notification.model == "good" && notification.postId == privious.postId {
                    isContinue = true
                    privious.friendEmail.append(notification.friendEmail[0])
                    notificationArray.remove(at: i)
                    notificationArray[i-1] = privious
                    notificationArray[i-1].isRead = false
                    self?.database.child("\(path)/\(notification.time)").removeValue()
                    continue
                }
                
                if isContinue == true {
                    let newData: [String: Any] = [
                        "friendEmail" : privious.friendEmail
                    ]
                    self?.database.child("\(path)/\(privious.time)").updateChildValues(newData)
                    isContinue = false
                }
                i += 1
            }
            if isContinue == true {
                let newData: [String: Any] = [
                    "friendEmail" : notificationArray[i-1].friendEmail
                ]
                self?.database.child("\(path)/\(notificationArray[i-1].time)").updateChildValues(newData)
                isContinue = false
            }
            completion(.success(notificationArray))
        }
    }
    
    
    // 通知の既読
    public func iReadNotification(date: String) {
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let path = "notification/\(safeMyEmail)/\(date)"
        let data: [String: Bool] = [
            "is_read": true
        ]
        database.child(path).updateChildValues(data)
    }
    
    
    // 名前の情報を取得
    public func fetchUserName(email: String, completion: @escaping (Result<String, Error>) -> Void) {
        let path = "users/\(email)/info/name"
        database.child(path).observeSingleEvent(of: .value) { (snapshot) in
            guard let name = snapshot.value as? String else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(name))
            return
        }
    }
    
    
    // 投稿を消す
    public func removePost(postId: String, postEmail: String, whichTable: Int, isParentPath: String?, completion: @escaping (Bool) -> Void) {
        
        let before5 = postId.suffix(5)
        var postDay = postId.suffix(4)
        let doubleTable = before5.prefix(1)
        var postName = ""
        var docName = ""
        var postName2 = ""
        var docName2 = ""
        
        var rUni = ""
        var rYear = ""
        var rfac = ""
        if let year = UserDefaults.standard.value(forKey: "year") as? String { rYear = year }
        if let uni = UserDefaults.standard.value(forKey: "uni") as? String { rUni = uni }
        if let fac = UserDefaults.standard.value(forKey: "fac") as? String { rfac = fac }
 
        if doubleTable == "0" { postName = "posts_all"; docName = "all_users" }
        if doubleTable == "1" { postName = "posts_fac"; docName = "\(rUni)\(rYear)\(rfac)" }
        if doubleTable == "4" {
            postName = "posts_fac"; docName = "\(rUni)\(rYear)\(rfac)"
            postName2 = "posts_all"; docName2 = "all_users"
        }
        
        if let parentPath = isParentPath {
            postDay = parentPath.suffix(4)
            firestore.collection("comment_posts").document(String(postDay)).collection(parentPath).document(postId).delete()
            completion(true)
            return
        }
        
        firestore.collection(postName).document(docName).collection(String(postDay)).document(postId).delete()
        firestore.collection("posts_individual").document(postEmail).collection("all_posts").document(postId).delete()
        
        // 学部と大学などの二つを投稿した場合
        if doubleTable == "4" {
            
            firestore.collection(postName2).document(docName2).collection(String(postDay)).document(postId).delete()
        }
        completion(true)
    }
    
    
    // 時間割を入れる
    public func insertTimeSchedule(myTimeSchedule: TimeScheduleContainer, completion: @escaping (Bool) -> Void) {
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let mySafeEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        let path = "users/\(mySafeEmail)/time_schedule/now"
        var timeData = [[String: String]]()
        for cell in myTimeSchedule.timeTable {
            let dictionary = [
                "subject": cell.subject,
                "teacher": cell.teacher,
                "color": cell.color,
                "place": cell.place ?? ""
            ]
            timeData.append(dictionary)
        }
        let data: [String: Any] = [
            "name": myTimeSchedule.name,
            "classCount": myTimeSchedule.classCount,
            "classDay": myTimeSchedule.classDay,
            "timeData": timeData
        ]
        UserDefaults.standard.setValue(data, forKey: "myTimeSchedule")
        database.child(path).setValue(data)
        completion(true)
    }
    
    public func fetchTimeSchedule(myEmail: String, completion: @escaping (Result<TimeScheduleContainer, Error>) -> Void) {
        let path = "users/\(myEmail)/time_schedule/now"
        database.child(path).observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [String: Any] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            guard let name = value["name"] as? String,
                  let classCount = value["classCount"] as? Int,
                  let classDay = value["classDay"] as? Int,
                  let array = value["timeData"] as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            var result1 = [TimeScheduleStruct]()
            var i = 0
            for dictionary in array {
                guard let teacher = dictionary["teacher"],
                      let subject = dictionary["subject"],
                      let color = dictionary["color"] else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                let data = TimeScheduleStruct(number: i, color: color, subject: subject, teacher: teacher)
                result1.append(data)
                i += 1
            }
            
            let result = TimeScheduleContainer(name: name, classCount: classCount, classDay: classDay, timeTable: result1)
            
            completion(.success(result))
        }
    }
    
     
    // 足跡
    public func insertAshiato(myEmail: String, friendEmail: String, date: String) {
        let path = "notification-ashiato/\(friendEmail)/\(date)"
        let data : [String: Any] = [
            "friendEmail": myEmail,
            "date": date
        ]
        database.child(path).setValue(data)
    }
    public func fetchAshiato(myEmail: String, completion: @escaping (Result<[AshiatoModel], Error>) -> Void) {
        let path = "notification-ashiato/\(myEmail)"
        database.child(path).observeSingleEvent(of: .value) { [weak self](snapshot) in
            guard let value = snapshot.value as? [String: Any] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            var result = [AshiatoModel]()
            for dictionary in value {
                if let ashiatoNode = dictionary.value as? [String: String] {
                    guard let email = ashiatoNode["friendEmail"],
                          let date = ashiatoNode["date"] else {
                        completion(.failure(DatabaseError.failedToFetch))
                        return
                    }
                    let data = AshiatoModel(email: email, date: date)
                    result.append(data)
                }
            }
            result.sort { (a, b) -> Bool in
                a.date > b.date
            }
            if result.count > 50 {
                let forCount = result.count
                var i = 1
                while i <= forCount - 50 {
                    let removePath = "notification-ashiato/\(myEmail)/\(result[forCount - i].date)"
                    self?.database.child(removePath).removeValue()
                    i += 1
                }
            }
            completion(.success(result))
        }
    }
    
    // フォローする
    public func FollowYou(myEmail: String, friendEmail: String, isUnFollow: Bool, completion: @escaping (Bool) -> (Void)) {
        
        let path = "users/\(myEmail)/フォロー"
        let friendPath = "users/\(friendEmail)/フォロワー"
        
        if isUnFollow == true {
            guard var myFriends = UserDefaults.standard.value(forKey: "myFriends") as? [String] else {
                return
            }
            var i = 0
            for cell in myFriends {
                if cell == friendEmail {
                    break
                }
                i += 1
            }
            myFriends.remove(at: i)
            UserDefaults.standard.setValue(myFriends, forKey: "myFriends")
            
            database.child(path).setValue(myFriends) { [weak self](error, _) in
                guard error == nil else {
                    completion(false)
                    return
                }
                completion(true)
                
                self?.database.child(friendPath).observeSingleEvent(of: .value) { (snapshot) in
                    guard var friends = snapshot.value as? [String] else {
                        completion(false)
                        return
                    }
                    var i = 0
                    for cell in friends {
                        if cell == myEmail {
                            friends.remove(at: i)
                            break
                        }
                        i += 1
                    }
                    self?.database.child(friendPath).setValue(friends)
                }
            }
            
        }
        
        
        // フレンド登録
        else {
            guard var myFriends = UserDefaults.standard.value(forKey: "myFriends") as? [String],
                  let myName = UserDefaults.standard.value(forKey: "name") as? String else {
                return
            }
            myFriends.append(friendEmail)
            UserDefaults.standard.setValue(myFriends, forKey: "myFriends")
            
            // 相手に通知する
            let date = Date()
            let format = DateFormatter()
            format.dateFormat = "yyyy-MM-dd HH:mm:ss"
            format.timeZone   = TimeZone(identifier: "Asia/Tokyo")
            let dateString = format.string(from: date)
            let notificationPath = "notification/\(friendEmail)/\(dateString)"
            
            
            database.child(path).setValue(myFriends) { [weak self](error, _) in
                guard error == nil else {
                    completion(false)
                    return
                }
                let ndate: [String: Any] = [
                    "model": "friend",
                    "id": "friend",
                    "friendEmail": [myEmail],
                    "is_read": false,
                    "time": dateString,
                    "whichTable": 0,
                    "textView": myName
                ]
                self?.database.child(notificationPath).updateChildValues(ndate)
                completion(true)
                
                self?.database.child(friendPath).observeSingleEvent(of: .value) { [weak self](snapshot) in
                    guard var friends = snapshot.value as? [String] else {
                        completion(false)
                        return
                    }
                    friends.append(myEmail)
                    self?.database.child(friendPath).setValue(friends)
                }
            }
        }
        
    }
    
    
    // ブロックしたら、自分のemailを追加
    public func blockedYou(myEmail: String, friendEmail: String, cancelBlock: Bool, completion: @escaping (Bool) -> (Void)) {
        if cancelBlock == true {
            let path = "block/\(myEmail)/\(friendEmail)"
            let path1 = "blocked/\(friendEmail)/\(myEmail)"
            database.child(path).removeValue()
            database.child(path1).removeValue()
            completion(true)
        }
        else {
            let path = "block/\(myEmail)"
            let data: [String: String] = [ "\(friendEmail)": "a" ]
            database.child(path).updateChildValues(data)
            
            let path1 = "blocked/\(friendEmail)"
            let data1: [String: String] = [  "\(myEmail)": "a" ]
            database.child(path1).updateChildValues(data1)
            
            completion(true)
        }
    }
    
    // 自分がブロックされているかどうか確かめる
    public func amIBlocked(myEmail: String, friendEmail: String, completion: @escaping (Bool) -> (Void)) {
        let path = "block/\(friendEmail)/\(myEmail)"
        database.child(path).observeSingleEvent(of: .value) { (snapshot) in
            guard let _ = snapshot.value as? String else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    //自分がブロックされているリストをfetch
    public func amIBlockedList(myEmail: String) {
        let path = "blocked/\(myEmail)"
        database.child(path).observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [String: String] else {
                UserDefaults.standard.setValue(nil, forKey: "amIBlocked")
                return
            }
            
            var blockedArray = [String]()
            for cell in value {
                blockedArray.append(cell.key)
            }
            UserDefaults.standard.setValue(blockedArray, forKey: "amIBlocked")
            return
        }
    }
    
    
    // 全てのデータを削除
    public func deleteAll(email: String, userInfo: ProfileInfo, completion: @escaping (Bool) -> (Void)) {
        
        let conversationPath = "allConversations/\(email)"
        let previousPath = "search/\(userInfo.age)/fac-dep/\(userInfo.university)/\(userInfo.faculty)/\(userInfo.department)/\(email)"
        let uniMemberPath = "search/\(userInfo.age)/university-member/\(userInfo.university)/\(email)"
        let notificationPath = "notification/\(email)"
        let notificationAshitoPath = "notification-ashiato/\(email)"
        let allUsersPath = "all_users/\(email)"
        let tokenPath = "userToken/\(email)"
        
        database.child(tokenPath).removeValue()
        database.child(conversationPath).removeValue()
        database.child(allUsersPath).removeValue()
        database.child(previousPath).removeValue()
        database.child(uniMemberPath).removeValue()
        database.child(notificationPath).removeValue()
        database.child(notificationAshitoPath).removeValue()
        
        // usersノードの削除
        // uidはfunctionsで削除
        let infoPath = "users/\(email)/info"
        let followPath = "users/\(email)/フォロワー"
        let followedPath = "users/\(email)/フォロー"
        let timeTablePath = "users/\(email)/time_schedule"
        
        
        database.child(infoPath).removeValue()
        database.child(followPath).removeValue()
        database.child(followedPath).removeValue()
        database.child(timeTablePath).removeValue()
        
        // Storageの削除をやりたい
        StorageManager.shared.deleteAllFile(email: email)
        
        let userPath = "users/\(email)/email"
        database.child(userPath).removeValue { [weak self](error, _) in
            guard error == nil else {
                completion(false)
                return
            }
            
            
            self?.firestore.collection("posts_individual").document(email).collection("all_posts").getDocuments(completion: { (querySnapshot, err) in
                
                guard err == nil, let strongSelf = self else {
                    completion(false)
                    return
                }
                var postArray = [Post]()
                for document in querySnapshot!.documents {
                    let dic = document.data()
                    postArray.append(strongSelf.convertPost(data: dic))
                }
                
                for post in postArray {
                    self?.firestore.collection("posts_individual").document(email).collection("all_posts").document(post.postId).delete()
                }
                self?.firestore.collection("posts_individual").document(email).delete()

                completion(true)
                
            })
        }
        
        
    }
    
    public func deleteToken(email: String) {
        let tokenPath = "userToken/\(email)"
        database.child(tokenPath).removeValue()
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // MARK: - TODOデータベース
    
    public func insertNewTodo(task: Task, completion: @escaping (Bool) -> (Void)) {
        
        let data: [String: Any] = [
            "taskId": task.taskId,
            "taskName": task.taskName,
            "timeSchedule": task.timeSchedule,
            "taskLimit": task.taskLimit,
            "documentPath": task.shareTask.documentPath,
            "memberCount": task.shareTask.memberCount,
            "makedEmail": task.shareTask.makedEmail,
            "doneMember": task.shareTask.doneMember,
            "gettingMember": task.shareTask.gettingMember,
            "wantToTalkMember": task.shareTask.wantToTalkMember
        ]
        firestore.collection("task").document(task.shareTask.documentPath).collection(task.timeSchedule).document(task.taskId).setData(data) { (error) in
            guard error == nil else {
                return
            }
            completion(true)
        }
        
    }
    
    
    public func fetchTargetTask(task: Task, completion: @escaping (Result<Task, Error>) -> (Void)) {
        
        firestore.collection("task").document(task.shareTask.documentPath).collection(task.timeSchedule).document(task.taskId).getDocument { (querySnapshot, error) in
            guard error == nil else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            //ブロックは省く
            let dic = querySnapshot!.data()
            guard dic != nil else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            
            if let taskId = dic?["taskId"] as? String,
               let taskName = dic?["taskName"] as? String,
               let taskLimit = dic?["taskLimit"] as? String,
               let timeSchedule = dic?["timeSchedule"] as? String,
               let documentPath = dic?["documentPath"] as? String,
               let memberCount = dic?["memberCount"] as? Int,
               let makedEmail = dic?["makedEmail"] as? String,
               let doneMember = dic?["doneMember"] as? [String],
               let gettingMember = dic?["gettingMember"] as? [String],
               let wantToTalkMember = dic?["wantToTalkMember"] as? [String]
            {
                let shareTask = ShareTask(documentPath: documentPath, memberCount: memberCount, makedEmail: makedEmail, doneMember: doneMember, gettingMember: gettingMember, wantToTalkMember: wantToTalkMember)
                let result = Task(taskId: taskId, taskName: taskName, notifyTime: "0", timeSchedule: timeSchedule, taskLimit: taskLimit, createDate: Date(), isFinish: false, shareTask: shareTask)
                completion(.success(result))
                return
            }
            completion(.failure(DatabaseError.failedToFetch))
        }
    }
    
    
    public func fetchTasks(timeSchedule: String, completion: @escaping (Result<[Task], Error>) -> (Void)) {
        
        var year = "none"
        var uni = "none"
        var fac = "none"
        if let year1 = UserDefaults.standard.value(forKey: "year") as? String { year = year1 }
        if let uni1 = UserDefaults.standard.value(forKey: "uni") as? String { uni = uni1 }
        if let fac1 = UserDefaults.standard.value(forKey: "fac") as? String { fac = fac1 }
        
        let fetchCount = 50
        
        firestore.collection("task").document("\(uni)\(year)\(fac)").collection(timeSchedule).order(by: "memberCount", descending: true).limit(to: fetchCount).getDocuments(completion: { (querySnapshot, error) in
            
            guard error == nil else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            //ブロックは省く
            var taskArray = [Task]()
            for document in querySnapshot!.documents {
                let dic = document.data()
                if let taskId = dic["taskId"] as? String,
                   let taskName = dic["taskName"] as? String,
                   let taskLimit = dic["taskLimit"] as? String,
                   let timeSchedule = dic["timeSchedule"] as? String,
                   let documentPath = dic["documentPath"] as? String,
                   let memberCount = dic["memberCount"] as? Int,
                   let makedEmail = dic["makedEmail"] as? String,
                   let doneMember = dic["doneMember"] as? [String],
                   let gettingMember = dic["gettingMember"] as? [String],
                   let wantToTalkMember = dic["wantToTalkMember"] as? [String]
                {
                    let shareTask = ShareTask(documentPath: documentPath, memberCount: memberCount, makedEmail: makedEmail, doneMember: doneMember, gettingMember: gettingMember, wantToTalkMember: wantToTalkMember)
                    let result = Task(taskId: taskId, taskName: taskName, notifyTime: "0", timeSchedule: timeSchedule, taskLimit: taskLimit, createDate: Date(), isFinish: false, shareTask: shareTask)
                    taskArray.append(result)
                }
            }
            
            completion(.success(taskArray))
            
        })
        
    }
    
    
    // todoに参加
    public func joinTargetTask(email: String, task: Task) {
        firestore.collection("task").document(task.shareTask.documentPath).collection(task.timeSchedule).document(task.taskId).updateData(["memberCount": FieldValue.increment(Int64(1))])
        firestore.collection("task").document(task.shareTask.documentPath).collection(task.timeSchedule).document(task.taskId).updateData(["gettingMember": FieldValue.arrayUnion([email])])
    }
    
    // finishに登録
    public func insertFinishTask(email: String, task: Task) {
        firestore.collection("task").document(task.shareTask.documentPath).collection(task.timeSchedule).document(task.taskId).updateData(["gettingMember": FieldValue.arrayRemove([email])])
        firestore.collection("task").document(task.shareTask.documentPath).collection(task.timeSchedule).document(task.taskId).updateData(["doneMember": FieldValue.arrayUnion([email])])
    }
    
    
    
    // wantToTalkに登録
    public func insertWantToTalk(email: String, task: Task) {
        firestore.collection("task").document(task.shareTask.documentPath).collection(task.timeSchedule).document(task.taskId).updateData(["wantToTalkMember": FieldValue.arrayUnion([email])])
    }
    // wanttoTalkから削除
    public func removeWantToTalk(email: String, task: Task) {
        firestore.collection("task").document(task.shareTask.documentPath).collection(task.timeSchedule).document(task.taskId).updateData(["wantToTalkMember": FieldValue.arrayRemove([email])])
    }
    
    // finishからgettingに戻す
    public func insertGettingTask(email: String, task: Task) {
        firestore.collection("task").document(task.shareTask.documentPath).collection(task.timeSchedule).document(task.taskId).updateData(["doneMember": FieldValue.arrayRemove([email])])
        firestore.collection("task").document(task.shareTask.documentPath).collection(task.timeSchedule).document(task.taskId).updateData(["gettingMember": FieldValue.arrayUnion([email])])
    }
    
    
    public func removeTask(email: String, task: Task) {
        firestore.collection("task").document(task.shareTask.documentPath).collection(task.timeSchedule).document(task.taskId).updateData(["doneMember": FieldValue.arrayRemove([email])])
        firestore.collection("task").document(task.shareTask.documentPath).collection(task.timeSchedule).document(task.taskId).updateData(["wantToTalkMember": FieldValue.arrayRemove([email])])
        firestore.collection("task").document(task.shareTask.documentPath).collection(task.timeSchedule).document(task.taskId).updateData(["gettingMember": FieldValue.arrayRemove([email])])
        firestore.collection("task").document(task.shareTask.documentPath).collection(task.timeSchedule).document(task.taskId).updateData(["memberCount": FieldValue.increment(Int64(-1))])
    }
    
    
    
}




struct ChatAppUser {
    
    let name: String
    let email: String
    
    var safeEmail: String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var profilePictureFileName: String {
        return "\(safeEmail)-profqile.png"
    }
}

