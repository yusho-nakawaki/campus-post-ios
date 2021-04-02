//
//  GoodListViewController.swift
//  Match
//
//  on 2020/12/31.
//

import UIKit
import JGProgressHUD

class GoodListViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    private var goodList = [String]()
    private let whichTable: Int
    private let postId: String
    public var targetPost = Post(postId: "", postMessage: "", postEmail: "", postName: "", postTime: "", good: 0, goodList: [], remessage: 0, remessagePostArray: [], isRemessage: nil, comment: 0, isComment: nil, photoUrl: nil, shareTask: nil)
    public var friendEmail = ""
    public var friendName = ""
    public var isFriendsMember = false
    public var isReaptMember = false
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(GoodListTableViewCell.self, forCellReuseIdentifier: "goodListCell")
        return table
    }()
    
    init(postId: String, whichTable: Int) {
        self.postId = postId
        self.whichTable = whichTable
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tableView.delegate = self
        tableView.dataSource = self
        setupNavigationTitle(text: "いいね")
        
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "multiply"), style: .done, target: self, action: #selector(dismissSelf))
        navigationController?.navigationBar.tintColor = .label
        
        if isReaptMember == true {
            setupNavigationTitle(text: "投稿をリピートした友達")
        }
        
        if isFriendsMember == true {
            setupNavigationTitle(text: "\(friendName)が追加した友達")
            DatabaseManager.shared.fetchFollowMember(friendEmail: friendEmail) { [weak self] (result) in
                switch result {
                case .success(let friendsMemeber):
                    self?.goodList = friendsMemeber
                    self?.tableView.reloadData()
                case .failure(let error):
                    print("failed fetch friend \(error)")
                }
            }
        }
        else {
            if isReaptMember == false {
                if targetPost.postId == "" {
                    // notificationVC
                    DatabaseManager.shared.fetchPostId(whichTable: whichTable, postId: postId) { [weak self](result) in
                        switch result {
                        case .success(let post):
                            var postForChange = post
                            postForChange.goodList.removeFirst()  // 一番めに0_nilがあるため
                            self?.goodList = postForChange.goodList
                            self?.tableView.reloadData()
                        case .failure(_):
                            print("failed to fetch good list")
                        }
                    }
                }
                else {
                    goodList = targetPost.goodList
                    goodList.removeFirst()
                    tableView.reloadData()
                }
            }
            else {
                /*
                 friendVCではうまく表示されるが、communityVCでは何故かうまく表示されない
                 */
                if targetPost.postId == "" {
                    // notificationVC
                    DatabaseManager.shared.fetchPostId(whichTable: whichTable, postId: postId) { [weak self](result) in
                        switch result {
                        case .success(let post):
                            var postForChange = post
                            postForChange.remessagePostArray.removeFirst()  // 一番めに0_nil
                            self?.goodList = postForChange.remessagePostArray
                            self?.tableView.reloadData()
                        case .failure(_):
                            print("failed to fetch good list")
                        }
                    }
                }
                else {
                    goodList = targetPost.remessagePostArray
                    goodList.removeFirst()
                    tableView.reloadData()
                }
            }
        }
        
        view.addSubview(tableView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    private func setupNavigationTitle(text: String) {
        // タイトルを表示するラベルを作成
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.sizeToFit()
        
        navigationItem.titleView = label
    }
    
}

extension GoodListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return goodList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "goodListCell", for: indexPath) as! GoodListTableViewCell
        let model = goodList[indexPath.row]
        cell.configure(email: model)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let friendEmail = goodList[indexPath.row]
        let friendVC = FriendProfileViewController(partnerEmail: friendEmail)
        let nav = UINavigationController(rootViewController: friendVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}
