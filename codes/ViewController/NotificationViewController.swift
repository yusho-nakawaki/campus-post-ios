//
//  SearchViewController.swift
//  Study_Match
//
//  on 2020/10/20.
//  Copyright © 2020 yusho. All rights reserved.
//

import UIKit
import JGProgressHUD


struct NotificationModel {
    var friendEmail: [String]
    var isRead: Bool
    let postId: String
    let model: String // repeat & replay & good & friend
    let time: String
    let whichTable: Int
    let textView: String
}

struct AshiatoModel {
    let email: String
    let date: String
}

struct Ashiato {
    let friendEmail: String
    let date: String
    let isTimeSchedule: Bool
}


class NotificationViewController: UIViewController {
    
    public var whichCell = 0 //0はいいね 1はリピート, 2はリプライ
    private var notificationArray = [NotificationModel]()
    private var notificationCount = 0
    private var ashiatoArray = [AshiatoModel]()
    private var ashiatoCount = 0
    private var whichTable = 0 // 0がリアクション, 1が足あと
    
    private let spinner = JGProgressHUD()
    
    let underlineLayer = CALayer()
    var segmentItemWidth: CGFloat = 0
    @IBOutlet weak var segmentedControll: UISegmentedControl!
    
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(UINib(nibName: "NotificationTableViewCell", bundle: nil), forCellReuseIdentifier: "notificationCell")
        return table
    }()
    private let tableView1: UITableView = {
        let table = UITableView()
        table.register(NotificationAshiatoCell.self, forCellReuseIdentifier: "ashiatoCell")
        return table
    }()
    
    private let noLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .medium)
        label.textColor = .gray
        label.text = "投稿をしていいねなどをもらおう"
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView1.delegate = self
        tableView1.dataSource = self
        tableView1.refreshControl = UIRefreshControl()
        tableView1.refreshControl?.addTarget(self, action: #selector(refresh1), for: .valueChanged)
        
        segmentedControll.frame.size.width = view.width
        segmentedControll.frame.size.height = 43
        navigationController?.navigationBar.tintColor = UIColor(named: "gentle")
        navigationController?.navigationBar.barTintColor = UIColor(named: "appBackground")
        
        segmentItemWidth = view.frame.width / 2
        underlineLayer.backgroundColor = UIColor(red: 0.12, green: 0.71, blue: 0.12, alpha: 1).cgColor
        underlineLayer.frame = CGRect(x: 0, y: 41, width: view.width/2 - 15, height: 2)
        segmentedControll.layer.addSublayer(underlineLayer)
        segmentedControll.iOS12Style()
        
        DatabaseManager.shared.notification { [weak self](result) in
            switch result {
            case .success(let notificationNode):
                guard let strongSelf = self else {
                    return
                }
                self?.noLabel.isHidden = true
                self?.tableView.isHidden = false
                strongSelf.notificationArray = notificationNode
                strongSelf.notificationCount = notificationNode.count
                strongSelf.tableView.reloadData()
                strongSelf.afterNotification()  
            case .failure(_):
                self?.noLabel.isHidden = false
                self?.tableView.isHidden = true
            }
        }
        
        fetchNewAshiato()
        
        view.addSubview(tableView)
        view.addSubview(tableView1)
        view.addSubview(noLabel)
        
        
        guard let formalEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeFormalEmail = DatabaseManager.safeEmail(emailAddress: formalEmail)
        if safeFormalEmail == "unnei-gmail-com" {
            let unneiButton = UIButton(frame: CGRect(x: view.width - 150,
                                                     y: view.height - 230,
                                                     width: 100,
                                                     height: 100))
            unneiButton.setTitle("運営ボタン", for: .normal)
            unneiButton.backgroundColor = UIColor(red: 0.12, green: 0.71, blue: 0.12, alpha: 1)
            unneiButton.layer.cornerRadius = 50
            unneiButton.addTarget(self, action: #selector(tapUnnei), for: .touchUpInside)
            
            view.addSubview(unneiButton)
        }
        
        // スワイプでtableViewを変える
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(sender:)))
        leftSwipe.direction = .left
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(sender:)))
        rightSwipe.direction = .right
        tableView.addGestureRecognizer(leftSwipe)
        tableView1.addGestureRecognizer(rightSwipe)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let tabItem = tabBarController?.tabBar.items?[2] {
            tabItem.badgeValue = nil
        }
    }
    
    private func afterNotification() {
        for cell in notificationArray {
            if cell.isRead == false {
                DatabaseManager.shared.iReadNotification(date: cell.time)
            }
            if cell.isRead == true {
                break
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if view.width > 800 {
            tableView.frame = CGRect(x: (view.width-800)/2,
                                        y: 5,
                                        width: 800,
                                        height: view.height)
            noLabel.frame = view.bounds
            tableView1.frame = CGRect(x: view.width + (view.width-800)/2,
                                      y: 5,
                                      width: 800,
                                      height: view.height)
        }
        else {
            tableView.frame = view.bounds
            noLabel.frame = view.bounds
            tableView1.frame = CGRect(x: view.width, y: 0, width: view.width, height: view.height)
        }
        
    }

    
    @IBAction func tapSegmentedControll(_ sender: Any) {
        let x = CGFloat(segmentedControll.selectedSegmentIndex) * segmentItemWidth
        underlineLayer.frame.origin.x = x
        
        if segmentedControll.selectedSegmentIndex == 0 {
            whichTable = 0
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .transitionCurlDown, animations: { [weak self] in
                self?.tableView.frame.origin.x += self?.view.width ?? 0
                self?.noLabel.frame.origin.x += self?.view.width ?? 0
                self?.tableView1.frame.origin.x += self?.view.width ?? 0
            })
        } else {
            whichTable = 1
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .transitionCurlDown, animations: { [weak self] in
                self?.tableView.frame.origin.x -= self?.view.width ?? 0
                self?.noLabel.frame.origin.x -= self?.view.width ?? 0
                self?.tableView1.frame.origin.x -= self?.view.width ?? 0
            }, completion: { [weak self] _ in
                self?.tableView1.reloadData()
            })
        }
    }
    
    @objc private func didSwipe(sender: UISwipeGestureRecognizer) {
        if sender.direction == .right {
            segmentedControll.selectedSegmentIndex -= 1
            tapSegmentedControll(sender)
        }
        else if sender.direction == .left {
            segmentedControll.selectedSegmentIndex += 1
            tapSegmentedControll(sender)
        }
    }
    
    
    @objc private func refresh() {
        tableView.refreshControl?.endRefreshing()
    }
    @objc private func refresh1() {
        fetchNewAshiato()
        tableView1.refreshControl?.endRefreshing()
        tableView1.reloadData()
    }

    private func fetchNewAshiato() {
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        DatabaseManager.shared.fetchAshiato(myEmail: safeMyEmail) { [weak self](result) in
            switch result {
            case .success(let ashiato):
                self?.ashiatoArray = ashiato
                self?.ashiatoCount = ashiato.count
            case .failure(_):
                print("failed to fetch ashiato list")
            }
        }
    }
    
    @objc private func tapUnnei() {
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
    
}





extension NotificationViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if whichTable == 0 {
            return notificationCount
        } else {
            return ashiatoCount
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if whichTable == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "notificationCell", for: indexPath) as! NotificationTableViewCell
            let model = notificationArray[indexPath.row]
            cell.configure(model: model)
            cell.selectionStyle = .none
            
            cell.profileButton1.tag = indexPath.row
            cell.profileButton1.addTarget(self, action: #selector(tapProfilePicture1), for: .touchUpInside)
            cell.profileButton2.tag = indexPath.row
            cell.profileButton2.addTarget(self, action: #selector(tapProfilePicture2), for: .touchUpInside)
            cell.profileButton3.tag = indexPath.row
            cell.profileButton3.addTarget(self, action: #selector(tapProfilePicture3), for: .touchUpInside)
            cell.profileButton4.tag = indexPath.row
            cell.profileButton4.addTarget(self, action: #selector(tapProfilePicture4), for: .touchUpInside)
            cell.ellipsis.tag = indexPath.row
            cell.ellipsis.addTarget(self, action: #selector(tapEllipsisButton), for: .touchUpInside)
            
            return cell
        } else {
            let cell = tableView1.dequeueReusableCell(withIdentifier: "ashiatoCell", for: indexPath) as! NotificationAshiatoCell
            let model = ashiatoArray[indexPath.row]
            cell.configure(model: model)
            cell.selectionStyle = .none
            
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if whichTable == 0 {
            if notificationArray[indexPath.row].model == "friend" {
                let friendVC = FriendProfileViewController(partnerEmail: notificationArray[indexPath.row].friendEmail[0])
                let nav = UINavigationController(rootViewController: friendVC)
                nav.modalPresentationStyle = .fullScreen
                present(nav, animated: true, completion: nil)
            }
            else {
                spinner.show(in: view)
                let targetPost = notificationArray[indexPath.row]
                let targetPostPass = notificationArray[indexPath.row].postId
                DatabaseManager.shared.fetchPostId(whichTable: notificationArray[indexPath.row].whichTable, postId: targetPostPass) { [weak self](result) in
                    switch result {
                    case .success(let fetchPost):
                        self?.spinner.dismiss()
                        let userPost = UserPost(model: fetchPost, whichTable: targetPost.whichTable)
                        self?.navigationController?.pushViewController(userPost, animated: true)
                    case .failure(_):
                        self?.alertMessage(alertMessage: "この投稿は削除されました")
                        self?.spinner.dismiss()
                        print("failed to fetch in notificationVC(didSelectRowAt)")
                    }
                }
            }
        } else {
            let friendEmail = ashiatoArray[indexPath.row].email
            let friendVC = FriendProfileViewController(partnerEmail: friendEmail)
            let nav = UINavigationController(rootViewController: friendVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if whichTable == 0 {
            return tableView.estimatedRowHeight
        } else {
            return 80
        }
    }
    
    
    @objc private func tapProfilePicture1(_ sender: UIButton) {
        let indexpath = sender.tag
        let targetEmail = notificationArray[indexpath].friendEmail[0]
        let friendProfileVC = FriendProfileViewController(partnerEmail: targetEmail)
        let nav = UINavigationController(rootViewController: friendProfileVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
    @objc private func tapProfilePicture2(_ sender: UIButton) {
        let indexpath = sender.tag
        let targetEmail = notificationArray[indexpath].friendEmail[1]
        let friendProfileVC = FriendProfileViewController(partnerEmail: targetEmail)
        let nav = UINavigationController(rootViewController: friendProfileVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
    @objc private func tapProfilePicture3(_ sender: UIButton) {
        let indexpath = sender.tag
        let targetEmail = notificationArray[indexpath].friendEmail[2]
        let friendProfileVC = FriendProfileViewController(partnerEmail: targetEmail)
        let nav = UINavigationController(rootViewController: friendProfileVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
    @objc private func tapProfilePicture4(_ sender: UIButton) {
        let indexpath = sender.tag
        let targetEmail = notificationArray[indexpath].friendEmail[3]
        let friendProfileVC = FriendProfileViewController(partnerEmail: targetEmail)
        let nav = UINavigationController(rootViewController: friendProfileVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
    
    @objc private func tapEllipsisButton(_ sender: UIButton) {
        let indexpath = sender.tag
        let targetPost = notificationArray[indexpath]
        let goodListVC = GoodListViewController(postId: targetPost.postId, whichTable: whichTable)
        let nav = UINavigationController(rootViewController: goodListVC)
        present(nav, animated: true)
    }
    
}




extension UIImage {
    
    convenience init?(color: UIColor, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
}


extension UISegmentedControl {
    func iOS12Style() {
        
        let unselectedTintImage = UIImage(color: .clear, size: CGSize(width: 1, height: 30))
        let selectedTintImage = UIImage(color: .clear, size: CGSize(width: 1, height: 30))
//        let highlightImage = UIImage(color: UIColor.blue.withAlphaComponent(0.20), size: CGSize(width: 1, height: 30))
        
        // 選択されていない時のUISegmentedControlの背景
        setBackgroundImage(unselectedTintImage, for: .normal, barMetrics: .default)
        
        // 選択時のUISegmentedControlの背景
        setBackgroundImage(selectedTintImage, for: .selected, barMetrics: .default)
        
        // 選択中のUISegmentedControlのハイライト時の背景
//        setBackgroundImage(highlightImage, for: .highlighted, barMetrics: .default)
        
        setTitleTextAttributes([.foregroundColor: UIColor.label], for: .selected)
        setTitleTextAttributes([.foregroundColor: UIColor.label], for: .normal)
        setDividerImage(selectedTintImage, forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
    }
}
