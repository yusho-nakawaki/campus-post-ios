//
//  ViewController.swift
//  BulletinBoard
//
//  on 2020/11/25.
//

import UIKit
import JGProgressHUD
import SDWebImage
import ImageSlideshow


class UserPost: UIViewController, UITextViewDelegate {

    
    private var posts = [Post]()
    private var parentPost: Post
    private var replay: Post?
    private var whichTable: Int // 0が全ての人, (1が大学)、1が学部
    private let spinner = JGProgressHUD()
    private var safeMyEmail = ""
    
    public var isCommentOfComment: String?
    public var isCommentCell = false
    public var fromCommunityVC = false // CommunityVCのみいいねをしたとき処理が走る
    public var indexPathForChangeGood = 0
    
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(UINib(nibName: "BullutinBoard2TableViewCell", bundle: nil), forCellReuseIdentifier: "BullutinBoard2TableViewCell")
        return table
    }()
    
    private let tableHeaderContainer: UIScrollView = {
        let view = UIScrollView()
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray5.cgColor
        return view
    }()
    private var userImage: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.backgroundColor = .secondarySystemBackground
        image.layer.masksToBounds = true
        image.tintColor = .gray
        return image
    }()
    private var userName: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        return label
    }()
    private var timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    private let textView: UITextView = {
        let text = UITextView()
        text.font = .systemFont(ofSize: 17)
        text.isEditable = false
        text.isSelectable = false
        return text
    }()
    
    private let imageContainer: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .fill
        view.distribution = .fillEqually
        view.spacing = 2
        view.contentMode = .scaleToFill
        view.layer.cornerRadius = 5
        view.isHidden = true
        return view
    }()
    
    private var photo1: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.isHidden = true
        return image
    }()
    private var photo2: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.isHidden = true
        return image
    }()
    private var photo3: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.isHidden = true
        return image
    }()
    private var photo4: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.isHidden = true
        return image
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        textView.delegate = self
        
        posts.append(parentPost)
        view.addSubview(tableView)
        tableHeaderContainer.addSubview(userImage)
        tableHeaderContainer.addSubview(userName)
        tableHeaderContainer.addSubview(timeLabel)
        tableHeaderContainer.addSubview(textView)
        tableHeaderContainer.addSubview(imageContainer)
        imageContainer.addArrangedSubview(photo1)
        imageContainer.addArrangedSubview(photo2)
        imageContainer.addArrangedSubview(photo3)
        imageContainer.addArrangedSubview(photo4)
        
        if let myEmail = UserDefaults.standard.value(forKey: "email") as? String {
            let email = DatabaseManager.safeEmail(emailAddress: myEmail)
            safeMyEmail = email
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: " ← ",
                                                           style: .done,
                                                           target: self,
                                                           action: #selector(popToVC))
        
        navigationController?.navigationBar.tintColor = UIColor(named: "gentle")
        navigationController?.navigationBar.barTintColor = UIColor(named: "appBackground")
        
        // スワイプでtableViewを変える
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(popToVC))
        rightSwipe.direction = .right
        tableView.addGestureRecognizer(rightSwipe)
    }
    
    init(model: Post, whichTable: Int) {
        self.parentPost = model
        self.whichTable = whichTable //0が全ての人, 1が大学、2が学部

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds
        
        // indexpath == 0の投稿がコメントしているなら、tableViewHeaderを用意する
        if let grandParentPostInfo = parentPost.isComment {
            guard grandParentPostInfo != "nil" else {
                return
            }
            // tableHeader用
            tableHeaderContainer.frame = CGRect(x: 0, y: 0, width: view.width, height: 130)
            userImage.frame = CGRect(x: 10, y: 10, width: 52, height: 52)
            userImage.layer.cornerRadius = 26
            userName.frame = CGRect(x: 73, y: 27, width: 180, height: 25)
            timeLabel.frame = CGRect(x: 81, y: 29, width: view.width - userName.width - 10, height: 25)
            textView.frame = CGRect(x: 68, y: 54, width: view.width - 100, height: 100)
            
            imageContainer.frame = CGRect(x: 73, y: textView.bottom + 5, width: view.width - 98, height: 120)
            photo1.frame = CGRect(x: 0, y: 0, width: 80, height: 120)
            photo2.frame = CGRect(x: photo1.right + 2, y: 0, width: 80, height: 120)
            photo3.frame = CGRect(x: photo2.right + 2, y: 0, width: 80, height: 120)
            photo4.frame = CGRect(x: photo3.right + 2, y: 0, width: 80, height: 120)
            
            setupTableHeader1()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        fetchComment()
    }
    
    private func setupTableHeader1() {
        if let grandParentPostinfo = parentPost.isComment {
            let targetId = grandParentPostinfo
            DatabaseManager.shared.fetchPostId(whichTable: whichTable, postId: targetId) { [weak self](result) in
                switch result {
                case.success(let post):
                    self?.setupTableHeader(post: post)
                case .failure(_):
                    print("failed to fetch コメントの親cellInfo")
                }
            }
        }
        
    }
    
    private func fetchComment() {
        DatabaseManager.shared.fetchCommentArray(whichTable: whichTable, parentPost: parentPost) { [weak self](result) in
            switch result {
            case .success(let postArray):
                self?.posts = postArray
                self?.tableView.reloadData()
            case .failure(_):
                print("failed to fetch in UserPost(fetchCommunityArray)")
            }
        }
    }
    
    @objc private func refresh() {
        fetchComment()
        tableView.refreshControl?.endRefreshing()
    }
    
    private func setupTableHeader(post: Post) {
        
        userName.text = post.postName
        userName.sizeToFit()
        timeLabel.text = post.postTime
        timeLabel.sizeToFit()
        let userNameWidth = userName.width
        timeLabel.center.x += userNameWidth
        textView.text = post.postMessage
        textView.sizeToFit()
        let textViewHeight = textView.height
        imageContainer.center.y += textViewHeight - 100
            
        let path = "profile_picture/\(post.postEmail)-profile.png"
        StorageManager.shared.getDownloadURL(for: path, completion: { [weak self]result in
            switch result {
            case .success(let url):
                self?.userImage.layer.borderWidth = 1
                self?.userImage.layer.borderColor = UIColor.gray.cgColor
                DispatchQueue.main.async {
                    self?.userImage.sd_setImage(with: url, completed: nil)
                }
            case .failure(_):
                self?.userImage.layer.borderWidth = 1
                self?.userImage.layer.borderColor = UIColor.gray.cgColor
                self?.userImage.image = UIImage(systemName: "person.circle")
            }
        })
        
        if post.photoUrl?.count ?? 0 >= 1 {
            imageContainer.isHidden = false
            imageContainer.layer.masksToBounds = true
            imageContainer.layer.borderWidth = 1
            imageContainer.layer.borderColor = UIColor.systemGray3.cgColor
        }
        if post.photoUrl?.count == 1 {
            photo1.frame.size.height = 160
            imageContainer.frame.size.height = 160

            photo1.isHidden = false
            let image1 = URL(string: post.photoUrl?[0] ?? "")
            if let url = image1 {
                DispatchQueue.main.async {
                    self.photo1.sd_setImage(with: url, completed: nil)
                }
            }
        }
        if post.photoUrl?.count == 2 {
            photo1.isHidden = false
            photo2.isHidden = false
            photo1.frame.size.height = 130
            photo2.frame.size.height = 130
            imageContainer.frame.size.height = 130
            let image1 = URL(string: post.photoUrl?[0] ?? "")
            let image2 = URL(string: post.photoUrl?[1] ?? "")
            if let url1 = image1, let url2 = image2 {
                DispatchQueue.main.async {
                    self.photo1.sd_setImage(with: url1, completed: nil)
                    self.photo2.sd_setImage(with: url2, completed: nil)
                }
            }
        }
        if post.photoUrl?.count == 3 {
            photo1.isHidden = false
            photo2.isHidden = false
            photo3.isHidden = false
            photo1.frame.size.height = 105
            photo2.frame.size.height = 105
            photo3.frame.size.height = 105
            imageContainer.frame.size.height = 105
            let image1 = URL(string: post.photoUrl?[0] ?? "")
            let image2 = URL(string: post.photoUrl?[1] ?? "")
            let image3 = URL(string: post.photoUrl?[2] ?? "")
            if let url1 = image1, let url2 = image2, let url3 = image3 {
                DispatchQueue.main.async {
                    self.photo1.sd_setImage(with: url1, completed: nil)
                    self.photo2.sd_setImage(with: url2, completed: nil)
                    self.photo3.sd_setImage(with: url3, completed: nil)
                }
            }
        }
        if post.photoUrl?.count == 4 {
            photo1.isHidden = false
            photo2.isHidden = false
            photo3.isHidden = false
            photo4.isHidden = false
            photo1.frame.size.height = 90
            photo2.frame.size.height = 90
            photo3.frame.size.height = 90
            photo4.frame.size.height = 90
            imageContainer.frame.size.height = 90
            let image1 = URL(string: post.photoUrl?[0] ?? "")
            let image2 = URL(string: post.photoUrl?[1] ?? "")
            let image3 = URL(string: post.photoUrl?[2] ?? "")
            let image4 = URL(string: post.photoUrl?[3] ?? "")
            if let url1 = image1, let url2 = image2, let url3 = image3, let url4 = image4 {
                DispatchQueue.main.async {
                    self.photo1.sd_setImage(with: url1, completed: nil)
                    self.photo2.sd_setImage(with: url2, completed: nil)
                    self.photo3.sd_setImage(with: url3, completed: nil)
                    self.photo4.sd_setImage(with: url4, completed: nil)
                }
            }
        }
        
        let tableHeaderHeight = 55 + userName.height + textViewHeight + imageContainer.height
        tableHeaderContainer.contentSize = CGSize(width: view.width, height: tableHeaderHeight)
        tableView.reloadData()
    }
    
    
    // urlがあった場合のtextView
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        let storyboard = UIStoryboard(name: "Web", bundle: nil)
        let post = storyboard.instantiateViewController(withIdentifier: "segueWeb") as! WebViewController
        post.urlString = URL.absoluteString

        let nav = UINavigationController(rootViewController: post)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
        return false
    }
    
    @objc private func popToVC() {
        navigationController?.popViewController(animated: true)
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




extension UserPost: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let model = posts[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "BullutinBoard2TableViewCell", for: indexPath) as! BullutinBoard2TableViewCell
        cell.selectionStyle = .none
        
        cell.repeatTableViewButton.isHidden = true
        if model.isRemessage != nil { cell.isRepeat = true }
        else { cell.isRepeat = false }
        if model.shareTask != nil { cell.isTask = true }
        else { cell.isTask = false }
        
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
        
        
        if posts[indexPath.row].isComment == nil {
            cell.configure(model: model)
            cell.userPostTimeLabel.text = posts[indexPath.row].postTime
            cell.replayContainer.isHidden = true
            cell.replayHeight.constant = 0
            cell.whichCell = 0
            cell.imageButtonMarginLeft.constant = 12
            cell.imageButtonMarginHeigth.constant = 12
            cell.messageTextView.font = .systemFont(ofSize: 17)
            cell.messageTextView.delegate = self
            cell.messageTextView.isUserInteractionEnabled = true
            cell.messageTextView.isEditable = false
            cell.messageTextView.isSelectable = true
            cell.messageTextView.dataDetectorTypes = UIDataDetectorTypes.link
            cell.messageTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.link]
            return cell
        }
        else if indexPath.row == 0 {
            if posts[indexPath.row].shareTask == nil {
                cell.repeatTableView.isHidden = true
            }
            else {
                cell.repeatTableView.isHidden = false
            }
            cell.replayContainer.isHidden = false
            cell.replayHeight.constant = 35
            cell.replayContainerRight.constant = 10 // misstake for left
            cell.whichCell = 2
            cell.imageButtonMarginLeft.constant = 12
            cell.imageButtonMarginHeigth.constant = 40
            cell.messageTextView.font = .systemFont(ofSize: 17)
            cell.userNameLabel.font = .systemFont(ofSize: 16, weight: .medium)
            cell.toReplayName.text = ""
            cell.toReplayName.font = .systemFont(ofSize: 17)
            cell.toReplayName.font = .systemFont(ofSize: 15)
            cell.toReplayName.textColor = UIColor(red: 0.12, green: 0.71, blue: 0.12, alpha: 0.5)
            cell.configure(model: model)
            cell.userPostTimeLabel.text = posts[indexPath.row].postTime
            cell.messageTextView.delegate = self
            cell.messageTextView.isUserInteractionEnabled = true
            cell.messageTextView.isEditable = false
            cell.messageTextView.isSelectable = true
            cell.messageTextView.dataDetectorTypes = UIDataDetectorTypes.link
            cell.messageTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.link]
            
            tableView.tableHeaderView = tableHeaderContainer
        }
        else {
            let model2 = posts[indexPath.row]
            cell.repeatTableView.isHidden = true
            cell.replayContainer.isHidden = false
            cell.replayHeight.constant = 35
            cell.whichCell = 1
            cell.nameAndTextViewMargin.constant = 10
            cell.messageTextView.font = .systemFont(ofSize: 16)
            cell.userNameLabel.font = .systemFont(ofSize: 14, weight: .medium)
            cell.toReplayName.text = posts[0].postName
            cell.toReplayName.font = .systemFont(ofSize: 15)
            cell.toReplayName.textColor = .label
            cell.configure(model: model2)
        }
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.estimatedRowHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row != 0 else {
            return
        }
        let model = posts[indexPath.row]
        let vc = UserPost(model: model, whichTable: whichTable)
        if let haveIsComment = posts[0].isComment {
            vc.isCommentOfComment = haveIsComment
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func tapReplay(_ sender: UIButton) {
        let indexpath = sender.tag
        let storyboard: UIStoryboard = UIStoryboard(name: "Replay", bundle: nil)
        let replayVC = storyboard.instantiateViewController(withIdentifier: "segueReplay") as! ReplayViewController
        replayVC.replayParentPost = posts[indexpath]
        replayVC.isReplayRepeat = 0
        replayVC.whichTable = whichTable
        
        replayVC.replayCompletion = { [weak self] success in
            if success == true {
                self?.fetchComment()
            }
        }
        
        
        if indexpath >= 1 {
            replayVC.isCommentOfCommet = posts[0].postId
        }
        else if let post0 = parentPost.isComment {
            replayVC.isCommentOfCommet = post0
        }
        
                
        let nav = UINavigationController(rootViewController: replayVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }

    @objc private func tappedRepeat(_ sender: UIButton) {
        let indexpath = sender.tag
        let storyboard: UIStoryboard = UIStoryboard(name: "Replay", bundle: nil)
        let replayVC = storyboard.instantiateViewController(withIdentifier: "segueReplay") as! ReplayViewController
        replayVC.repeatParentPost = posts[indexpath]
        replayVC.isRepeatMessage = true
        replayVC.isReplayRepeat = 1
        replayVC.whichTable = whichTable
        
        replayVC.replayCompletion = { [weak self] success in
            if success == true {
                self?.fetchComment()
            }
        }
        
        
        if indexpath >= 1 {
            replayVC.isCommentOfCommet = posts[0].postId
        }
        else if let post0 = parentPost.isComment {
            // replayセルをタップして、replayCellのindexpath=0となった時用
            replayVC.isCommentOfCommet = post0
        }
        

        let nav = UINavigationController(rootViewController: replayVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
    
    @objc private func tappedGood(_ sender: UIButton) {
        let indexpath = sender.tag
        let indexPath = IndexPath(row: indexpath, section: 0)
        var i = 0
        
        for goodEmail in posts[indexpath].goodList {
            if safeMyEmail == goodEmail {
                posts[indexpath].goodList.remove(at: i)
                posts[indexpath].good -= 1
                tableView.reloadRows(at: [indexPath], with: .fade)
                if posts[indexpath].isComment != nil {
                    DatabaseManager.shared.insertMyGoodList(targetPost: posts[indexpath], whichTable: whichTable, whichVC: 5, uni: nil, year: nil, fac: nil) { (success) in
                        if success == true {
                            print("success remove goodList")
                        }
                    }
                }
                else {
                    if fromCommunityVC == true {
                        let nav = self.navigationController
                        // 一つ前のViewControllerを取得する
                        let communityVC = nav?.viewControllers[(nav?.viewControllers.count)!-2] as! CommunityViewController
                        // 値を渡す
                        if whichTable == 0 {
                            communityVC.posts_all[indexPathForChangeGood].good -= 1
                            var j = 0
                            for cell in communityVC.posts_all[indexPathForChangeGood].goodList {
                                if cell == safeMyEmail {
                                    communityVC.posts_all[indexPathForChangeGood].goodList.remove(at: j)
                                    communityVC.tableViewAll.reloadRows(at: [IndexPath(row: indexPathForChangeGood, section: 0)], with: .none)
                                    break
                                }
                                j += 1
                            }
                        }
                        else {
                            communityVC.posts_faculty[indexPathForChangeGood].good += 1
                            var j = 0
                            for cell in communityVC.posts_faculty[indexPathForChangeGood].goodList {
                                if cell == safeMyEmail {
                                    communityVC.posts_faculty[indexPathForChangeGood].goodList.remove(at: j)
                                    communityVC.tableViewFaculty.reloadRows(at: [IndexPath(row: indexPathForChangeGood, section: 0)], with: .none)
                                    break
                                }
                                j += 1
                            }
                        }
                    }
                    DatabaseManager.shared.insertMyGoodList(targetPost: posts[indexpath], whichTable: whichTable, whichVC: 4, uni: nil, year: nil, fac: nil) { (success) in
                        if success == true {
                            print("success remove goodList")
                        }
                    }
                }
                return
            }
            i += 1
        }
        
        posts[indexpath].goodList.append(safeMyEmail)
        posts[indexpath].good += 1
        tableView.reloadRows(at: [indexPath], with: .fade)
        
        // goodListに入れる
        if posts[indexpath].isComment != nil {
            DatabaseManager.shared.insertMyGoodList(targetPost: posts[indexpath], whichTable: whichTable, whichVC: 1, uni: nil, year: nil, fac: nil) { (success) in
                if success == true {
                    print("success remove goodList")
                }
            }
        }
        else {
            if fromCommunityVC == true {
                let nav = self.navigationController
                // 一つ前のViewControllerを取得する
                let communityVC = nav?.viewControllers[(nav?.viewControllers.count)!-2] as! CommunityViewController
                // 値を渡す
                if whichTable == 0 {
                    communityVC.posts_all[indexPathForChangeGood].good += 1
                    communityVC.posts_all[indexPathForChangeGood].goodList.append(safeMyEmail)
                    communityVC.tableViewAll.reloadRows(at: [IndexPath(row: indexPathForChangeGood, section: 0)], with: .none)
                }
                else {
                    communityVC.posts_faculty[indexPathForChangeGood].good += 1
                    communityVC.posts_faculty[indexPathForChangeGood].goodList.append(safeMyEmail)
                    communityVC.tableViewFaculty.reloadRows(at: [IndexPath(row: indexPathForChangeGood, section: 0)], with: .none)
                }
            }
            
            DatabaseManager.shared.insertMyGoodList(targetPost: posts[indexpath], whichTable: whichTable, whichVC: 0, uni: nil, year: nil, fac: nil) { (success) in
                if success == true {
                    print("success insert goodList")
                }
            }
        }
        
    }
    @objc private func tappedGoodNumber(_ sender: UIButton) {
        let indexpath = sender.tag
        let targetPost = posts[indexpath]
        let goodListVC = GoodListViewController(postId: targetPost.postId, whichTable: whichTable)
        goodListVC.targetPost = targetPost
        let nav = UINavigationController(rootViewController: goodListVC)
        present(nav, animated: true)
    }
    
    @objc private func tappedRepeatNumber(_ sender: UIButton) {
        let indexpath = sender.tag
        let targetPost = posts[indexpath]
        let goodListVC = GoodListViewController(postId: targetPost.postId, whichTable: whichTable)
        goodListVC.targetPost = targetPost
        goodListVC.isReaptMember = true
        let nav = UINavigationController(rootViewController: goodListVC)
        present(nav, animated: true)
    }

    @objc private func didTapImageButton(_ sender: UIButton) {
        let indexpath = sender.tag
        let friendEmail = posts[indexpath].postEmail
        let friendVC = FriendProfileViewController(partnerEmail: friendEmail)
        let nav = UINavigationController(rootViewController: friendVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
    
    @objc private func tappedOther(_ sender: UIButton) {
        let indexpath = sender.tag
        let alertPost = posts[indexpath]
        otherMenuActionSheet(alertPost: alertPost, indexpath: indexpath)
    }
    
    @objc private func tapRepeatTableView(_ sender: UIButton) {
        let indexpath = sender.tag
        if let target = posts[indexpath].isRemessage {
            if target.isRemessage == nil {
                // isRemessageがないバージョン
                let remessagePost = Post(postId: target.parentPostId, postMessage: target.postMessage, postEmail: target.postEmail, postName: target.postName, postTime: target.postTime, good: target.good, goodList: target.goodList, remessage: target.remessage, remessagePostArray: target.remessagePostArray, isRemessage: nil, comment: target.comment, isComment: target.isComment, photoUrl: target.photoUrl, shareTask: target.shareTask)
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
                            let userPost = UserPost(model: remessagePost, whichTable: self?.whichTable ?? 0)
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
        if let task = posts[indexpath].shareTask {
            let storyboard: UIStoryboard = UIStoryboard(name: "ShareTodo", bundle: nil)
            let shareTodoViewController = storyboard.instantiateViewController(withIdentifier: "ShareTodoViewController") as! ShareTodoViewController
            shareTodoViewController.task = Task(taskId: task.taskId, taskName: task.taskName, notifyTime: "", timeSchedule: task.timeSchedule, taskLimit: task.taskLimit, createDate: Date(), isFinish: false, shareTask: ShareTask(documentPath: task.documentPath, memberCount: task.memberCount, makedEmail: task.makedEmail, doneMember: task.doneMember, gettingMember: task.gettingMember, wantToTalkMember: task.wantToTalkMember))
            let nav = UINavigationController(rootViewController: shareTodoViewController)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        }
    }
    
    
    private func otherMenuActionSheet(alertPost: Post, indexpath: Int) {
        let actionSheet = UIAlertController(title: "",
                                            message: "",
                                            preferredStyle: .actionSheet)
        if alertPost.postEmail == safeMyEmail {
            actionSheet.addAction(UIAlertAction(title: "この投稿を削除する", style: .default, handler: { [weak self] _ in
                if indexpath == 0 {
                    guard let strongSelf = self else {
                        return
                    }
                    if strongSelf.parentPost.isComment == nil {
                        // commentではなくpostの投稿
                        DatabaseManager.shared.removePost(postId: alertPost.postId, postEmail: alertPost.postEmail, whichTable: strongSelf.whichTable, isParentPath: nil) { (succuss) in
                            if succuss == true {
                                let nav = strongSelf.navigationController
                                let communityVC = nav?.viewControllers[(nav?.viewControllers.count)!-2] as! CommunityViewController
                                if strongSelf.whichTable == 0 {
                                    communityVC.posts_all.remove(at: strongSelf.indexPathForChangeGood)
                                    communityVC.tableViewAll.reloadData()
                                }
                                if strongSelf.whichTable == 1 {
                                    communityVC.posts_faculty.remove(at: strongSelf.indexPathForChangeGood)
                                    communityVC.tableViewFaculty.reloadData()
                                }
                                strongSelf.navigationController?.popViewController(animated: true)
                            }
                            else {
                                strongSelf.alertUserError(alertMessage: "ネットワークを確認してください")
                            }
                        }
                    }
                    else {
                        if strongSelf.parentPost.isComment!.contains("|!|") == true {
                            let stringArray = strongSelf.parentPost.isComment!.components(separatedBy: "|!|")
                            if stringArray.count == 2 {
                                let grandPostId = (stringArray[0])
                                DatabaseManager.shared.removePost(postId: alertPost.postId, postEmail: alertPost.postEmail, whichTable: strongSelf.whichTable, isParentPath: grandPostId) { (succuss) in
                                    if succuss == true {
                                        strongSelf.navigationController?.popViewController(animated: true)
                                    }
                                    else {
                                        strongSelf.alertUserError(alertMessage: "ネットワークを確認してください")
                                    }
                                }
                            }
                        }
                        else {
                            DatabaseManager.shared.removePost(postId: alertPost.postId, postEmail: alertPost.postEmail, whichTable: self?.whichTable ?? 0, isParentPath: self?.parentPost.isComment!) { (succuss) in
                                if succuss == true {
                                    self?.navigationController?.popViewController(animated: true)
                                }
                                else {
                                    self?.alertUserError(alertMessage: "ネットワークを確認してください")
                                }
                            }
                        }
                        
                    }
                    
                } // indexpath != 0
                
                else {
                    // indexpath != 0であり、parentPostのpathから削除
                    if self?.isCommentOfComment != nil {
                        guard let rowParentPost = self?.parentPost.postId else {
                            return
                        }
                        DatabaseManager.shared.removePost(postId: alertPost.postId, postEmail: alertPost.postEmail, whichTable: self?.whichTable ?? 0, isParentPath: rowParentPost) { (succuss) in
                            if succuss == true {
                                self?.alertMessage(alertMessage: "この投稿を削除しました")
                                self?.posts.remove(at: indexpath)
                                self?.tableView.reloadData()
                            }
                            else {
                                self?.alertUserError(alertMessage: "ネットワークを確認してください")
                            }
                        }
                    }
                    else {
                        DatabaseManager.shared.removePost(postId: alertPost.postId, postEmail: alertPost.postEmail, whichTable: self?.whichTable ?? 0, isParentPath: self?.parentPost.postId ?? "") { (succuss) in
                            if succuss == true {
                                self?.alertMessage(alertMessage: "この投稿を削除しました")
                                self?.posts.remove(at: indexpath)
                                self?.tableView.reloadData()
                            }
                            else {
                                self?.alertUserError(alertMessage: "ネットワークを確認してください")
                            }
                        }
                    }
                    
                }
            }))
        }
        actionSheet.addAction(UIAlertAction(title: "通報する", style: .default, handler: { [weak self] _ in
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
            actionSheet.popoverPresentationController?.sourceRect = CGRect(x: screenSize.size.width/2,
                                                                           y: screenSize.size.height,
                                                                           width: 0,
                                                                           height: 0)
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
            let blockedList: [String] = ["\(friendEmail)"]
            UserDefaults.standard.setValue(blockedList, forKey: "blocked")
        }
        
        if safeMyEmail == friendEmail {
            DatabaseManager.shared.FollowYou(myEmail: safeMyEmail, friendEmail: friendEmail, isUnFollow: true) { (success) -> (Void) in
                print("success")
            }
        }
        
        DatabaseManager.shared.blockedYou(myEmail: safeMyEmail, friendEmail: friendEmail, cancelBlock: false) { [weak self](success) -> (Void) in
            if success == true {
                self?.posts.remove(at: indexpath)
                self?.tableView.reloadData()
                self?.alertMessage(alertMessage: "ブロックしました")
            }
        }
        
        
    }
    
    
    
    @objc private func tapImage1(gestureRecognizer: UITapGestureRecognizer, index: Int) {
        let tappedLocation = gestureRecognizer.location(in: tableView)
        let tappedIndexPath = tableView.indexPathForRow(at: tappedLocation)
        guard let tappedRow = tappedIndexPath?.row else { return }
        let imageSlideshow = ImageSlideshow()
        
        var sdWebImageSource = [SDWebImageSource]()
        if posts[tappedRow].photoUrl?.count == 1 {
            sdWebImageSource = [SDWebImageSource(urlString: (posts[tappedRow].photoUrl?[0]) ?? "")!]
        }
        if posts[tappedRow].photoUrl?.count == 2 {
            sdWebImageSource = [SDWebImageSource(urlString: (posts[tappedRow].photoUrl?[0]) ?? "")!, SDWebImageSource(urlString: (posts[tappedRow].photoUrl?[1]) ?? "")!]
            if index == 1 { sdWebImageSource.swapAt(0, 1) }
        }
        if posts[tappedRow].photoUrl?.count == 3 {
            sdWebImageSource = [SDWebImageSource(urlString: (posts[tappedRow].photoUrl?[0]) ?? "")!, SDWebImageSource(urlString: (posts[tappedRow].photoUrl?[1]) ?? "")!, SDWebImageSource(urlString: (posts[tappedRow].photoUrl?[2]) ?? "")!]
            if index == 1 { sdWebImageSource.swapAt(0, 1); sdWebImageSource.swapAt(1, 2) }
            if index == 2 { sdWebImageSource.swapAt(0, 1); sdWebImageSource.swapAt(0, 2) }
        }
        if posts[tappedRow].photoUrl?.count == 4 {
            sdWebImageSource = [SDWebImageSource(urlString: (posts[tappedRow].photoUrl?[0]) ?? "")!, SDWebImageSource(urlString: (posts[tappedRow].photoUrl?[1]) ?? "")!, SDWebImageSource(urlString: (posts[tappedRow].photoUrl?[2]) ?? "")!, SDWebImageSource(urlString: (posts[tappedRow].photoUrl?[3]) ?? "")!]
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
    

}


