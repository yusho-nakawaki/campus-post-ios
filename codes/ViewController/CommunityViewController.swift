//
//  ViewController.swift
//  BulletinBoard
//
//  on 2020/11/25.
//

import UIKit
import JGProgressHUD
import ImageSlideshow

struct Post {
    let postId: String
    let postMessage: String
    let postEmail: String
    let postName: String
    let postTime: String
    var good: Int
    var goodList: [String]
    var remessage: Int
    var remessagePostArray: [String]
    var isRemessage: Remessage?
    var comment: Int
    var isComment: String?
    let photoUrl: [String]?
    var shareTask: BullutinTask?
}

struct Remessage {
    let parentPostId: String
    let postMessage: String
    let postEmail: String
    let postName: String
    let postTime: String
    var good: Int
    var goodList: [String]
    var remessage: Int
    var remessagePostArray: [String]
    var isRemessage: String? //RemessageのparentPostIdを入れる
    var comment: Int
    var isComment: String?
    let photoUrl: [String]?
    var shareTask: BullutinTask?
}

struct BullutinTask {
    let taskId: String
    let taskName: String
    let taskLimit: String
    let timeSchedule: String
    let documentPath: String //"\(uni)\(year)\(fac)"
    var memberCount: Int
    let makedEmail: String
    var doneMember: [String]
    var gettingMember: [String]
    var wantToTalkMember: [String]
}




class CommunityViewController: UIViewController, UITabBarControllerDelegate {

    
    public var posts_all = [Post]()
    public var posts_faculty = [Post]()
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    let semaphore = DispatchSemaphore(value: 1)
    var reloading = true
    
    let underlineLayer = CALayer()
    var segmentItemWidth: CGFloat = 0
    private var whichTable = 1 // 0が全ての人, 1が学部
    
    
    private let spinner = JGProgressHUD()
    private var safeMyEmail = ""
    public var isAfterPost = false
    private var isFirstFlow = true
    private var changeGoodForProfile = ""
    
    public let tableViewAll: UITableView = {
        let table = UITableView()
        table.register(UINib(nibName: "BullutinBoard2TableViewCell", bundle: nil), forCellReuseIdentifier: "BullutinBoard2TableViewCell")
        return table
    }()
    public let tableViewFaculty: UITableView = {
        let table = UITableView()
        table.register(UINib(nibName: "BullutinBoard2TableViewCell", bundle: nil), forCellReuseIdentifier: "BullutinBoard2TableViewCell")
        return table
    }()
    
    private let commentButton: UIButton = {
        let button = UIButton()
        let largeConfiguration = UIImage.SymbolConfiguration(scale: .large)
        let buttonImage = UIImage(systemName: "square.and.pencil", withConfiguration: largeConfiguration)
        button.setImage(buttonImage, for: .normal)
        button.tintColor = .white
        button.contentMode = .scaleAspectFit
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 30
        button.backgroundColor = UIColor(red: 0.12, green: 0.71, blue: 0.12, alpha: 1)
        return button
    }()
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let email = DatabaseManager.safeEmail(emailAddress: myEmail)
        safeMyEmail = email
        
        fetchFacultyPosts()
        setUpForViewDidLoad()
    }
    
    
    private func setUpForViewDidLoad() {
        tableViewAll.delegate = self
        tableViewAll.dataSource = self
        tableViewAll.refreshControl = UIRefreshControl()
        tableViewAll.refreshControl?.addTarget(self, action: #selector(refreshAll), for: .valueChanged)
        tableViewFaculty.delegate = self
        tableViewFaculty.dataSource = self
        tableViewFaculty.refreshControl = UIRefreshControl()
        tableViewFaculty.refreshControl?.addTarget(self, action: #selector(refreshFaculty), for: .valueChanged)
        
        // スワイプでtableViewを変える
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(sender:)))
        leftSwipe.direction = .left
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(sender:)))
        rightSwipe.direction = .right
        tableViewAll.addGestureRecognizer(rightSwipe)
        tableViewFaculty.addGestureRecognizer(leftSwipe)
        
        tabBarController?.delegate = self
        isFirstFlow = true
        
        setupNavigationbar()
        setupSegmentedControl()
        
        view.addSubview(tableViewAll)
        view.addSubview(tableViewFaculty)
        view.addSubview(commentButton)
        
        commentButton.addTarget(self, action: #selector(didTapCommentButton), for: .touchUpInside)
    }
    

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard isFirstFlow == true else {
            return
        }
        isFirstFlow = false
        
        if view.width > 800 {
            tableViewAll.frame = CGRect(x: view.width + (view.width-800)/2,
                                        y: 5,
                                        width: 800,
                                        height: view.height)
            tableViewFaculty.frame = CGRect(x: (view.width-800)/2,
                                            y: 5,
                                            width: 800,
                                            height: view.height)
                
            
            let safeBottom = view.safeAreaInsets.bottom
            commentButton.frame = CGRect(x: tableViewFaculty.right - 90,
                                         y: view.height - safeBottom - 90,
                                         width: 80,
                                         height: 80)
            commentButton.layer.cornerRadius = 40
        }
        else {
            tableViewAll.frame = CGRect(x: view.width, y: 0, width: view.width, height: view.height)
            tableViewFaculty.frame = CGRect(x: 0, y: 0, width: view.width, height: view.height)
            let safeBottom = view.safeAreaInsets.bottom
            commentButton.frame = CGRect(x: view.width - 90, y: view.height - safeBottom - 90, width: 60, height: 60)
        }
        
        
        spinner.show(in: view)
        
        // 自分がブロックされている人たちをfetch
        DatabaseManager.shared.amIBlockedList(myEmail: safeMyEmail)
        
        if let _ = UserDefaults.standard.value(forKey: "name") as? String { }
        else {
            alertMessage(alertMessage: "左上のアイコンをタップして、プロフィールを完成させよう")
        }
        
    }
    
    
    
    private func setupNavigationbar() {
        
        view.backgroundColor = UIColor(named: "appBackground")
        navigationController?.navigationBar.tintColor = UIColor(named: "gentle")
        navigationController?.navigationBar.barTintColor = UIColor(named: "appBackground")

        
        let button: UIBarButtonItem = UIBarButtonItem.init(
                                        barButtonSystemItem: .search,
                                        target: self,
                                        action: #selector(didTapSearch))
        button.tintColor = .label
        navigationItem.rightBarButtonItem = button
        
        // profile画面へ
        let menuBtn = UIButton(type: .custom)
        menuBtn.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        menuBtn.contentMode = .scaleAspectFill
        menuBtn.clipsToBounds = true
        if let myPictureData = UserDefaults.standard.value(forKey: "my_picture") as? Data {
            menuBtn.setImage(UIImage(data: myPictureData), for: .normal)
        }
        else {
            menuBtn.setImage(UIImage(systemName: "person.circle"), for: .normal)
        }
        menuBtn.addTarget(self, action: #selector(myProfilePicture), for: .touchUpInside)
        
        let menuBarItem = UIBarButtonItem(customView: menuBtn)
        let currWidth = menuBarItem.customView?.widthAnchor.constraint(equalToConstant: 32)
        currWidth?.isActive = true
        let currHeight = menuBarItem.customView?.heightAnchor.constraint(equalToConstant: 32)
        currHeight?.isActive = true
        menuBarItem.customView?.layer.cornerRadius = 16
        navigationItem.leftBarButtonItem = menuBarItem
        
    }
    
    
    private func fetchAllPosts() {
        UserDefaults.standard.setValue(nil, forKey: "fetch_date_all")
        DatabaseManager.shared.fetchPostInfo(whichTable: whichTable, nowPostCount: posts_all.count) { [weak self](result) -> (Void) in
            switch result {
            case .success(let postArray):
                self?.posts_all = postArray
                self?.tableViewAll.reloadData()
            case .failure(let error):
                self?.alertUserError(alertMessage: "通信エラーが起きました。アプリを落としてもう一度開いてください。")
                print("failed to fetch post: \(error)")
            }
        }
    }
    
    
    private func fetchFacultyPosts() {
        UserDefaults.standard.setValue(nil, forKey: "fetch_date_faculty")
        DatabaseManager.shared.fetchFacultyPostInfo(whichTable: whichTable, nowPostCount: posts_faculty.count) { [weak self](result) -> (Void) in
            switch result {
            case .success(let postArray):
                self?.posts_faculty = postArray
                self?.tableViewFaculty.reloadData()
                self?.spinner.dismiss()
                self?.fetchAllPosts()
            case .failure(let error):
                self?.spinner.dismiss()
                self?.alertUserError(alertMessage: "通信エラーが起きました。アプリを落としてもう一度開いてください。")
                print("failed to fetch post: \(error)")
            }
        }
    }
    

    
    @objc private func didTapSearch() {
        let searchSubjectVC = SearchSubject()
        let nav = UINavigationController(rootViewController: searchSubjectVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    
    @objc private func didTapCommentButton() {
        let storyboard: UIStoryboard = UIStoryboard(name: "PostView", bundle: nil)
        let post = storyboard.instantiateViewController(withIdentifier: "seguePost") as! PostViewController
        if whichTable == 0 { post.fromGroup = "all" }
        if whichTable == 1 { post.fromGroup = "fac" }
        post.completionPost = { [weak self] (success) in
            if success == true {
                guard let strongSelf = self else { return }
                if strongSelf.whichTable == 0 { strongSelf.fetchAllNewPosts() }
                if strongSelf.whichTable == 1 { strongSelf.fetchFacultyNewPosts() }
            }
            else {
                self?.alertMessage(alertMessage: "ネットワーク環境を確認してください")
            }
        }
        let nav = UINavigationController(rootViewController: post)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    
    
    private func setupSegmentedControl() {
        
        segmentedControl.selectedSegmentIndex = 0
        
        segmentedControl.frame.size.width = view.width*0.7
        segmentedControl.frame.size.height = 43
        segmentedControl.tintColor = .label
        
        segmentItemWidth = view.width*0.35
        underlineLayer.backgroundColor = UIColor(red: 0.12, green: 0.71, blue: 0.12, alpha: 1).cgColor
        underlineLayer.frame = CGRect(x: 0, y: 41, width: view.width*0.35, height: 2)
        segmentedControl.layer.addSublayer(underlineLayer)
        segmentedControl.iOS12Style()
    }
    
    
    @IBAction func tapSegment(_ sender: Any) {
        let x = CGFloat(segmentedControl.selectedSegmentIndex) * segmentItemWidth
        underlineLayer.frame.origin.x = x
        
        if segmentedControl.selectedSegmentIndex == 0 {
            whichTable = 1
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .transitionCurlDown, animations: { [weak self] in
                let viewWidth = self?.view.width ?? 0
                self?.tableViewAll.frame.origin.x += viewWidth
                self?.tableViewFaculty.frame.origin.x += viewWidth
            }, completion: { [weak self] _ in
                self?.tableViewFaculty.reloadData()
            })
        } else if segmentedControl.selectedSegmentIndex == 1 {
            whichTable = 0
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .transitionCurlDown, animations: { [weak self] in
                self?.tableViewAll.frame.origin.x -= self?.view.width ?? 0
                self?.tableViewFaculty.frame.origin.x -= self?.view.width ?? 0
            }, completion: { [weak self] _ in
                self?.tableViewAll.reloadData()
            })
        }
    }
    
    @objc private func didSwipe(sender: UISwipeGestureRecognizer) {
        if sender.direction == .right {
            segmentedControl.selectedSegmentIndex = 0
            tapSegment(sender)
        }
        else if sender.direction == .left {
            segmentedControl.selectedSegmentIndex = 1
            tapSegment(sender)
        }
    }
    
    
    
    @objc private func refreshAll() {
        // tableViewを下に引っ張る処理
        updateAllDataTop()
        
        semaphore.wait()
        semaphore.signal()
        tableViewAll.refreshControl?.endRefreshing()
    }
    
    @objc private func refreshFaculty() {
        // tableViewを下に引っ張る処理
        updateFacultyDataTop()
        
        semaphore.wait()
        semaphore.signal()
        tableViewFaculty.refreshControl?.endRefreshing()
    }

    
    func updateAllDataTop () {
        DispatchQueue.global().async {
            //*** ここでデータを更新する処理をする ***
            self.fetchAllNewPosts()
            DispatchQueue.main.async {
                self.semaphore.signal() // 処理が終わった信号を送る
            }
        }
    }
    
    func updateFacultyDataTop () {
        DispatchQueue.global().async {
            self.fetchFacultyNewPosts()
            DispatchQueue.main.async {
                self.semaphore.signal()
            }
        }
    }
    
    
    private func fetchAllNewPosts() {
        // 初めての投稿はposts[0].postTimeがない
        var postTime = ""
        if posts_all.count >= 1 {
            postTime = posts_all[0].postTime
        }
        else {
            let date = Date()
            let preDate = Calendar.current.date(byAdding: .day, value: -1, to: date)!
            let format = DateFormatter()
            format.dateFormat = "yyyy-MM-dd HH:mm:ss"
            format.timeZone   = TimeZone(identifier: "Asia/Tokyo")
            postTime = format.string(from: preDate)
        }
        
        DatabaseManager.shared.fetchNewPostInfo(whichTable: whichTable, nowPostCount: posts_all.count, latestPostTime: postTime) { [weak self](result) -> (Void) in
            switch result {
            case .success(let postArray):
                guard let strongSelf = self else {
                    return
                }
                if postArray.count < 50 { //ここの値を変えるならdatabaseの方も変える
                    let newPost: [Post] = postArray + strongSelf.posts_all
                    strongSelf.posts_all = newPost
                }
                else {
                    strongSelf.posts_all = postArray
                }
                strongSelf.tableViewAll.reloadData()
            case .failure(let error):
                print("failed to fetch post: \(error)")
            }
        }
    }
    
    private func fetchFacultyNewPosts() {
        // 初めての投稿はposts[0].postTimeがない
        var postTime = ""
        if posts_faculty.count >= 1 {
            postTime = posts_faculty[0].postTime
        }
        else {
            let date = Date()
            let preDate = Calendar.current.date(byAdding: .day, value: -1, to: date)!
            let format = DateFormatter()
            format.dateFormat = "yyyy-MM-dd HH:mm:ss"
            format.timeZone   = TimeZone(identifier: "Asia/Tokyo")
            postTime = format.string(from: preDate)
        }
        
        DatabaseManager.shared.fetchNewFacultyPostInfo(whichTable: whichTable, nowPostCount: posts_faculty.count, latestPostTime: postTime) { [weak self](result) -> (Void) in
            switch result {
            case .success(let postArray):
                guard let strongSelf = self else {
                    return
                }
                if postArray.count < 50 { //ここの値を変えるならdatabaseの方も変える
                    let newPost: [Post] = postArray + strongSelf.posts_faculty
                    strongSelf.posts_faculty = newPost
                }
                else {
                    strongSelf.posts_faculty = postArray
                }
                strongSelf.tableViewFaculty.reloadData()
            case .failure(let error):
                print("failed to fetch post: \(error)")
            }
        }
    }
    
    
    func updateAllDataBottom () {
        DispatchQueue.global().async {
            //*** ここでデータを更新する処理をする ***
            self.fetchAllOldPosts()
            DispatchQueue.main.async {
                self.tableViewAll.reloadData()
                self.semaphore.signal() // 処理が終わった信号を送る
            }
        }
    }
    
    
    func updateFacultyDataBottom () {
        DispatchQueue.global().async {
            //*** ここでデータを更新する処理をする ***
            self.fetchFacultyOldPosts()
            DispatchQueue.main.async {
                self.tableViewFaculty.reloadData()
                self.semaphore.signal() // 処理が終わった信号を送る
            }
        }
    }
    
    
    private func fetchAllOldPosts() {
        // tableViewを上に引っ張る処理
        let nowFetchDate = Date()
        let dayformat = DateFormatter()
        dayformat.dateFormat = "MM"
        dayformat.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        let oldFetchDayString = dayformat.string(from: nowFetchDate)
        
        DatabaseManager.shared.fetchPostInfo(whichTable: whichTable, nowPostCount: posts_all.count) { [weak self](result) -> (Void) in
            switch result {
            case .success(let postArray):
                guard let fetchDate = UserDefaults.standard.value(forKey: "fetch_date_all") as? Date else {
                    return
                }
                let fetchDayString = dayformat.string(from: fetchDate)
                
                if oldFetchDayString == fetchDayString {
                    // 今のpostの数を合わせてfetchしている
                    self?.posts_all = postArray
                    self?.tableViewAll.reloadData()
                    self?.reloading = true
                }
                else {
                    self?.posts_all.append(contentsOf: postArray)
                    self?.tableViewAll.reloadData()
                    self?.reloading = true
                }
            case .failure(let error):
                self?.alertUserError(alertMessage: "通信エラーが起きました。アプリを落としてもう一度開いてください。")
                print("failed to fetch post: \(error)")
            }
        }
    }
    
    
    private func fetchFacultyOldPosts() {
        // tableViewを上に引っ張る処理
        let nowFetchDate = Date()
        let dayformat = DateFormatter()
        dayformat.dateFormat = "MM"
        dayformat.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        let oldFetchDayString = dayformat.string(from: nowFetchDate)
        
        DatabaseManager.shared.fetchFacultyPostInfo(whichTable: whichTable, nowPostCount: posts_faculty.count) { [weak self](result) -> (Void) in
            switch result {
            case .success(let postArray):
                guard let fetchDate = UserDefaults.standard.value(forKey: "fetch_date_faculty") as? Date else {
                    return
                }
                let fetchDayString = dayformat.string(from: fetchDate)

                if oldFetchDayString == fetchDayString {
                    self?.posts_faculty = postArray
                    self?.tableViewFaculty.reloadData()
                    self?.reloading = true
                }
                else {
                    self?.posts_faculty.append(contentsOf: postArray)
                    self?.tableViewFaculty.reloadData()
                    self?.reloading = true
                }
            case .failure(let error):
                self?.alertUserError(alertMessage: "通信エラーが起きました。アプリを落としてもう一度開いてください。")
                print("failed to fetch post: \(error)")
            }
        }
    }
    
    
    
    @objc private func myProfilePicture() {
        let profileVC = FriendProfileViewController(partnerEmail: safeMyEmail)
        
        profileVC.completionGoodFromProfile = { [weak self]changeGoodId in
            
            guard let strongSelf = self,
                  changeGoodId != "" else {
                return
            }
            strongSelf.changeGoodForProfile = changeGoodId
            
            if strongSelf.changeGoodForProfile != "" {
                if strongSelf.posts_all.count != 0 { strongSelf.changeGoodAll(changeID: "") }
                if strongSelf.posts_faculty.count != 0 { strongSelf.changeGoodFac(changeID: "") }
            }
            
            strongSelf.changeGoodForProfile = ""
        }
        profileVC.completionChangePicture = { [weak self] chnageMyIcon in
            self?.setupNavigationbar()
        }
        let nav = UINavigationController(rootViewController: profileVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    
    private func changeGoodAll(changeID: String) {
        guard posts_all.count != 0 else { return }
        var targetId = ""
        if changeID == "" { targetId = changeGoodForProfile }
        else { targetId = changeID }
        
        var i = 0
        for cell in posts_all {
            if cell.postId == targetId {
                var j = 0
                for goodList in posts_all[i].goodList {
                    if goodList == safeMyEmail {
                        posts_all[i].good -= 1
                        posts_all[i].goodList.remove(at: j)
                        if whichTable == 0 {
                            tableViewAll.reloadRows(at: [IndexPath(row: j, section: 0)], with: .none)
                        }
                        return
                    }
                    j += 1
                }
                posts_all[i].good += 1
                posts_all[i].goodList.append(safeMyEmail)
                if whichTable == 0 {
                    tableViewAll.reloadRows(at: [IndexPath(row: i, section: 0)], with: .none)
                }
                return
            }
            i += 1
        }
    }
    
    
    private func changeGoodFac(changeID: String) {
        guard posts_faculty.count != 0 else { return }
        var targetId = ""
        if changeID == "" { targetId = changeGoodForProfile }
        else { targetId = changeID }
        
        var i = 0
        for cell in posts_faculty {
            if cell.postId == targetId {
                var j = 0
                for goodList in posts_faculty[i].goodList {
                    if goodList == safeMyEmail {
                        posts_faculty[i].good -= 1
                        posts_faculty[i].goodList.remove(at: j)
                        if whichTable == 1 {
                            tableViewFaculty.reloadRows(at: [IndexPath(row: j, section: 0)], with: .none)
                        }
                        return
                    }
                    j += 1
                }
                posts_faculty[i].good += 1
                posts_faculty[i].goodList.append(safeMyEmail)
                if whichTable == 1 {
                    tableViewFaculty.reloadRows(at: [IndexPath(row: i, section: 0)], with: .none)
                }
                return
            }
            i += 1
        }
    }
        
    
  
    
    public func alertUserError(alertMessage: String) {
        let alert = UIAlertController(title: "エラー",
                                      message: alertMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true)
    }
    
    func alertMessage(alertMessage: String) {
        let alert = UIAlertController(title: "",
                                      message: alertMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true)
    }
    
    
    //login後の処理
    public func afterLogin() {
        setupNavigationbar()
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        tableViewAll.reloadData()
        
    }
    
    
    
    
}













extension CommunityViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if whichTable == 0 {
            return posts_all.count
        }
        else {
            return posts_faculty.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if whichTable == 0 {
            let model = posts_all[indexPath.row]
            
            let cell = tableViewAll.dequeueReusableCell(withIdentifier: "BullutinBoard2TableViewCell", for: indexPath) as! BullutinBoard2TableViewCell
            cell.selectionStyle = .none
            
            if model.isRemessage != nil { cell.isRepeat = true; cell.isTask = false }
            else { cell.isRepeat = false; cell.isTask = false }
            cell.configure(model: model)
            
            
            cell.replayButton.tag = indexPath.row
            cell.replayButton.addTarget(self, action: #selector(tapReplay), for: .touchUpInside)
            cell.repeatButton.tag = indexPath.row
            cell.repeatButton.addTarget(self, action: #selector(tappedRepeat), for: .touchUpInside)
            cell.goodButton.tag = indexPath.row
            cell.goodButton.tintColor = .systemGray
            cell.goodButton.addTarget(self, action: #selector(tappedGood), for: .touchUpInside)
            cell.goodNumberButton.tag = indexPath.row
            cell.goodNumberButton.addTarget(self, action: #selector(tappedGoodNumber), for: .touchUpInside)
            cell.repeatNumberButton.addTarget(self, action: #selector(tappedRepeatNumber), for: .touchUpInside)
            cell.otherMenuButton.tag = indexPath.row
            cell.otherMenuButton.addTarget(self, action: #selector(tappedOther), for: .touchUpInside)
            cell.userImageButton.tag = indexPath.row
            cell.userImageButton.addTarget(self, action: #selector(didTapImageButton), for: .touchUpInside)
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
                    }else {
                        cell.imageContainerMerginRight.constant = 200
                    }
                }
            }
            
            
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
        
        else {
            let model = posts_faculty[indexPath.row]
            let cell = tableViewFaculty.dequeueReusableCell(withIdentifier: "BullutinBoard2TableViewCell", for: indexPath) as! BullutinBoard2TableViewCell
            cell.selectionStyle = .none
            
            if model.isRemessage != nil { cell.isRepeat = true }
            else {  cell.isRepeat = false }
            if model.shareTask != nil { cell.isTask = true }
            else { cell.isTask = false }
            
            cell.configure(model: model)
            
            cell.replayButton.tag = indexPath.row
            cell.replayButton.addTarget(self, action: #selector(tapReplay), for: .touchUpInside)
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
            cell.userImageButton.tag = indexPath.row
            cell.userImageButton.addTarget(self, action: #selector(didTapImageButton), for: .touchUpInside)
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
                    }else {
                        cell.imageContainerMerginRight.constant = 200
                    }
                }
            }
            
            
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
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if whichTable == 0 {
            return tableViewAll.estimatedRowHeight
        }
        else {
            return tableViewFaculty.estimatedRowHeight
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if whichTable == 0 {
            let model = posts_all[indexPath.row]
            let vc = UserPost(model: model, whichTable: whichTable)
            vc.indexPathForChangeGood = indexPath.row
            vc.fromCommunityVC = true
            navigationController?.pushViewController(vc, animated: true)
        }
        else {
            let model = posts_faculty[indexPath.row]
            let vc = UserPost(model: model, whichTable: whichTable)
            vc.indexPathForChangeGood = indexPath.row
            vc.fromCommunityVC = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    
   
    
    @objc func tapReplay(_ sender: UIButton) {
        
        guard let _ = UserDefaults.standard.value(forKey: "name") as? String else
        { return }
        
        if whichTable == 0 {
            let indexpath = sender.tag
            let storyboard: UIStoryboard = UIStoryboard(name: "Replay", bundle: nil)
            let replayVC = storyboard.instantiateViewController(withIdentifier: "segueReplay") as! ReplayViewController
            replayVC.replayParentPost = posts_all[indexpath]
            replayVC.isReplayRepeat = 0
            replayVC.whichTable = whichTable
            
            replayVC.replayCompletion = { [weak self]success in
                if success == true {
                    self?.posts_all[indexpath].comment += 1
                    self?.tableViewAll.reloadRows(at: [IndexPath(row: indexpath, section: 0)], with: .none)
                }
                else {
                    self?.alertMessage(alertMessage: "ネットワーク環境を確認してください")
                }
            }
            
            let nav = UINavigationController(rootViewController: replayVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        }
        else {
            let indexpath = sender.tag
            let storyboard: UIStoryboard = UIStoryboard(name: "Replay", bundle: nil)
            let replayVC = storyboard.instantiateViewController(withIdentifier: "segueReplay") as! ReplayViewController
            replayVC.replayParentPost = posts_faculty[indexpath]
            replayVC.isReplayRepeat = 0
            replayVC.whichTable = whichTable
            
            replayVC.replayCompletion = { [weak self]success in
                if success == true {
                    self?.posts_faculty[indexpath].comment += 1
                    self?.tableViewFaculty.reloadRows(at: [IndexPath(row: indexpath, section: 0)], with: .none)
                }
                else {
                    self?.alertMessage(alertMessage: "ネットワーク環境を確認してください")
                }
            }
            
            let nav = UINavigationController(rootViewController: replayVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        }
        
    }

    @objc private func tappedRepeat(_ sender: UIButton) {
        
        guard let _ = UserDefaults.standard.value(forKey: "name") as? String else
        { return }
        
        if whichTable == 0 {
            let indexpath = sender.tag
            let storyboard: UIStoryboard = UIStoryboard(name: "Replay", bundle: nil)
            let replayVC = storyboard.instantiateViewController(withIdentifier: "segueReplay") as! ReplayViewController
            replayVC.repeatParentPost = posts_all[indexpath]
            replayVC.isRepeatMessage = true
            replayVC.isReplayRepeat = 1
            replayVC.whichTable = whichTable
            
            replayVC.replayCompletion = { [weak self]success in
                if success == true {
                    self?.posts_all[indexpath].remessage += 1
                    self?.tableViewAll.reloadRows(at: [IndexPath(row: indexpath, section: 0)], with: .none)
                }
                else {
                    self?.alertMessage(alertMessage: "ネットワーク環境を確認してください")
                }
            }
            
            let nav = UINavigationController(rootViewController: replayVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        }
        else {
            let indexpath = sender.tag
            let storyboard: UIStoryboard = UIStoryboard(name: "Replay", bundle: nil)
            let replayVC = storyboard.instantiateViewController(withIdentifier: "segueReplay") as! ReplayViewController
            replayVC.repeatParentPost = posts_faculty[indexpath]
            replayVC.isRepeatMessage = true
            replayVC.isReplayRepeat = 1
            replayVC.whichTable = whichTable
            
            replayVC.replayCompletion = { [weak self]success in
                if success == true {
                    self?.posts_faculty[indexpath].remessage += 1
                    self?.tableViewFaculty.reloadRows(at: [IndexPath(row: indexpath, section: 0)], with: .none)
                }
                else {
                    self?.alertMessage(alertMessage: "ネットワーク環境を確認してください")
                }
            }
            
            let nav = UINavigationController(rootViewController: replayVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        }
        
    }
    
    @objc private func tappedGood(_ sender: UIButton) {
        
        guard let _ = UserDefaults.standard.value(forKey: "name") as? String else
        { return }
        let indexpath = sender.tag
        
        if whichTable == 0 {
            // targetPostのwhichTableを取得する
            let before5 = posts_all[indexpath].postId.suffix(5)
            let doubleTable = before5.prefix(1)
            if doubleTable == "4" { changeGoodFac(changeID: posts_all[indexpath].postId) }

            changePostAllGood(indexpath: indexpath)
            
        }
        else {
            // targetPostのwhichTableを取得する
            let before5 = posts_faculty[indexpath].postId.suffix(5)
            let doubleTable = before5.prefix(1)
            if doubleTable == "4" { changeGoodAll(changeID: posts_faculty[indexpath].postId) }
            changePostFacGood(indexpath: indexpath)
            
        }
        
    }
    
    private func changePostAllGood(indexpath: Int) {
        let indexPath = IndexPath(row: indexpath, section: 0)
        var i = 0
        for goodEmail in posts_all[indexpath].goodList {
            if safeMyEmail == goodEmail {
                posts_all[indexpath].goodList.remove(at: i)
                posts_all[indexpath].good -= 1
                tableViewAll.reloadRows(at: [indexPath], with: .fade)
                DatabaseManager.shared.insertMyGoodList(targetPost: posts_all[indexpath], whichTable: whichTable, whichVC: 4, uni: nil, year: nil, fac: nil) { (success) in
                    if success == true {
                        print("success insert goodList")
                    }
                }
                return
            }
            i += 1
        }
        
        posts_all[indexpath].good += 1
        posts_all[indexpath].goodList.append(safeMyEmail)
        tableViewAll.reloadRows(at: [indexPath], with: .fade)
        
        // goodListに入れる
        DatabaseManager.shared.insertMyGoodList(targetPost: posts_all[indexpath], whichTable: whichTable, whichVC: 0, uni: nil, year: nil, fac: nil) { (success) in
            if success == true {
                print("success insert goodList")
            }
        }
    }
    
    
    private func changePostFacGood(indexpath: Int) {
        let indexPath = IndexPath(row: indexpath, section: 0)
        var i = 0
        for goodEmail in posts_faculty[indexpath].goodList {
            if safeMyEmail == goodEmail {
                posts_faculty[indexpath].goodList.remove(at: i)
                posts_faculty[indexpath].good -= 1
                tableViewFaculty.reloadRows(at: [indexPath], with: .fade)
                DatabaseManager.shared.insertMyGoodList(targetPost: posts_faculty[indexpath], whichTable: whichTable, whichVC: 4, uni: nil, year: nil, fac: nil) { (success) in
                    if success == true {
                        print("success insert goodList")
                    }
                }
                return
            }
            i += 1
        }
        
        posts_faculty[indexpath].good += 1
        posts_faculty[indexpath].goodList.append(safeMyEmail)
        tableViewFaculty.reloadRows(at: [indexPath], with: .fade)
        
        // goodListに入れる
        DatabaseManager.shared.insertMyGoodList(targetPost: posts_faculty[indexpath], whichTable: whichTable, whichVC: 0, uni: nil, year: nil, fac: nil) { (success) in
            if success == true {
                print("success insert goodList")
            }
        }
    }
    
    @objc private func tappedGoodNumber(_ sender: UIButton) {
        if whichTable == 0 {
            let indexpath = sender.tag
            let targetPost = posts_all[indexpath]
            let goodListVC = GoodListViewController(postId: targetPost.postId, whichTable: whichTable)
            goodListVC.targetPost = targetPost
            let nav = UINavigationController(rootViewController: goodListVC)
            present(nav, animated: true)
        }
        else {
            let indexpath = sender.tag
            let targetPost = posts_faculty[indexpath]
            let goodListVC = GoodListViewController(postId: targetPost.postId, whichTable: whichTable)
            goodListVC.targetPost = targetPost
            let nav = UINavigationController(rootViewController: goodListVC)
            present(nav, animated: true)
        }

    }
    
    @objc private func tappedRepeatNumber(_ sender: UIButton) {
        if whichTable == 0 {
            let indexpath = sender.tag
            let targetPost = posts_all[indexpath]
            let goodListVC = GoodListViewController(postId: targetPost.postId, whichTable: whichTable)
            goodListVC.targetPost = targetPost
            goodListVC.isReaptMember = true
            let nav = UINavigationController(rootViewController: goodListVC)
            present(nav, animated: true)
        }
        else {
            let indexpath = sender.tag
            let targetPost = posts_faculty[indexpath]
            let goodListVC = GoodListViewController(postId: targetPost.postId, whichTable: whichTable)
            goodListVC.targetPost = targetPost
            goodListVC.isReaptMember = true
            let nav = UINavigationController(rootViewController: goodListVC)
            present(nav, animated: true)
        }
    }
    
    @objc private func tappedOther(_ sender: UIButton) {
        
        guard let _ = UserDefaults.standard.value(forKey: "name") as? String else
        { return }
        if whichTable == 0 {
            let indexpath = sender.tag
            let alertPost = posts_all[indexpath]
            otherMenuActionSheet(alertPost: alertPost, indexpath: indexpath)
        }
        else {
            let indexpath = sender.tag
            let alertPost = posts_faculty[indexpath]
            otherMenuActionSheet(alertPost: alertPost, indexpath: indexpath)
        }
    }

    @objc private func didTapImageButton(_ sender: UIButton) {
        guard UserDefaults.standard.object(forKey: "name") != nil else {
            alertMessage(alertMessage: "プロフィールを完成させよう")
            return
        }
        if whichTable == 0 {
            let indexpath = sender.tag
            let friendEmail = posts_all[indexpath].postEmail
            let friendVC = FriendProfileViewController(partnerEmail: friendEmail)
            
            friendVC.completionGoodFromProfile = { [weak self]changeGoodId in
                
                guard let strongSelf = self,
                      changeGoodId != "" else {
                    return
                }
                strongSelf.changeGoodForProfile = changeGoodId
                
                if strongSelf.changeGoodForProfile != "" {
                    if strongSelf.posts_all.count != 0 { strongSelf.changeGoodAll(changeID: "") }
                    if strongSelf.posts_faculty.count != 0 { strongSelf.changeGoodFac(changeID: "") }
                }
                
                strongSelf.changeGoodForProfile = ""
            }
            
            let nav = UINavigationController(rootViewController: friendVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        }
        else {
            let indexpath = sender.tag
            let friendEmail = posts_faculty[indexpath].postEmail
            let friendVC = FriendProfileViewController(partnerEmail: friendEmail)
            
            friendVC.completionGoodFromProfile = { [weak self]changeGoodId in
                
                guard let strongSelf = self,
                      changeGoodId != "" else {
                    return
                }
                strongSelf.changeGoodForProfile = changeGoodId
                
                if strongSelf.changeGoodForProfile != "" {
                    if strongSelf.posts_all.count != 0 { strongSelf.changeGoodAll(changeID: "") }
                    if strongSelf.posts_faculty.count != 0 { strongSelf.changeGoodFac(changeID: "") }
                }
                
                strongSelf.changeGoodForProfile = ""
            }
            let nav = UINavigationController(rootViewController: friendVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        }
    }
    
    
    
    @objc private func tapRepeatTableView(_ sender: UIButton) {
        if whichTable == 0 {
            let indexpath = sender.tag
            if let target = posts_all[indexpath].isRemessage {
                if target.isRemessage == nil {
                    // isRemessageがないバージョン
                    let remessagePost = Post(postId: target.parentPostId, postMessage: target.postMessage, postEmail: target.postEmail, postName: target.postName, postTime: target.postTime, good: target.good, goodList: target.goodList, remessage: target.remessage, remessagePostArray: target.remessagePostArray, isRemessage: nil, comment: target.comment, isComment: target.isComment, photoUrl: target.photoUrl, shareTask: target.shareTask)
                    let userPost = UserPost(model: remessagePost, whichTable: whichTable)
                    userPost.indexPathForChangeGood = indexpath
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
                                let userPost = UserPost(model: remessagePost, whichTable: self?.whichTable ?? 0)
                                userPost.indexPathForChangeGood = indexpath
                                self?.spinner.dismiss()
                                self?.navigationController?.pushViewController(userPost, animated: true)
                            }
                        case .failure(_):
                            self?.spinner.dismiss()
                            self?.alertMessage(alertMessage: "このメッセージは削除されました")
                            print("failed to fetch in tapRepeatTableView(fetchPostId)")
                        }
                    }
                    print("aaaaaaa")
                }
            }
        }
        
        else {
            let indexpath = sender.tag
            if let target = posts_faculty[indexpath].isRemessage {
                if target.isRemessage == nil {
                    // isRemessageがないバージョン
                    let remessagePost = Post(postId: target.parentPostId, postMessage: target.postMessage, postEmail: target.postEmail, postName: target.postName, postTime: target.postTime, good: target.good, goodList: target.goodList, remessage: target.remessage, remessagePostArray: target.remessagePostArray, isRemessage: nil, comment: target.comment, isComment: target.isComment, photoUrl: target.photoUrl, shareTask: target.shareTask)
                    let userPost = UserPost(model: remessagePost, whichTable: whichTable)
                    userPost.indexPathForChangeGood = indexpath
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
                                let userPost = UserPost(model: remessagePost, whichTable: self?.whichTable ?? 0)
                                userPost.indexPathForChangeGood = indexpath
                                self?.spinner.dismiss()
                                self?.navigationController?.pushViewController(userPost, animated: true)
                            }
                        case .failure(_):
                            self?.spinner.dismiss()
                            self?.alertMessage(alertMessage: "このメッセージは削除されました")
                            print("failed to fetch in tapRepeatTableView(fetchPostId)")
                        }
                    }
                }

            }
            
            
            
            // taskをタップ
            if let task = posts_faculty[indexpath].shareTask {
                let storyboard: UIStoryboard = UIStoryboard(name: "ShareTodo", bundle: nil)
                let shareTodoViewController = storyboard.instantiateViewController(withIdentifier: "ShareTodoViewController") as! ShareTodoViewController
                shareTodoViewController.task = Task(taskId: task.taskId, taskName: task.taskName, notifyTime: "", timeSchedule: task.timeSchedule, taskLimit: task.taskLimit, createDate: Date(), isFinish: false, shareTask: ShareTask(documentPath: task.documentPath, memberCount: task.memberCount, makedEmail: task.makedEmail, doneMember: task.doneMember, gettingMember: task.gettingMember, wantToTalkMember: task.wantToTalkMember))
                let nav = UINavigationController(rootViewController: shareTodoViewController)
                nav.modalPresentationStyle = .fullScreen
                present(nav, animated: true, completion: nil)
            }
        
        }
        
        
    }
    
    
    
    private func otherMenuActionSheet(alertPost: Post, indexpath: Int) {
        let actionSheet = UIAlertController(title: "",
                                            message: "",
                                            preferredStyle: .actionSheet)
        if alertPost.postEmail == safeMyEmail {
            actionSheet.addAction(UIAlertAction(title: "この投稿を削除する", style: .default, handler: { [weak self] _ in
                DatabaseManager.shared.removePost(postId: alertPost.postId, postEmail: alertPost.postEmail, whichTable: self?.whichTable ?? 0, isParentPath: nil) { (succuss) in
                    if succuss == true {
                        guard let strongSelf = self else {
                            return
                        }
                        strongSelf.alertMessage(alertMessage: "この投稿を削除しました")
                        if strongSelf.whichTable == 0 { strongSelf.posts_all.remove(at: indexpath); self?.tableViewAll.reloadData() }
                        else if strongSelf.whichTable == 1 { strongSelf.posts_faculty.remove(at: indexpath); self?.tableViewFaculty.reloadData() }
                        
                    }
                    else {
                        self?.alertUserError(alertMessage: "ネットワークを確認してください")
                    }
                }
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: "通報する",
                                            style: .default,
                                            handler: { [weak self] _ in
                                                
            DatabaseManager.shared.alertPost(postId: alertPost.postId, whichTable: self?.whichTable ?? 0) { (success) in
                if success == true {
                    self?.alertMessage(alertMessage: "この投稿を通報しました")
                }
                else {
                    self?.alertUserError(alertMessage: "ネットワークを確認してください")
                }
            }
        }))
        
        if alertPost.postEmail != safeMyEmail {
            actionSheet.addAction(UIAlertAction(title: "ブロックする",
                                                style: .default,
                                                handler: { [weak self] _ in
                self?.blockYou(friendEmail: alertPost.postEmail, indexpath: indexpath)
            }))
        }
        
        
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
    
    private func blockYou(friendEmail: String, indexpath: Int) {
        
        if let blockedList = UserDefaults.standard.value(forKey: "blocked") as? [String] {
            for cell in blockedList {
                if cell == friendEmail {
                    return
                }
            }
            
        }
        
        // ブロック
        if var blockedList = UserDefaults.standard.value(forKey: "blocked") as? [String] {
            blockedList.append(friendEmail)
            UserDefaults.standard.setValue(blockedList, forKey: "blocked")
        }
        else {
            let blockedList: [String] = [friendEmail]
            UserDefaults.standard.setValue(blockedList, forKey: "blocked")
        }
        
        if safeMyEmail == friendEmail {
            DatabaseManager.shared.FollowYou(myEmail: safeMyEmail, friendEmail: friendEmail, isUnFollow: true) { (success) -> (Void) in
                print("success")
            }
        }
        
        DatabaseManager.shared.blockedYou(myEmail: safeMyEmail, friendEmail: friendEmail, cancelBlock: false) { [weak self](success) -> (Void) in
            if success == true {
                guard let strongSelf = self else {
                    return
                }
                strongSelf.alertMessage(alertMessage: "この投稿を削除しました")
                if strongSelf.whichTable == 0 {
                    strongSelf.posts_all.remove(at: indexpath)
                    strongSelf.tableViewAll.reloadData()
                }
                else {
                    strongSelf.posts_faculty.remove(at: indexpath)
                    strongSelf.tableViewFaculty.reloadData()
                }
                self?.alertMessage(alertMessage: "ブロックしました")
            }
        }
    }
    
    @objc private func tapImage1(gestureRecognizer: UITapGestureRecognizer, index: Int) {
        
        if whichTable == 0 {
            let tappedLocation = gestureRecognizer.location(in: tableViewAll)
            let tappedIndexPath = tableViewAll.indexPathForRow(at: tappedLocation)
            guard let tappedRow = tappedIndexPath?.row else { return }
            let imageSlideshow = ImageSlideshow()
            
            var sdWebImageSource = [SDWebImageSource]()
            if posts_all[tappedRow].photoUrl?.count == 1 {
                sdWebImageSource = [SDWebImageSource(urlString: (posts_all[tappedRow].photoUrl?[0]) ?? "")!]
            }
            if posts_all[tappedRow].photoUrl?.count == 2 {
                sdWebImageSource = [SDWebImageSource(urlString: (posts_all[tappedRow].photoUrl?[0]) ?? "")!, SDWebImageSource(urlString: (posts_all[tappedRow].photoUrl?[1]) ?? "")!]
                if index == 1 { sdWebImageSource.swapAt(0, 1) }
            }
            if posts_all[tappedRow].photoUrl?.count == 3 {
                sdWebImageSource = [SDWebImageSource(urlString: (posts_all[tappedRow].photoUrl?[0]) ?? "")!, SDWebImageSource(urlString: (posts_all[tappedRow].photoUrl?[1]) ?? "")!, SDWebImageSource(urlString: (posts_all[tappedRow].photoUrl?[2]) ?? "")!]
                if index == 1 { sdWebImageSource.swapAt(0, 1); sdWebImageSource.swapAt(1, 2) }
                if index == 2 { sdWebImageSource.swapAt(0, 1); sdWebImageSource.swapAt(0, 2) }
            }
            if posts_all[tappedRow].photoUrl?.count == 4 {
                sdWebImageSource = [SDWebImageSource(urlString: (posts_all[tappedRow].photoUrl?[0]) ?? "")!, SDWebImageSource(urlString: (posts_all[tappedRow].photoUrl?[1]) ?? "")!, SDWebImageSource(urlString: (posts_all[tappedRow].photoUrl?[2]) ?? "")!, SDWebImageSource(urlString: (posts_all[tappedRow].photoUrl?[3]) ?? "")!]
                if index == 1 { sdWebImageSource.swapAt(0, 1); sdWebImageSource.swapAt(1, 2); sdWebImageSource.swapAt(2, 3) }
                if index == 2 { sdWebImageSource.swapAt(0, 2); sdWebImageSource.swapAt(1, 3) }
                if index == 3 { sdWebImageSource.swapAt(2, 3); sdWebImageSource.swapAt(1, 2); sdWebImageSource.swapAt(0, 1) }
            }
            imageSlideshow.setImageInputs(sdWebImageSource)
            //ImageSlideshow.
            let fullScreenController = imageSlideshow.presentFullScreenController(from: self)
            fullScreenController.slideshow.activityIndicator = nil
            fullScreenController.slideshow.pageIndicator = nil
//            fullScreenController.slideshow.activityIndicator = DefaultActivityIndicator(style: UIActivityIndicatorView.Style.medium, color: nil)
        }
        if whichTable == 1 {
            let tappedLocation = gestureRecognizer.location(in: tableViewFaculty)
            let tappedIndexPath = tableViewFaculty.indexPathForRow(at: tappedLocation)
            guard let tappedRow = tappedIndexPath?.row else { return }
            let imageSlideshow = ImageSlideshow()
            
            var sdWebImageSource = [SDWebImageSource]()
            if posts_faculty[tappedRow].photoUrl?.count == 1 {
                sdWebImageSource = [SDWebImageSource(urlString: (posts_faculty[tappedRow].photoUrl?[0]) ?? "")!]
            }
            if posts_faculty[tappedRow].photoUrl?.count == 2 {
                sdWebImageSource = [SDWebImageSource(urlString: (posts_faculty[tappedRow].photoUrl?[0]) ?? "")!, SDWebImageSource(urlString: (posts_faculty[tappedRow].photoUrl?[1]) ?? "")!]
                if index == 1 { sdWebImageSource.swapAt(0, 1) }
            }
            if posts_faculty[tappedRow].photoUrl?.count == 3 {
                sdWebImageSource = [SDWebImageSource(urlString: (posts_faculty[tappedRow].photoUrl?[0]) ?? "")!, SDWebImageSource(urlString: (posts_faculty[tappedRow].photoUrl?[1]) ?? "")!, SDWebImageSource(urlString: (posts_faculty[tappedRow].photoUrl?[2]) ?? "")!]
                if index == 1 { sdWebImageSource.swapAt(0, 1); sdWebImageSource.swapAt(1, 2) }
                if index == 2 { sdWebImageSource.swapAt(0, 1); sdWebImageSource.swapAt(0, 2) }
            }
            if posts_faculty[tappedRow].photoUrl?.count == 4 {
                sdWebImageSource = [SDWebImageSource(urlString: (posts_faculty[tappedRow].photoUrl?[0]) ?? "")!, SDWebImageSource(urlString: (posts_faculty[tappedRow].photoUrl?[1]) ?? "")!, SDWebImageSource(urlString: (posts_faculty[tappedRow].photoUrl?[2]) ?? "")!, SDWebImageSource(urlString: (posts_faculty[tappedRow].photoUrl?[3]) ?? "")!]
                if index == 1 { sdWebImageSource.swapAt(0, 1); sdWebImageSource.swapAt(1, 2); sdWebImageSource.swapAt(2, 3) }
                if index == 2 { sdWebImageSource.swapAt(0, 2); sdWebImageSource.swapAt(1, 3) }
                if index == 3 { sdWebImageSource.swapAt(2, 3); sdWebImageSource.swapAt(1, 2); sdWebImageSource.swapAt(0, 1) }
            }
            imageSlideshow.setImageInputs(sdWebImageSource)
            
            let fullScreenController = imageSlideshow.presentFullScreenController(from: self)
            fullScreenController.slideshow.activityIndicator = nil
            fullScreenController.slideshow.pageIndicator = nil
//            fullScreenController.slideshow.activityIndicator = DefaultActivityIndicator(style: UIActivityIndicatorView.Style.medium, color: nil)
        }
        
        
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
        let height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset + 80
        if distanceFromBottom < height {
            if whichTable == 0 {
                if reloading == true { // デリゲートは何回も呼ばれてしまうので、リロード中はfalseにしておく
                    updateAllDataBottom()
                    semaphore.wait()
                    semaphore.signal()
                    reloading = false
                }
            }
            else {
                if reloading == true { // デリゲートは何回も呼ばれてしまうので、リロード中はfalseにしておく
                    updateFacultyDataBottom()
                    semaphore.wait()
                    semaphore.signal()
                    reloading = false
                }
            }
            
        }
    }

}

