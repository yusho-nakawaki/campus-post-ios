//
//  FriendProfileViewController.swift
//  BulletinBoard
//
//  on 2020/12/05.
//

import UIKit
import JGProgressHUD
import SDWebImage
import FirebaseAuth
import ImageSlideshow


struct ProfileInfo {
    var name: String
    var picutre: String
    let introduction: String
    let age: String
    let university: String
    let faculty: String
    let department: String
    var friendCount: String
}

class FriendProfileViewController: UIViewController {
    
    public var completionGoodFromProfile: ((String) -> (Void))?
    public var completionChangePicture: ((Bool) -> (Void))?
    
    var friendEmail: String

    var friendPosts = [Post]()
    var profileInfo = ProfileInfo(name: "", picutre: "", introduction: "", age: "", university: "", faculty: "", department: "", friendCount: "")
    var urlImage = ""
    var isBlocked = false
    var amIblocked = false
    var reloading = true
    var isGoMenu = true
    let semaphore = DispatchSemaphore(value: 1)
    var forGoodChange = ""
    
    
    private let spinner = JGProgressHUD()
    private var safeMyEmail = ""
    private var isFriend = false
    private var goAnimate = true //メニューの表示をされるかどうか

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UINib(nibName: "BullutinBoard2TableViewCell", bundle: nil), forCellReuseIdentifier: "BullutinBoard2TableViewCell")
        return tableView
    }()
    public var imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    private var userNameLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    private var uniAgeLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    private var facDepLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    private var friendCountButton: UIButton =  {
        let button = UIButton()
        return button
    }()
    private var userIntroduction: UITextView = {
        let text = UITextView()
        return text
    }()
    
    private var chatStartButton: UIButton = {
        let button = UIButton()
        return button
    }()
    private var timeScheduleButton: UIButton = {
        let button = UIButton()
        return button
    }()
    private var makeFriendsButton: UIButton = {
        let button = UIButton()
        return button
    }()
    
    // 設定
    private let menu: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .secondarySystemBackground
        return view
    }()
    private let mask: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.4)
        return view
    }()
    private var menuLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .medium)
        label.text = "プロフィールを変更"
        label.isUserInteractionEnabled = true
        return label
    }()
    private var menuLabe3: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .medium)
        label.text = "設定"
        label.isUserInteractionEnabled = true
        return label
    }()
    private var menuLabe4: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .medium)
        label.text = "公式Twitter"
        label.isUserInteractionEnabled = true
        return label
    }()
    private var menuLabe5: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .medium)
        label.text = "規約"
        label.isUserInteractionEnabled = true
        return label
    }()
    private var menuLabe6: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .medium)
        label.text = "運営に報告する"
        label.isUserInteractionEnabled = true
        return label
    }()
    private var alertMessageTextView: UITextView = { //運営に通報するの内容
        let text = UITextView()
        return text
    }()
    private var alertMask: UIView = {
        let view = UIView()
        return view
    }()
//    private var menuLabe7: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 19, weight: .medium)
//        label.text = "ログアウト"
//        label.isUserInteractionEnabled = true
//        return label
//    }()
    private var menuLabe8: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .medium)
        label.text = "全てのデータを削除"
        label.isUserInteractionEnabled = true
        return label
    }()
    
    
    init(partnerEmail: String) {
        self.friendEmail = partnerEmail
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        tableView.delegate = self
        tableView.dataSource = self
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "multiply"), style: .done, target: self, action: #selector(dismissSelf))
        
        view.addSubview(tableView)
        view.addSubview(menu)
        view.addSubview(mask)
        
        
        let path = "profile_picture/\(friendEmail)-profile.png"
        StorageManager.shared.getDownloadURL(for: path, completion: { [weak self]result in
            switch result {
            case .success(let url):
                self?.urlImage = url.absoluteString
                DispatchQueue.main.async {
                    self?.imageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(_):
                self?.imageView.image = UIImage(systemName: "person.circle")
                self?.imageView.tintColor = .gray
            }
        })
        
        
        
        if friendEmail == safeMyEmail {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(changeProfile))
            
            let tap1 = UITapGestureRecognizer(target: self, action: #selector(description1))
            menuLabel.addGestureRecognizer(tap1)
            let tap3 = UITapGestureRecognizer(target: self, action: #selector(description3))
            menuLabe3.addGestureRecognizer(tap3)
            let tap4 = UITapGestureRecognizer(target: self, action: #selector(description4))
            menuLabe4.addGestureRecognizer(tap4)
            let tap5 = UITapGestureRecognizer(target: self, action: #selector(description5))
            menuLabe5.addGestureRecognizer(tap5)
            let tap6 = UITapGestureRecognizer(target: self, action: #selector(description6))
            menuLabe6.addGestureRecognizer(tap6)
//            let tap7 = UITapGestureRecognizer(target: self, action: #selector(description7))
//            menuLabe7.addGestureRecognizer(tap7)
            let tap8 = UITapGestureRecognizer(target: self, action: #selector(description8))
            menuLabe8.addGestureRecognizer(tap8)
            
            menu.addSubview(menuLabel)
            menu.addSubview(menuLabe3)
            menu.addSubview(menuLabe4)
            menu.addSubview(menuLabe5)
            menu.addSubview(menuLabe6)
//            menu.addSubview(menuLabe7)
            menu.addSubview(menuLabe8)
            
        }
        else {
            if let blockedList = UserDefaults.standard.value(forKey: "blocked") as? [String] {
                for cell in blockedList {
                    if cell == friendEmail {
                        isBlocked = true
                        break
                    }
                }
            }
            
            if let myFriends = UserDefaults.standard.value(forKey: "myFriends") as? [String] {
                for cell in myFriends {
                    if cell == friendEmail {
                        isFriend = true
                        break
                    }
                }
            }
            
            
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(tappedFriendMune))
        }
        
        
        tableView.tableHeaderView = createTableHeader()
        navigationController?.navigationBar.tintColor = UIColor(named: "gentle")
        navigationController?.navigationBar.barTintColor = UIColor(named: "appBackground")
        
        
        chatStartButton.addTarget(self, action: #selector(tappedChatStart), for: .touchUpInside)
        timeScheduleButton.addTarget(self, action: #selector(tappedTimeSchedule), for: .touchUpInside)
        makeFriendsButton.addTarget(self, action: #selector(tappedMakeFriends), for: .touchUpInside)
        friendCountButton.addTarget(self, action: #selector(tappedFriendCount), for: .touchUpInside)
        
        
        DatabaseManager.shared.fetchUserInfo(userEmail: friendEmail) { [weak self](result) in
            switch result {
            case .success(let info):
                self?.profileInfo = info
                self?.setupAfterFetch(info: info)
            case .failure(let error):
                self?.alertUserError(alertMessage: "このユーザーは退会しました")
                print(error)
            }
        }
        
        
               
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapImage))
        imageView.addGestureRecognizer(tap)
        
        if safeMyEmail != friendEmail {
            DatabaseManager.shared.amIBlocked(myEmail: safeMyEmail, friendEmail: friendEmail) { [weak self](amIBlocked) -> (Void) in
                if amIBlocked == true {
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.amIblocked = true
                    let blockedContainer = UIView(frame: CGRect(x: 0, y: strongSelf.friendCountButton.bottom + 10, width: strongSelf.view.width, height: strongSelf.view.height))
                    blockedContainer.backgroundColor = .systemBackground
                    let blockedLabel = UILabel(frame: CGRect(x: 0, y: 100, width: strongSelf.view.width, height: 30))
                    blockedLabel.text = "ブロックされています"
                    blockedLabel.font = .systemFont(ofSize: 16, weight: .bold)
                    blockedLabel.textColor = .gray
                    blockedLabel.backgroundColor = .systemBackground
                    blockedLabel.textAlignment = .center
                    blockedContainer.addSubview(blockedLabel)
                    strongSelf.tableView.addSubview(blockedContainer)
                }
            }
        }
        
        
    }
    
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if view.width > 800 {
            let safeY = view.safeAreaInsets.top
            tableView.frame = CGRect(x: (view.width-800)/2,
                                        y: 5,
                                        width: 800,
                                        height: view.height)
            menu.frame = CGRect(x: view.width,
                                y: safeY,
                                width: 250,
                                height: view.height)
            mask.frame = CGRect(x: view.width,
                                y: safeY,
                                width: view.width - menu.width,
                                height: view.height)
        }
        else {
            let safeY = view.safeAreaInsets.top
            tableView.frame = view.bounds
            menu.frame = CGRect(x: view.width, y: safeY, width: 250, height: view.height)
            mask.frame = CGRect(x: view.width, y: safeY, width: view.width - menu.width, height: view.height)
        }
        
    }
    
    
    
    func createTableHeader() -> UIView {

        // imageViewの設定
        imageView = UIImageView(frame: CGRect(x: 15,
                                              y: 15,
                                              width: 80,
                                              height: 80))
        imageView.layer.cornerRadius = 40
        imageView.tintColor = .gray
        imageView.image = UIImage(systemName: "person.circle")
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.isUserInteractionEnabled = true
        
        // userNameLableの設定
        userNameLabel = UILabel(frame: CGRect(x: 15,
                                              y: 105,
                                              width: 220,
                                              height: 25))
        userNameLabel.text = ""
        userNameLabel.font = .systemFont(ofSize: 18, weight: .medium)
        
        
        //大学と学年
        uniAgeLabel = UILabel(frame: CGRect(x: 15,
                                            y: userNameLabel.bottom,
                                            width: view.width - 30,
                                            height: 18))
        uniAgeLabel.text = ""
        uniAgeLabel.font = .systemFont(ofSize: 15, weight: .regular)
        
        //学部学科
        facDepLabel = UILabel(frame: CGRect(x: 15,
                                            y: uniAgeLabel.bottom,
                                            width: view.width - 30,
                                            height: 18))
        facDepLabel.text = ""
        facDepLabel.font = .systemFont(ofSize: 15, weight: .regular)
        
        //友達数ボタン
        friendCountButton = UIButton(frame: CGRect(x: 15,
                                                   y: facDepLabel.bottom,
                                                   width: view.width - 30,
                                                   height: 18))
        friendCountButton.setTitleColor(.label, for: .normal)
        friendCountButton.titleLabel?.font = .systemFont(ofSize: 15)
        friendCountButton.contentHorizontalAlignment = .left
        
        // userIntroductionの設定
        userIntroduction = UITextView(frame: CGRect(x: 10,
                                                    y: friendCountButton.bottom + 10,
                                                    width: view.width - 30,
                                                    height: 120))
        userIntroduction.isEditable = false
        userIntroduction.isSelectable = false
        userIntroduction.isScrollEnabled = false
        userIntroduction.text = ""
        userIntroduction.font = .systemFont(ofSize: 18, weight: .regular)
        
        var buttonSpace = (view.width - 95 - 150)/4
        if view.width > 800 {
            buttonSpace = (800 - 95 - 150)/4
        }
        // 時間割
        timeScheduleButton = UIButton(frame: CGRect(x: imageView.right + buttonSpace,
                                                    y: 34,
                                                    width: 50,
                                                    height: 50))
        timeScheduleButton.setImage(UIImage(systemName: "calendar"), for: .normal)
        timeScheduleButton.layer.cornerRadius = 25
        timeScheduleButton.tintColor = UIColor(red: 0.12, green: 0.71, blue: 0.12, alpha: 1)
        timeScheduleButton.layer.borderWidth = 1
        timeScheduleButton.layer.borderColor = UIColor(red: 0.12, green: 0.71, blue: 0.12, alpha: 0.3).cgColor
        // chatStartButtonの設定
        chatStartButton = UIButton(frame: CGRect(x: timeScheduleButton.right + buttonSpace,
                                                 y: 34,
                                                 width: 50,
                                                 height: 50))
        chatStartButton.setImage(UIImage(systemName: "message"), for: .normal)
        chatStartButton.layer.cornerRadius = 25
        chatStartButton.tintColor = UIColor(red: 0.12, green: 0.71, blue: 0.12, alpha: 1)
        chatStartButton.layer.borderWidth = 1
        chatStartButton.layer.borderColor = UIColor(red: 0.12, green: 0.71, blue: 0.12, alpha: 0.3).cgColor
        
        
        
//        makeFriendsButtonの設定
        makeFriendsButton = UIButton(frame: CGRect(x: chatStartButton.right + buttonSpace,
                                                   y: 34,
                                                   width: 50,
                                                   height: 50))
        
        
        if isBlocked == true {
            makeFriendsButton.setImage(UIImage(systemName: "multiply"), for: .normal)
            makeFriendsButton.tintColor = .red
            makeFriendsButton.layer.borderWidth = 1
            makeFriendsButton.layer.borderColor = UIColor.red.cgColor
        }
        else {
            makeFriendsButton.setImage(UIImage(systemName: "person.fill.badge.plus"), for: .normal)
            makeFriendsButton.tintColor = UIColor(red: 0.12, green: 0.71, blue: 0.12, alpha: 1)
            makeFriendsButton.layer.borderWidth = 1
            makeFriendsButton.layer.borderColor = UIColor(red: 0.12, green: 0.71, blue: 0.12, alpha: 0.3).cgColor
        }
        if isFriend == true {
            makeFriendsButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
        }
        makeFriendsButton.layer.cornerRadius = 25
        
        var headerView = UIView(frame: CGRect(x: 0,
                                              y: 0,
                                              width: view.width,
                                              height: 360))
        if view.width > 800 {
            headerView = UIView(frame: CGRect(x: (view.width-800)/2,
                                                  y: 0,
                                                  width: 800,
                                                  height: 360))
        }
            
        headerView.addSubview(imageView)
        headerView.addSubview(userNameLabel)
        headerView.addSubview(uniAgeLabel)
        headerView.addSubview(facDepLabel)
        headerView.addSubview(userIntroduction)
        headerView.addSubview(friendCountButton)
        headerView.addSubview(timeScheduleButton)
        headerView.addSubview(chatStartButton)
        headerView.addSubview(makeFriendsButton)
        return headerView
    }

    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isBlocked == false && amIblocked == false {
            DatabaseManager.shared.fetchFriendPosts(friendEmail: friendEmail, nowPostCount: friendPosts.count, completion: { [weak self](result) in
                switch result {
                case .success(let resultPost):
                    self?.friendPosts = resultPost
                    self?.sortPosts()
                    self?.tableView.reloadData()
                case .failure(let error):
                    print("error in FriendProfileVC in viewDidAppear \(error)")
                }
            })
        }
        
        
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissSetting))
        mask.addGestureRecognizer(tap)
        
        if safeMyEmail == friendEmail {
            DatabaseManager.shared.reloadMySearch(myEmail: safeMyEmail, info: profileInfo)
        }
        else {
            if isBlocked == true {
                let blockedContainer = UIView(frame: CGRect(x: 0, y: friendCountButton.bottom + 10, width: view.width, height: view.height))
                blockedContainer.backgroundColor = .systemBackground
                let blockedLabel = UILabel(frame: CGRect(x: 0, y: 100, width: view.width, height: 30))
                blockedLabel.text = "ブロックしています"
                blockedLabel.font = .systemFont(ofSize: 16, weight: .bold)
                blockedLabel.textColor = .gray
                blockedLabel.backgroundColor = .systemBackground
                blockedLabel.textAlignment = .center
                blockedContainer.addSubview(blockedLabel)
                tableView.addSubview(blockedContainer)
            }
            if isBlocked == false && amIblocked == false {
                let date = Date()
                let format = DateFormatter()
                format.dateFormat = "yyyy-MM-dd HH:mm:ss"
                format.timeZone   = TimeZone(identifier: "Asia/Tokyo")
                let dateString = format.string(from: date)
                DatabaseManager.shared.insertAshiato(myEmail: safeMyEmail, friendEmail: friendEmail, date: dateString)
            }
        }
        
        
    }
    
    
    @objc private func dismissSelf() {
        if forGoodChange == "" {
            dismiss(animated: true, completion: nil)
        }
        else {
            dismiss(animated: true) { [weak self] in
                self?.completionGoodFromProfile?(self?.forGoodChange ?? "")
            }
        }
    }
        
    
    // chatStartButton
    @objc private func tappedChatStart() {
        guard friendEmail != safeMyEmail else {
            return
        }
        guard isBlocked == false else {
            alertUserError(alertMessage: "\(profileInfo.name)さんをブロックしています。")
            return
        }
        guard amIblocked == false else {
            alertUserError(alertMessage: "\(profileInfo.name)さんにブロックされています")
            return
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        spinner.show(in: view)
        
        // 会話履歴があるかどうかをチェックする
        DatabaseManager.shared.checkExistConversation(partnerEmail: friendEmail, safeMyEmail: safeMyEmail) { [weak self](result) in
            switch result {
            case .success(let conversationid):
                if conversationid == "nil" {
                    // 初めてのチャット
                    // もしくはdelete後初めてのチャット
                    let chatVC = ChatViewController(partnerEmail: self?.friendEmail ?? "", partnerName: self?.userNameLabel.text ?? "", conversationId: nil)
                    chatVC.isNewConversation = true
                    chatVC.title = self?.userNameLabel.text
                    chatVC.navigationItem.largeTitleDisplayMode = .never
                    self?.spinner.dismiss()
                    self?.navigationController?.pushViewController(chatVC, animated: true)
                }
                else {
                    let chatVC = ChatViewController(partnerEmail: self?.friendEmail ?? "", partnerName: self?.userNameLabel.text ?? "", conversationId: conversationid)
                    chatVC.isNewConversation = false
                    chatVC.title = self?.userNameLabel.text
                    chatVC.navigationItem.largeTitleDisplayMode = .never
                    self?.spinner.dismiss()
                    self?.navigationController?.pushViewController(chatVC, animated: true)
                }
                
            case .failure(let error):
                print("error in tappedChatStartButton \(error)")
            }
        }
    }
    
    @objc private func tappedTimeSchedule() {
        guard isBlocked == false else {
            alertUserError(alertMessage: "\(profileInfo.name)さんをブロックしています")
            return
        }
        guard amIblocked == false else {
            alertUserError(alertMessage: "\(profileInfo.name)さんにブロックされています")
            return
        }
        
        let storyboard: UIStoryboard = UIStoryboard(name: "TimeSchedule", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "segueTimeSchedule") as! TimeSchedule
        vc.friendEmail = friendEmail
        vc.fromProfileVC = true
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    
    @objc private func tappedMakeFriends() {
        guard friendEmail != safeMyEmail else {
            return
        }
        if isBlocked == true {
            let alert: UIAlertController = UIAlertController(title: "",
                                                             message: "ブロックを解除しますか？",
                                                             preferredStyle: .alert)
            
            let defaultAction: UIAlertAction = UIAlertAction(title: "解除する",
                                                             style: .default,
                                                             handler:{ [weak self]_ in
                self?.blockYou()
            })
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "解除しない",
                                                            style: .cancel,
                                                            handler:{ _ in
            })
            
            alert.addAction(cancelAction)
            alert.addAction(defaultAction)
            
            present(alert, animated: true, completion: nil)
        }
        else {
            if isFriend == false && amIblocked == true {
                alertUserError(alertMessage: "\(profileInfo.name)さんにブロックされています")
                return
            }
            DatabaseManager.shared.FollowYou(myEmail: safeMyEmail, friendEmail: friendEmail, isUnFollow: isFriend) { [weak self](success) -> (Void) in
                if success == true {
                    guard let strongSelf = self,
                          let userName = strongSelf.userNameLabel.text else {
                        return
                    }
                    if strongSelf.isFriend == true {
                        let actionSheet = UIAlertController(title: "",
                                                            message: "",
                                                            preferredStyle: .actionSheet)
                        actionSheet.addAction(UIAlertAction(title: "\(strongSelf.profileInfo.name)さんを友達登録からはずす", style: .destructive, handler: { _ in
                            
                            strongSelf.isFriend = false
//                            strongSelf.friendLabel.isHidden = true
                            strongSelf.makeFriendsButton.setImage(UIImage(systemName: "person.fill.badge.plus"), for: .normal)
                            strongSelf.alertMessage(alertMessage: "\(userName)さんのフォローを外しました")
                        }))
                        
                        
                        actionSheet.addAction(UIAlertAction(title: "cancel",
                                                            style: .cancel,
                                                            handler: nil))
                        strongSelf.present(actionSheet, animated: true)
                    }
                    else {
                        strongSelf.isFriend = true
//                        strongSelf.friendLabel.isHidden = false
                        strongSelf.makeFriendsButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
                        strongSelf.alertMessage(alertMessage: "\(userName)さんをフォローしました")
                    }
                }
            }
        }
        
    }
    
    @objc private func tappedFriendCount() {
        let goodlistVC = GoodListViewController(postId: "", whichTable: 0)
        goodlistVC.friendEmail = friendEmail
        goodlistVC.friendName = profileInfo.name
        goodlistVC.isFriendsMember = true
        navigationController?.pushViewController(goodlistVC, animated: true)
    }
    
    
    @objc private func tappedFriendMune() {
        guard let friendName = userNameLabel.text else {
            return
        }
        let actionSheet = UIAlertController(title: "",
                                            message: "",
                                            preferredStyle: .actionSheet)
        if isBlocked == true {
            actionSheet.addAction(UIAlertAction(title: "\(friendName)さんのブロックを解除する", style: .default, handler: { [weak self] _ in
                self?.blockYou()
            }))
        }
        else {
            actionSheet.addAction(UIAlertAction(title: "\(friendName)さんをブロックする", style: .default, handler: { [weak self] _ in
                self?.blockYou()
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: "cancel",
                                            style: .cancel,
                                            handler: nil))
        present(actionSheet, animated: true)
    }
    
    private func blockYou() {
        if isBlocked == true {
            // ブロック解除
            DatabaseManager.shared.blockedYou(myEmail: safeMyEmail, friendEmail: friendEmail, cancelBlock: true) { [weak self](success) -> (Void) in
                if success == true {
                    self?.unBlock()
                }
            }
            
        }
        else {
            // ブロック
            if var blockedList = UserDefaults.standard.value(forKey: "blocked") as? [String] {
                blockedList.append(friendEmail)
                UserDefaults.standard.setValue(blockedList, forKey: "blocked")
            }
            else {
                let blockedList: [String] = [friendEmail]
                UserDefaults.standard.setValue(blockedList, forKey: "blocked")
            }
            
            if isFriend == true {
                DatabaseManager.shared.FollowYou(myEmail: safeMyEmail, friendEmail: friendEmail, isUnFollow: true) { (success) -> (Void) in
                    print("success")
                }
            }
            DatabaseManager.shared.blockedYou(myEmail: safeMyEmail, friendEmail: friendEmail, cancelBlock: false) { [weak self](success) -> (Void) in
                if success == true {
                    self?.isBlocked = true
                    self?.makeFriendsButton.setImage(UIImage(systemName: "multiply"), for: .normal)
                    self?.makeFriendsButton.tintColor = .red
                    self?.makeFriendsButton.layer.borderColor = UIColor.red.cgColor
                    self?.makeFriendsButton.layer.borderWidth = 1
                    self?.alertMessage(alertMessage: "ブロックしました")
                }
            }
        }
        
    }
    
    private func unBlock() {
        if var blockedList = UserDefaults.standard.value(forKey: "blocked") as? [String] {
            var i = 0
            for cell in blockedList {
                if cell == friendEmail {
                    blockedList.remove(at: i)
                    break
                }
                i += 1
            }
            UserDefaults.standard.setValue(blockedList, forKey: "blocked")
            
            isBlocked = false
            makeFriendsButton.setImage(UIImage(systemName: "person.fill.badge.plus"), for: .normal)
            makeFriendsButton.tintColor = UIColor(red: 0.12, green: 0.71, blue: 0.12, alpha: 1)
            makeFriendsButton.layer.borderColor = UIColor(red: 0.12, green: 0.71, blue: 0.12, alpha: 1).cgColor
            alertMessage(alertMessage: "ブッロクを解除しました")
        }
    }
    
    
    // change my profile
    @objc private func changeProfile() {
        
        
        if goAnimate == true && isGoMenu == true {
            isGoMenu = false
            let menuImage1 = UIButton(frame: CGRect(x: 20, y: 55, width: 30, height: 30))
            menuImage1.addTarget(self, action: #selector(description1), for: .touchUpInside)
            menuImage1.setImage(UIImage(systemName: "person.crop.rectangle"), for: .normal)
            menuImage1.tintColor = .label
            menuLabel.frame = CGRect(x: 60, y: 50, width: menu.width - 30, height: 40)
            let menuImage3 = UIButton(frame: CGRect(x: 20, y: menuLabel.bottom + 25, width: 30, height: 30))
            menuImage3.addTarget(self, action: #selector(description3), for: .touchUpInside)
            menuImage3.setImage(UIImage(systemName: "gearshape"), for: .normal)
            menuImage3.tintColor = .label
            menuLabe3.frame = CGRect(x: 60, y: menuLabel.bottom + 20, width: menu.width - 30, height: 40)
            let menuImage4 = UIButton(frame: CGRect(x: 25, y: menuLabe3.bottom + 30, width: 20, height: 20))
            menuImage4.addTarget(self, action: #selector(description4), for: .touchUpInside)
            menuImage4.setImage(UIImage(named: "twitter-icon"), for: .normal)
            menuImage4.tintColor = .label
            menuLabe4.frame = CGRect(x: 60, y: menuLabe3.bottom + 20, width: menu.width - 30, height: 40)
            let menuImage5 = UIButton(frame: CGRect(x: 20, y: menuLabe4.bottom + 25, width: 30, height: 30))
            menuImage5.addTarget(self, action: #selector(description5), for: .touchUpInside)
            menuImage5.setImage(UIImage(systemName: "doc.plaintext"), for: .normal)
            menuImage5.tintColor = .label
            menuLabe5.frame = CGRect(x: 60, y: menuLabe4.bottom + 20, width: menu.width - 30, height: 40)
            let menuImage6 = UIButton(frame: CGRect(x: 20, y: menuLabe5.bottom + 25, width: 30, height: 30))
            menuImage6.addTarget(self, action: #selector(description6), for: .touchUpInside)
            menuImage6.setImage(UIImage(systemName: "paperplane"), for: .normal)
            menuImage6.tintColor = .label
            menuLabe6.frame = CGRect(x: 60, y: menuLabe5.bottom + 20, width: menu.width - 30, height: 40)
//            let menuImage7 = UIButton(frame: CGRect(x: 20, y: menuLabe6.bottom + 25, width: 30, height: 30))
//            menuImage7.addTarget(self, action: #selector(description7), for: .touchUpInside)
//            menuImage7.setImage(UIImage(systemName: "icloud.and.arrow.up"), for: .normal)
//            menuImage7.tintColor = .label
//            menuLabe7.frame = CGRect(x: 60, y: menuLabe6.bottom + 20, width: menu.width - 30, height: 40)
            let menuImage8 = UIButton(frame: CGRect(x: 20, y: menuLabe6.bottom + 25, width: 30, height: 30))
            menuImage8.addTarget(self, action: #selector(description8), for: .touchUpInside)
            menuImage8.setImage(UIImage(systemName: "person.badge.minus"), for: .normal)
            menuImage8.tintColor = .label
            menuLabe8.frame = CGRect(x: 60, y: menuLabe6.bottom + 20, width: menu.width - 30, height: 40)
            let menuLabe9 = UILabel(frame: CGRect(x: 25, y: menuLabe8.bottom + 30, width: menu.width - 30, height: 40))
            menuLabe9.text = "ID： \(String(friendEmail.prefix(friendEmail.count - 10)))"
            menuLabe9.font = .systemFont(ofSize: 17, weight: .regular)
            
            menu.contentSize = CGSize(width:menu.width, height: menuLabe9.bottom + 20)
            
            menu.addSubview(menuImage1)
            menu.addSubview(menuImage3)
            menu.addSubview(menuImage4)
            menu.addSubview(menuImage5)
            menu.addSubview(menuImage6)
//            menu.addSubview(menuImage7)
            menu.addSubview(menuImage8)
            menu.addSubview(menuLabe9)
            
            
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .transitionCurlDown, animations: { [weak self] in
                self?.menu.center.x -= self?.menu.layer.frame.width ?? 250
                self?.mask.center.x -= self?.view.width ?? 0
            }, completion: { [weak self] _ in
                self?.goAnimate = false
                self?.isGoMenu = true
            })
            
        }
        if goAnimate == false {
            menu.center.x += menu.width
            mask.center.x += view.width
            goAnimate = true
            isGoMenu = true
        }
        
    }
    
    @objc private func didSwipe(sender: UISwipeGestureRecognizer) {
        if sender.direction == .right {
            changeProfile()
        }
        else if sender.direction == .left {
            changeProfile()
        }
        else if sender.direction == .down {
            dismissSelf()
        }
    }
    
    
    private func setupAfterFetch(info: ProfileInfo) {
        userNameLabel.text = info.name
        
        let date = Date()
        let yearformat = DateFormatter()
        yearformat.dateFormat = "yyyy"
        yearformat.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        let yearString = yearformat.string(from: date)
        let monthformat = DateFormatter()
        monthformat.dateFormat = "MM"
        monthformat.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let monthString = monthformat.string(from: date)
        
        if let year = Int(info.age), let nowYear = Int(yearString) {
            let schoolYear = nowYear - year
            if monthString == "01" || monthString == "02" {
                uniAgeLabel.text = "\(info.university) \(schoolYear)年生"
            }
            else {
                uniAgeLabel.text = "\(info.university) \(schoolYear + 1)年生"
            }
        }
        
        if info.faculty == "" {
            facDepLabel.text = "学部未設定"
        }
        else {
            facDepLabel.text = "\(info.faculty) \(info.department)"
        }
        
        userIntroduction.text = info.introduction
        userIntroduction.sizeToFit()
        
        friendCountButton.setTitle("友達追加 \(info.friendCount)人", for: .normal)
        
        let width = tableView.width
        let border = CALayer()
        border.frame = CGRect(x: 15, y: userIntroduction.bottom + 20, width: width - 30, height: 1.0)
        border.backgroundColor = UIColor.systemGray5.cgColor
        tableView.layer.addSublayer(border)
        
        changeSize()
        
        if friendEmail == "unnei-gmail-com" {
            facDepLabel.text = ""
            uniAgeLabel.text = "*** 公式アカウント ***"
        }
        
        //これから直さなくては行けない
        DatabaseManager.shared.fetchFollowMember(friendEmail: friendEmail) { [weak self] (result) in
            switch result {
            case .success(let friendsMemeber):
                self?.friendCountButton.setTitle("友達追加 \(friendsMemeber.count)人", for: .normal)
            case .failure(let error):
                print("failed fetch friend \(error)")
            }
        }
    }
    
    @objc private func tapImage() {
        let photoVC = PhotoViewController(data: nil, url: URL(string: urlImage))
        photoVC.downloadButton.isHidden = true
        let nav = UINavigationController(rootViewController: photoVC)
        present(nav, animated: true, completion: nil)
    }
    
    
    @objc private func dismissSetting() {
        menu.center.x += menu.width
        mask.center.x += view.width
        goAnimate = true
    }
    
    @objc private func description1() {
        if let myName = UserDefaults.standard.value(forKey: "name") as? String {
            let changeMyInfo = BasicUserInfo(email: safeMyEmail, name: myName)
            changeMyInfo.currentInfo = profileInfo
            changeMyInfo.profilePicture = urlImage
            navigationController?.pushViewController(changeMyInfo, animated: true)
        }
        else {
            let changeMyInfo = BasicUserInfo(email: safeMyEmail, name: "ゲスト")
            changeMyInfo.currentInfo = profileInfo
            changeMyInfo.profilePicture = urlImage
            navigationController?.pushViewController(changeMyInfo, animated: true)
        }
    }
    
    @objc private func description3() {
        let settingVC = SettingViewController()
        navigationController?.pushViewController(settingVC, animated: true)
    }
    @objc private func description4() {
        goAnimate = true
        isGoMenu = true
        
        let url = URL(string: "https://twitter.com/campus_posts")!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    @objc private func description5() {
        let storyboard = UIStoryboard(name: "Web", bundle: nil)
        let post = storyboard.instantiateViewController(withIdentifier: "segueWeb") as! WebViewController
        post.urlString = "https://campus-post.net/terms-of-service.html"

        let nav = UINavigationController(rootViewController: post)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    @objc private func description6() {
        alertMask = UIView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: view.width,
                                        height: view.height))
        alertMask.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        let alertContainer = UIView(frame: CGRect(x: 20,
                                                  y: 150,
                                                  width: view.width - 40,
                                                  height: 200))
        let alertLabel = UILabel(frame: CGRect(x: (alertContainer.width*1/10),
                                               y: 20,
                                               width: alertContainer.width*4/5,
                                               height: 20))
        alertMessageTextView = UITextView(frame: CGRect(x: alertContainer.width*1/10,
                                                        y: alertLabel.bottom,
                                                        width: alertContainer.width*4/5,
                                                        height: 100))
        let cancelButton = UIButton(frame: CGRect(x: (alertContainer.width - 200)/2,
                                                  y: alertMessageTextView.bottom + 10,
                                                  width: 80,
                                                  height: 30))
        let sendButton = UIButton(frame: CGRect(x: cancelButton.right + 40,
                                                y: alertMessageTextView.bottom + 10,
                                                width: 80,
                                                height: 30))
        alertContainer.backgroundColor = .secondarySystemBackground
        alertContainer.layer.cornerRadius = 10
        alertLabel.text = "相談したいことや改善点など"
        alertLabel.textColor = .darkGray
        alertMessageTextView.layer.borderWidth = 1
        alertMessageTextView.backgroundColor = .secondarySystemBackground
        alertMessageTextView.layer.borderColor = UIColor.gray.cgColor
        alertMessageTextView.font = .systemFont(ofSize: 18)
        alertMessageTextView.layer.cornerRadius = 5
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.darkGray, for: .normal)
        cancelButton.addTarget(self, action: #selector(tap6Cancel), for: .touchUpInside)
        sendButton.setTitle("送信する", for: .normal)
        sendButton.setTitleColor(.darkGray, for: .normal)
        sendButton.addTarget(self, action: #selector(tap6Send), for: .touchUpInside)
        
        alertContainer.addSubview(alertMessageTextView)
        alertContainer.addSubview(alertLabel)
        alertContainer.addSubview(cancelButton)
        alertContainer.addSubview(sendButton)
        alertMask.addSubview(alertContainer)
        view.addSubview(alertMask)
        
    }
    @objc private func tap6Cancel() {
        goAnimate = true
        alertMessageTextView.resignFirstResponder()
        alertMask.isHidden = true
    }
    @objc private func tap6Send() {
        tap6Cancel()
        alertMessageTextView.resignFirstResponder()
        guard let text = alertMessageTextView.text,
              text != "" else {
            return
        }
        DatabaseManager.shared.alertForFriendVC(myEmail: safeMyEmail, friendEmail: friendEmail, message: text) { [weak self] (success) in
            if success == true {
                self?.alertMessage(alertMessage: "運営に報告しました。メッセージありがとうございます。")
            }
        }
    }
    
    @objc private func description7() {
        let alert: UIAlertController = UIAlertController(title: "",
                                                         message: "本当に退会しますか",
                                                         preferredStyle: .alert)
        
        let defaultAction: UIAlertAction = UIAlertAction(title: "退会します",
                                                         style: .destructive,
                                                         handler:{ [weak self]_ in
            do {
                try
                Auth.auth().signOut()
                self?.cleanInformationForSignout()
                let registerVC = RegisterViewController()
                let nav = UINavigationController(rootViewController: registerVC)
                nav.modalPresentationStyle = .fullScreen
                self?.present(nav, animated: true)
            }
            catch {
                self?.alertUserError(alertMessage: "通信に失敗しました。リロードしてください。")
            }
        })
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "しません",
                                                        style: .cancel,
                                                        handler:{ _ in
        })
        
        alert.addAction(cancelAction)
        alert.addAction(defaultAction)
        
        present(alert, animated: true, completion: nil)

    }
    
    @objc private func description8() {
        let alert: UIAlertController = UIAlertController(title: "全てのデータを消します",
                                                         message: "本当によろしいですか？",
                                                         preferredStyle: .alert)
        
        let defaultAction: UIAlertAction = UIAlertAction(title: "退会します", style: .destructive, handler:{ [weak self]_ in
                                    
            guard let strongSelf = self else {
                return
            }
            strongSelf.spinner.show(in: strongSelf.view)
            DatabaseManager.shared.deleteAll(email: strongSelf.safeMyEmail, userInfo: strongSelf.profileInfo, completion: { (success) -> (Void) in
                
                if success == true {
                    Auth.auth().currentUser?.delete() { error in
                        if error == nil {
                            // 非ログイン時の画面へ
                            strongSelf.spinner.dismiss()
                            strongSelf.cleanInformationForSignout()
                            let registerVC = RegisterViewController()
                            let nav = UINavigationController(rootViewController: registerVC)
                            nav.modalPresentationStyle = .fullScreen
                            strongSelf.present(nav, animated: true)
                        }
                        strongSelf.spinner.dismiss()
                        strongSelf.cleanInformationForSignout()
                        strongSelf.alertMessage(alertMessage: "退会しました。アプリを落としてください。")
                        return
                    }
                }
                else {
                    strongSelf.spinner.dismiss()
                    strongSelf.alertMessage(alertMessage: "退会しました。アプリを落としてください")
                }
                
            })
        })
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル",
                                                        style: .cancel,
                                                        handler:{ _ in
        })
        
        alert.addAction(cancelAction)
        alert.addAction(defaultAction)
        
        present(alert, animated: true, completion: nil)

    }
    
    func updateIndividualDataBottom () {
        DispatchQueue.global().async {
            //*** ここでデータを更新する処理をする ***
            self.fetchIndividualOldPosts()
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.semaphore.signal() // 処理が終わった信号を送る
            }
        }
    }
    
    private func fetchIndividualOldPosts() {
        // tableViewを上に引っ張る処理
        
        DatabaseManager.shared.fetchIndividualPostInfo(nowPostCount: friendPosts.count, friendEmail: friendEmail) { [weak self](result) -> (Void) in
            switch result {
            case .success(let postArray):
                self?.friendPosts = postArray
                self?.tableView.reloadData()
                self?.reloading = true
            case .failure(let error):
                self?.alertUserError(alertMessage: "通信エラーが起きました。アプリを落としてもう一度開いてください。")
                print("failed to fetch post: \(error)")
            }
        }
    }
    
    private func cleanInformationForSignout() {
        UserDefaults.standard.setValue(nil, forKey: "email")
        UserDefaults.standard.setValue(nil, forKey: "name")
        UserDefaults.standard.setValue(nil, forKey: "profile_picutre_url")
        UserDefaults.standard.setValue(nil, forKey: "my_picture")
        UserDefaults.standard.setValue(nil, forKey: "fetch_date_all")
        UserDefaults.standard.setValue(nil, forKey: "fetch_date_faculty")
        UserDefaults.standard.setValue(nil, forKey: "blocked")
        UserDefaults.standard.setValue(nil, forKey: "amIBlocked")
        UserDefaults.standard.setValue(nil, forKey: "myFriends")
        UserDefaults.standard.setValue(nil, forKey: "myTimeSchedule")
        UserDefaults.standard.setValue(nil, forKey: "classTime")
        UserDefaults.standard.setValue(nil, forKey: "myTasks")
        UserDefaults.standard.setValue(nil, forKey: "onClassTime")
        UserDefaults.standard.setValue(nil, forKey: "uni")
        UserDefaults.standard.setValue(nil, forKey: "age")
        UserDefaults.standard.setValue(nil, forKey: "fac")
        UserDefaults.standard.setValue(nil, forKey: "setting")
    }
    
    
    private func changeSize() {
        let introdutionHeight = userIntroduction.height
        
        tableView.tableHeaderView?.frame.size.height += introdutionHeight - 120
        tableView.reloadData()
    }
    
    
    private func sortPosts() {
        friendPosts = friendPosts.sorted(by: { (a, b) -> Bool in
            return a.postTime > b.postTime
        })
    }
    
    
    func alertUserError(alertMessage: String) {
        let alert = UIAlertController(title: "エラー",
                                      message: alertMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true)
    }
    
    func alertMessage(alertMessage: String) {
        let alert = UIAlertController(title: "メッセージ",
                                      message: alertMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true)
    }
    
    
}










extension FriendProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        friendPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let model = friendPosts[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "BullutinBoard2TableViewCell", for: indexPath) as! BullutinBoard2TableViewCell
        cell.selectionStyle = .none
        
        if model.isRemessage != nil { cell.isRepeat = true }
        else {  cell.isRepeat = false }
        if model.shareTask != nil { cell.isTask = true }
        else { cell.isTask = false }
        cell.configure(model: model)
        
        cell.replayButton.tag = indexPath.row
        cell.replayButton.addTarget(self, action: #selector(tapReplay(_:)), for: .touchUpInside)
        cell.repeatButton.tag = indexPath.row
        cell.repeatButton.addTarget(self, action: #selector(tappedRepeat), for: .touchUpInside)
        cell.goodButton.tag = indexPath.row
        cell.goodButton.tintColor = .systemGray
        cell.goodButton.addTarget(self, action: #selector(tappedGood), for: .touchUpInside)
        cell.goodNumberButton.tag = indexPath.row
        cell.goodNumberButton.addTarget(self, action: #selector(tappedGoodNumber), for: .touchUpInside)
        cell.repeatNumberButton.tag = indexPath.row
        cell.repeatNumberButton.addTarget(self, action: #selector(tappedRepeatNumber), for: .touchUpInside)
        cell.otherMenuButton.tag = indexPath.row
        cell.otherMenuButton.addTarget(self, action: #selector(tappedOther), for: .touchUpInside)
        cell.repeatTableViewButton.tag = indexPath.row
        cell.repeatTableViewButton.addTarget(self, action: #selector(tapRepeatTableView), for: .touchUpInside)
        
        if model.photoUrl != nil {
            if model.photoUrl?.count == 1 {
                let tapGesture1 = UITapGestureRecognizer(target: self, action: #selector(tapImage1))
                cell.postImage1.addGestureRecognizer(tapGesture1)
            }
            else {
                let tapGesture1 = UITapGestureRecognizer(target: self, action: #selector(tapImage1))
                cell.postImage1.addGestureRecognizer(tapGesture1)
                let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector(tapImage2))
                cell.postImage2.addGestureRecognizer(tapGesture2)
                let tapGesture3 = UITapGestureRecognizer(target: self, action: #selector(tapImage3))
                cell.postImage3.addGestureRecognizer(tapGesture3)
                let tapGesture4 = UITapGestureRecognizer(target: self, action: #selector(tapImage4))
                cell.postImage4.addGestureRecognizer(tapGesture4)
            }
            
            if view.width > 600 {
                if model.photoUrl?.count == 1 {
                    cell.imageContainerMerginRight.constant = 400
                }
                cell.imageContainerMerginRight.constant = 200
            }
        }
        
        // 毎回この重い処理が走っていいのか
        cell.goodButton.setImage(UIImage(systemName: "heart"), for: .normal)
        for goodEmail in model.goodList {
            if goodEmail == safeMyEmail {
                cell.goodButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
                cell.goodButton.tintColor = .systemRed
                break
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.estimatedRowHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = friendPosts[indexPath.row]
        print(model)
        print(model.shareTask)
        let before5 = model.postId.suffix(5)
        var whichTable = Int(before5.prefix(1)) ?? 0
        if whichTable == 4 { whichTable = 0}
        let vc = UserPost(model: model, whichTable: whichTable)
        navigationController?.pushViewController(vc, animated: true)
    }
    
   
    
    @objc func tapReplay(_ sender: UIButton) {
        let indexpath = sender.tag
        let storyboard: UIStoryboard = UIStoryboard(name: "Replay", bundle: nil)
        let replayVC = storyboard.instantiateViewController(withIdentifier: "segueReplay") as! ReplayViewController
        replayVC.replayParentPost = friendPosts[indexpath]
        
        let before5 = friendPosts[indexpath].postId.suffix(5)
        var whichTable = Int(before5.prefix(1)) ?? 0
        if whichTable == 4 { whichTable = 0}
        
        replayVC.whichTable = whichTable
        
                
        let nav = UINavigationController(rootViewController: replayVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }

    @objc private func tappedRepeat(_ sender: UIButton) {
        let indexpath = sender.tag
        let before5 = friendPosts[indexpath].postId.suffix(5)
        var whichTable = Int(before5.prefix(1)) ?? 0
        if whichTable == 4 { whichTable = 0}
        
        let storyboard: UIStoryboard = UIStoryboard(name: "Replay", bundle: nil)
        let replayVC = storyboard.instantiateViewController(withIdentifier: "segueReplay") as! ReplayViewController
        replayVC.repeatParentPost = friendPosts[indexpath]
        replayVC.isRepeatMessage = true
        replayVC.isReplayRepeat = 1
        replayVC.whichTable = whichTable
        
        let nav = UINavigationController(rootViewController: replayVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
    
    
    @objc private func tappedGood(_ sender: UIButton) {
        let indexpath = sender.tag
        let indexPath = IndexPath(row: indexpath, section: 0)
        
        var i = 0
        for goodEmail in friendPosts[indexpath].goodList {
            if safeMyEmail == goodEmail {
                // remove good
                friendPosts[indexpath].goodList.remove(at: i)
                friendPosts[indexpath].good -= 1
                tableView.reloadRows(at: [indexPath], with: .fade)
                DatabaseManager.shared.insertMyGoodList(targetPost: friendPosts[indexpath], whichTable: 0, whichVC: 4, uni: profileInfo.university, year: profileInfo.age, fac: profileInfo.faculty) { (success) in
                    if success == true {
                        print("success insert goodList")
                    }
                }
                
                if forGoodChange == "" {
                    forGoodChange = friendPosts[indexpath].postId
                }
                else {
                    // いいねして外した
                    forGoodChange = ""
                }
                
                return
            }
            i += 1
        }
        
        // いいねの追加
        friendPosts[indexpath].good += 1
        friendPosts[indexpath].goodList.append(safeMyEmail)
        tableView.reloadRows(at: [indexPath], with: .fade)
        
        // communityVCといいねをリンクさせる
//        NotificationCenter.default.post(name: .insertGoodFromProfile, object: nil)
        forGoodChange = friendPosts[indexpath].postId
        
        // goodListに入れる
        DatabaseManager.shared.insertMyGoodList(targetPost: friendPosts[indexpath], whichTable: 0, whichVC: 2, uni: profileInfo.university, year: profileInfo.age, fac: profileInfo.faculty) { (success) in
            if success == true {
                print("success insert goodList")
            }
        }
        
    }
    
    @objc private func tappedGoodNumber(_ sender: UIButton) {
        let indexpath = sender.tag
        let targetPost = friendPosts[indexpath]
        let before5 = friendPosts[indexpath].postId.suffix(5)
        var whichTable = Int(before5.prefix(1)) ?? 0
        if whichTable == 4 { whichTable = 0}
        
        let goodListVC = GoodListViewController(postId: targetPost.postId, whichTable: whichTable)
        goodListVC.targetPost = targetPost
        let nav = UINavigationController(rootViewController: goodListVC)
        present(nav, animated: true)
    }
    
    @objc private func tappedRepeatNumber(_ sender: UIButton) {
        let indexpath = sender.tag
        let targetPost = friendPosts[indexpath]
        let before5 = friendPosts[indexpath].postId.suffix(5)
        var whichTable = Int(before5.prefix(1)) ?? 0
        if whichTable == 4 { whichTable = 0}
        
        let goodListVC = GoodListViewController(postId: targetPost.postId, whichTable: whichTable)
        goodListVC.targetPost = targetPost
        goodListVC.isReaptMember = true
        let nav = UINavigationController(rootViewController: goodListVC)
        present(nav, animated: true)
    }
    
    
    @objc private func tappedOther(_ sender: UIButton) {
        let indexpath = sender.tag
        let alertPost = friendPosts[indexpath]
        otherMenuActionSheet(alertPost: alertPost, indexpath: indexpath)
    }
    

    @objc private func tapRepeatTableView(_ sender: UIButton) {
        let indexpath = sender.tag
        let before5 = friendPosts[indexpath].postId.suffix(5)
        var whichTable = Int(before5.prefix(1)) ?? 0
        if whichTable == 4 { whichTable = 0}
        
        if let target = friendPosts[indexpath].isRemessage {
            if target.isRemessage == nil {
                // isRemessageがないバージョン
                let remessagePost = Post(postId: target.parentPostId, postMessage: target.postMessage, postEmail: target.postEmail, postName: target.postName, postTime: target.postTime, good: target.good, goodList: target.goodList, remessage: target.remessage, remessagePostArray: target.remessagePostArray, isRemessage: nil, comment: target.comment, isComment: target.isComment, photoUrl: target.photoUrl)
                let userPost = UserPost(model: remessagePost, whichTable: whichTable)
                navigationController?.pushViewController(userPost, animated: true)
            }
            if let isRemessage = target.isRemessage {
                // さらにisRemessageがあるバージョン
                // fetchPostIdはremessageの情報もfetchするから、もっと効率の良く書けるはず
                spinner.show(in: view)
                DatabaseManager.shared.fetchPostId(whichTable: whichTable, postId: isRemessage) { [weak self](result) in
                    switch result {
                    case .success(let fetchPost):
                        var reremessagePost: Remessage?
                        if fetchPost.isRemessage == nil {
                            // parentPostがリメッセージしてない場合
                            reremessagePost = Remessage(parentPostId: fetchPost.postId, postMessage: fetchPost.postMessage, postEmail: fetchPost.postEmail, postName: fetchPost.postName, postTime: fetchPost.postTime, good: fetchPost.good, goodList: fetchPost.goodList, remessage: fetchPost.remessage, remessagePostArray: fetchPost.remessagePostArray, isRemessage: nil, comment: fetchPost.comment, isComment: fetchPost.isComment, photoUrl: fetchPost.photoUrl)
                        }
                        else if let isRemessagePostId = fetchPost.isRemessage?.parentPostId {
                            // parentPostがリメッセージした場合
                            reremessagePost = Remessage(parentPostId: fetchPost.postId, postMessage: fetchPost.postMessage, postEmail: fetchPost.postEmail, postName: fetchPost.postName, postTime: fetchPost.postTime, good: fetchPost.good, goodList: fetchPost.goodList, remessage: fetchPost.remessage, remessagePostArray: fetchPost.remessagePostArray, isRemessage: isRemessagePostId, comment: fetchPost.comment, isComment: fetchPost.isComment, photoUrl: fetchPost.photoUrl)
                        }
                        
                        if let rowReremessagePost = reremessagePost {
                            let remessagePost = Post(postId: target.parentPostId, postMessage: target.postMessage, postEmail: target.postEmail, postName: target.postName, postTime: target.postTime, good: target.good, goodList: target.goodList, remessage: target.remessage, remessagePostArray: target.remessagePostArray, isRemessage: rowReremessagePost, comment: target.comment, isComment: target.isComment, photoUrl: target.photoUrl)
                            let userPost = UserPost(model: remessagePost, whichTable: whichTable)
                            self?.spinner.dismiss()
                            self?.navigationController?.pushViewController(userPost, animated: true)
                        }
                    case .failure(_):
                        print("failed to fetch in tapRepeatTableView(fetchPostId)")
                    }
                }
            }

        }
        
        // taskをタップ
        if let task = friendPosts[indexpath].shareTask {
            let storyboard: UIStoryboard = UIStoryboard(name: "ShareTodo", bundle: nil)
            let shareTodoViewController = storyboard.instantiateViewController(withIdentifier: "ShareTodoViewController") as! ShareTodoViewController
            shareTodoViewController.task = Task(taskId: task.taskId, taskName: task.taskName, notifyTime: "", timeSchedule: task.timeSchedule, taskLimit: task.taskLimit, createDate: Date(), isFinish: false, shareTask: ShareTask(documentPath: task.documentPath, memberCount: task.memberCount, makedEmail: task.makedEmail, doneMember: task.doneMember, gettingMember: task.gettingMember, wantToTalkMember: task.wantToTalkMember))
            let nav = UINavigationController(rootViewController: shareTodoViewController)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        }
    }
    
    
    
    private func otherMenuActionSheet(alertPost: Post, indexpath: Int) {
        
        let before5 = alertPost.postId.suffix(5)
        var whichTable = Int(before5.prefix(1)) ?? 0
        if whichTable == 4 { whichTable = 0}
        
        let actionSheet = UIAlertController(title: "",
                                            message: "",
                                            preferredStyle: .actionSheet)
        if alertPost.postEmail == safeMyEmail {
            actionSheet.addAction(UIAlertAction(title: "この投稿を削除する", style: .default, handler: { [weak self] _ in
                DatabaseManager.shared.removePost(postId: alertPost.postId, postEmail: self?.safeMyEmail ?? "", whichTable: whichTable, isParentPath: nil) { (succuss) in
                    if succuss == true {
                        self?.alertMessage(alertMessage: "この投稿を削除しました")
                        self?.friendPosts.remove(at: indexpath)
                        self?.tableView.reloadData()
                    }
                    else {
                        self?.alertUserError(alertMessage: "ネットワークを確認してください")
                    }
                }
            }))
        }
        actionSheet.addAction(UIAlertAction(title: "通報する", style: .default, handler: { [weak self] _ in
            DatabaseManager.shared.alertPost(postId: alertPost.postId, whichTable: whichTable) { (success) in
                if success == true {
                    self?.alertMessage(alertMessage: "この投稿を通報しました")
                }
                else {
                    self?.alertUserError(alertMessage: "ネットワークを確認してください")
                }
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "キャンセル",
                                            style: .cancel,
                                            handler: nil))
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            actionSheet.popoverPresentationController?.sourceView = self.view
            let screenSize = UIScreen.main.bounds
            actionSheet.popoverPresentationController?.sourceRect = CGRect(x: screenSize.size.width/2, y: screenSize.size.height, width: 0, height: 0)
        }
        present(actionSheet, animated: true)
    }
    
    
    
    @objc private func tapImage1(gestureRecognizer: UITapGestureRecognizer, index: Int) {
        
        let tappedLocation = gestureRecognizer.location(in: tableView)
        let tappedIndexPath = tableView.indexPathForRow(at: tappedLocation)
        guard let tappedRow = tappedIndexPath?.row else { return }
        let imageSlideshow = ImageSlideshow()
        
        var sdWebImageSource = [SDWebImageSource]()
        if friendPosts[tappedRow].photoUrl?.count == 1 {
            sdWebImageSource = [SDWebImageSource(urlString: (friendPosts[tappedRow].photoUrl?[0]) ?? "")!]
        }
        if friendPosts[tappedRow].photoUrl?.count == 2 {
            sdWebImageSource = [SDWebImageSource(urlString: (friendPosts[tappedRow].photoUrl?[0]) ?? "")!, SDWebImageSource(urlString: (friendPosts[tappedRow].photoUrl?[1]) ?? "")!]
            if index == 1 { sdWebImageSource.swapAt(0, 1) }
        }
        if friendPosts[tappedRow].photoUrl?.count == 3 {
            sdWebImageSource = [SDWebImageSource(urlString: (friendPosts[tappedRow].photoUrl?[0]) ?? "")!, SDWebImageSource(urlString: (friendPosts[tappedRow].photoUrl?[1]) ?? "")!, SDWebImageSource(urlString: (friendPosts[tappedRow].photoUrl?[2]) ?? "")!]
            if index == 1 { sdWebImageSource.swapAt(0, 1); sdWebImageSource.swapAt(1, 2) }
            if index == 2 { sdWebImageSource.swapAt(0, 1); sdWebImageSource.swapAt(0, 2) }
        }
        if friendPosts[tappedRow].photoUrl?.count == 4 {
            sdWebImageSource = [SDWebImageSource(urlString: (friendPosts[tappedRow].photoUrl?[0]) ?? "")!, SDWebImageSource(urlString: (friendPosts[tappedRow].photoUrl?[1]) ?? "")!, SDWebImageSource(urlString: (friendPosts[tappedRow].photoUrl?[2]) ?? "")!, SDWebImageSource(urlString: (friendPosts[tappedRow].photoUrl?[3]) ?? "")!]
            if index == 1 { sdWebImageSource.swapAt(0, 1); sdWebImageSource.swapAt(1, 2); sdWebImageSource.swapAt(2, 3) }
            if index == 2 { sdWebImageSource.swapAt(0, 2); sdWebImageSource.swapAt(1, 3) }
            if index == 3 { sdWebImageSource.swapAt(2, 3); sdWebImageSource.swapAt(1, 2); sdWebImageSource.swapAt(0, 1) }
        }
        imageSlideshow.setImageInputs(sdWebImageSource)
        //ImageSlideshow.
        let fullScreenController = imageSlideshow.presentFullScreenController(from: self)
        fullScreenController.slideshow.activityIndicator = nil
        fullScreenController.slideshow.pageIndicator = nil
    }
    @objc private func tapImage2(gestureRecognizer: UITapGestureRecognizer) {
        tapImage1(gestureRecognizer: gestureRecognizer, index: 1)
    }
    @objc private func tapImage3(gestureRecognizer: UITapGestureRecognizer) {
        tapImage1(gestureRecognizer: gestureRecognizer, index: 2)
    }
    @objc private func tapImage4(gestureRecognizer: UITapGestureRecognizer) {
        tapImage1(gestureRecognizer: gestureRecognizer, index: 3)
    }
    
    
    // 上に引っ張る処理
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isBlocked == false && amIblocked == false {
            let height = scrollView.frame.size.height
            let contentYoffset = scrollView.contentOffset.y
            let distanceFromBottom = scrollView.contentSize.height - contentYoffset + 80
            if distanceFromBottom < height {
                
                if reloading == true { // デリゲートは何回も呼ばれてしまうので、リロード中はfalseにしておく
                    updateIndividualDataBottom()
                    semaphore.wait()
                    semaphore.signal()
                    reloading = false
                }
            }
        }
    }
}

