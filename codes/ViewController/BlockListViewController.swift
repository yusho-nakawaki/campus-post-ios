//
//  BlockListViewController.swift
//  match
//
//  on 2021/02/28.
//

import UIKit
import JGProgressHUD

class BlockListViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    private var blockList = [String]()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(GoodListTableViewCell.self, forCellReuseIdentifier: "goodListCell")
        return table
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tableView.delegate = self
        tableView.dataSource = self
        title = "ブロックしたユーザー"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "multiply"), style: .done, target: self, action: #selector(dismissSelf))
        navigationController?.navigationBar.tintColor = .label
        
        
        if let blockArray = UserDefaults.standard.value(forKey: "blocked") as? [String] {
            blockList = blockArray
        }
        if blockList.count == 0 {
            let blockedContainer = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: view.height))
            blockedContainer.backgroundColor = .systemBackground
            let blockedLabel = UILabel(frame: CGRect(x: 0, y: 150, width: view.width, height: 30))
            blockedLabel.text = "ブロックしているユーザーはいません"
            blockedLabel.font = .systemFont(ofSize: 16, weight: .bold)
            blockedLabel.textColor = .gray
            blockedLabel.backgroundColor = .systemBackground
            blockedLabel.textAlignment = .center
            blockedContainer.addSubview(blockedLabel)
            tableView.addSubview(blockedContainer)
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
    
}

extension BlockListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "goodListCell", for: indexPath) as! GoodListTableViewCell
        let model = blockList[indexPath.row]
        cell.configure(email: model)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let friendEmail = blockList[indexPath.row]
        let friendVC = FriendProfileViewController(partnerEmail: friendEmail)
        let nav = UINavigationController(rootViewController: friendVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}
