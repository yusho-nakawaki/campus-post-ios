//
//  ViewController.swift
//  Study_Match
//
//  on 2020/10/15.
//  Copyright © 2020 yusho. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseMessaging
import FirebaseDatabase
import JGProgressHUD


struct Conversation {
    let id: String
    let partner_name: String
    let partner_email: String
    var notification: Bool
    var latest_message: LatestMessage
}

struct ConversationGroup {
    let id: String
    let emailList: [String]
    var latest_message: LatestMessage
}

struct LatestMessage {
    var date: Date
    var text: String
    var isRead: Bool
}


class ConversationViewController: UIViewController, MessagingDelegate {
    
    
    private let spinner = JGProgressHUD(style: .dark)
    private var conversations = [Conversation]()
    private var loginObserver: NSObjectProtocol?
//    private var reloadDataObserver: NSObjectProtocol?
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }()
    
    private let noConversaionLavel: UILabel = {
        let label = UILabel()
        label.text = "友達とトークを開始してみよう"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 22, weight: .bold)
        return label
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
//        navigationItem.title = "チャット"
        navigationController?.navigationBar.tintColor = UIColor(named: "gentle")
        navigationController?.navigationBar.barTintColor = UIColor(named: "appBackground")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        if let settingLists = UserDefaults.standard.value(forKey: "setting") as? [[String: Any]] {
            var settingList = [Setting]()
            for cell in settingLists {
                guard let info = cell["info"] as? String,
                      let on = cell["on"] as? Bool else {
                    return
                }
                settingList.append(Setting(info: info, on: on))
            }
            if settingList[0].on == true {
                // 登録トークン取得のため
                Messaging.messaging().delegate = self
                insertMyToken()
            }
        }
        else {
            // 登録トークン取得のため
            Messaging.messaging().delegate = self
            insertMyToken()
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "person.badge.plus"), style: .done, target: self, action:  #selector(tappedRightBarButton))
        
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLoginNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.startListeningForConversations()
        })
        
        startListeningForConversations()
        
        view.addSubview(tableView)
        view.addSubview(noConversaionLavel)
        
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        if noConversaionLavel.isHidden == false {
            startListeningForConversations()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if view.width > 800 {
            tableView.frame = CGRect(x: (view.width-800)/2,
                                        y: 5,
                                        width: 800,
                                        height: view.height)
            noConversaionLavel.frame = CGRect(x: 10,
                                              y: (view.height-100)/2,
                                              width: view.width-20,
                                              height: 100)
            noConversaionLavel.font = .systemFont(ofSize: 25, weight: .bold)
        }
        else {
            tableView.frame = view.bounds
            noConversaionLavel.frame = CGRect(x: 10,
                                              y: (view.height-100)/2,
                                              width: view.width-20,
                                              height: 100)
        }
        
    }
    

    
    
    private func startListeningForConversations() {
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        // メモリ解放
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        DatabaseManager.shared.getAllConversations(for: safeMyEmail) { [weak self](result) in
            switch result {
            case .success(let conversations1):
                guard !conversations1.isEmpty,
                      let strongSelf = self else {
                    return
                }
                
                strongSelf.afterFetchConversations(conversationArray: conversations1)
            
            case .failure(let err):
                print("Error (ConversationVC startListeningForConversations): \(err)")
            }
        }
    }
    
    
    private func afterFetchConversations(conversationArray: [Conversation]) {
        
        conversations = conversationArray
        sortConversation()
        tableView.reloadData()
        tableView.isHidden = false
        noConversaionLavel.isHidden = true
        navBarNumber()
    }
    
    private func navBarNumber() {
        var notReadNumber = 0
        for cell in conversations {
            if cell.latest_message.isRead == false {
                notReadNumber += 1
            }
        }
        if notReadNumber == 0 {
            if let tabItem = tabBarController?.tabBar.items?[3] {
                tabItem.badgeValue = nil
                // badgeオフ
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
        else {
            if let tabItem = tabBarController?.tabBar.items?[3] {
                tabItem.badgeColor = UIColor.orange
                tabItem.badgeValue = "\(notReadNumber)"
            }
        }
    }
    
    
    @objc private func tappedRightBarButton() {
        let searchVC = SearchFriendsViewController()
        searchVC.completionForChatFriends = { [weak self]resultFriends in
            guard let strongSelf = self else {
                return
            }
            
            let currentConversations = strongSelf.conversations
            if let targetConversation = currentConversations.first(where: {
                $0.partner_email == resultFriends.email
            }) {
                // 上の条件式に当てはまったら
                let chatVC = ChatViewController(partnerEmail: targetConversation.partner_email, partnerName: targetConversation.partner_name, conversationId: targetConversation.id)
                chatVC.isNewConversation = false
                chatVC.title = targetConversation.partner_name
                chatVC.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(chatVC, animated: true)
            }
            else {
                // databaseにない新しくチャットを開始する人
                strongSelf.goChatBySearch(result: resultFriends)
            }
        }
        let navVC = UINavigationController(rootViewController: searchVC)
        present(navVC, animated: true)
    }
    
    private func goChatBySearch(result: SearchResult) {
        let partnerName = result.name
        let partnerEmail = result.email
        // 会話履歴があるかどうかをチェックする
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                return
        }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        DatabaseManager.shared.checkExistConversation(partnerEmail: partnerEmail, safeMyEmail: safeMyEmail) { [weak self](result) in
            switch result {
            case .success(let conversationid):
                if conversationid == "nil" {
                    // 初めてのチャット
                    // もしくはdelete後初めてのチャット
                    let chatVC = ChatViewController(partnerEmail: partnerEmail, partnerName: partnerName, conversationId: nil)
                    chatVC.isNewConversation = true
                    chatVC.title = partnerName
                    chatVC.navigationItem.largeTitleDisplayMode = .never
                    self?.navigationController?.pushViewController(chatVC, animated: true)
                }
                else {
                    let chatVC = ChatViewController(partnerEmail: partnerEmail, partnerName: partnerName, conversationId: conversationid)
                    chatVC.isNewConversation = false
                    chatVC.title = partnerName
                    chatVC.navigationItem.largeTitleDisplayMode = .never
                    self?.navigationController?.pushViewController(chatVC, animated: true)
                }
                
            case .failure(let error):
                print("error in tappedChatStartButton \(error)")
            }
        }
        
    }
    
    
    private func sortConversation() {
        conversations = conversations.sorted { (a, b) -> Bool in
            return a.latest_message.date > b.latest_message.date
        }
    }
    
    
    // トークンをdatabaseに
    private func insertMyToken() {
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                return
        }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        Messaging.messaging().token { token, error in
          if let error = error {
            print("Error fetching FCM registration token: \(error)")
          } else if let token = token {
            Database.database().reference().child("userToken/\(safeMyEmail)/token").setValue(
                ["token": token]
            )
          }
        }
    }
    
    
    func subscribeToPushNotifications() {
        Messaging.messaging().subscribe(toTopic: "pushNotifications")
    }
    
    func saveUsername() {
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                return
        }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(safeMyEmail, forKey: "username")
        userDefaults.synchronize()
        subscribeToPushNotifications()
    }
    
    
}



extension ConversationViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier,
                                                 for: indexPath) as! ConversationTableViewCell
        cell.userImageButton.tag = indexPath.row
        cell.userImageButton.addTarget(self, action: #selector(tapUserImage), for: .touchUpInside)
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        conversations[indexPath.row].latest_message.isRead = true
        if model.latest_message.isRead == false {
            navBarNumber()
        }
        let chatVC = ChatViewController(partnerEmail: model.partner_email, partnerName: model.partner_name, conversationId: model.id)
        chatVC.title = model.partner_name
        chatVC.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    
    @objc private func tapUserImage(_ sender: UIButton) {
        let indexpath = sender.tag
        let friendEmail = conversations[indexpath].partner_email
        let friendVC = FriendProfileViewController(partnerEmail: friendEmail)
        let nav = UINavigationController(rootViewController: friendVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    
    // スワイプでdelete
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let editAction = UIContextualAction(style: .normal, title: "") { [weak self](action, view, completionHandler) in
            
            //処理を記述
            if self?.conversations[indexPath.row].notification == true {
                DatabaseManager.shared.notificationOffConversation(partnerEmail: self?.conversations[indexPath.row].partner_email ?? "", conversationId: self?.conversations[indexPath.row].id ?? "")
                self?.conversations[indexPath.row].notification = false
                self?.tableView.reloadRows(at: [IndexPath(item: indexPath.row, section: 0)], with: .none)
            }
            else {
                DatabaseManager.shared.notificationOnConversation(partnerEmail: self?.conversations[indexPath.row].partner_email ?? "", conversationId: self?.conversations[indexPath.row].id ?? "")
                self?.conversations[indexPath.row].notification = true
                self?.tableView.reloadRows(at: [IndexPath(item: indexPath.row, section: 0)], with: .none)
            }
            
            // 実行結果に関わらず記述
            completionHandler(true)
        }
        if conversations[indexPath.row].notification == true {
            editAction.image = UIImage(systemName: "bell.slash")
        }
        else {
            editAction.image = UIImage(systemName: "bell")
        }
        return UISwipeActionsConfiguration(actions: [editAction])
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            let conversationId = conversations[indexPath.row].id
            conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            
            let date = Date()
            let format = DateFormatter()
            format.dateFormat = "yyyy-MM-dd HH:mm:ss"
            format.timeZone   = TimeZone(identifier: "Asia/Tokyo")
            let dateString = format.string(from: date)
            UserDefaults.standard.setValue(dateString, forKey: "delete")
            DatabaseManager.shared.deleteConversation(conversationId: conversationId, completion: { success in
                if !success {
                    print("fail to delete picture")
                }
            })
            tableView.endUpdates()
        }
    }
    
}
