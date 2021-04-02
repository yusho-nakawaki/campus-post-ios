//
//  SearchFriendsViewController.swift
//  Study_Match
//
//  on 2020/10/31.
//  Copyright © 2020 yusho. All rights reserved.
//

import UIKit
import JGProgressHUD

struct SearchResult {
    let name: String
    let email: String
}

struct FriendsList {
    var name: String
    var email: String
    var picture: String
}

final class SearchFriendsViewController: UIViewController {
    
    private let spinner = JGProgressHUD()
    private var myFriends = [FriendsList]()
    private var results = [SearchResult]()
    private var didSearch = false
    private var myFriendsEmail = [String]()
        
    public var completionForChatFriends: ((SearchResult) -> (Void))?
    
    private let searchFreindsBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "友達を検索・・・"
        return bar
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(SearchFriendsTableViewCell.self,
                       forCellReuseIdentifier: SearchFriendsTableViewCell.identifier)
        return table
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "見つかりませんでした"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.isHidden = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        searchFreindsBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        view.addSubview(tableView)
        view.addSubview(noResultsLabel)
        
        navigationController?.navigationBar.topItem?.titleView = searchFreindsBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "戻る",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        navigationController?.navigationBar.tintColor = .label
        
        guard let myfriendEmails = UserDefaults.standard.value(forKey: "myFriends") as? [String] else {
            return
        }
        myFriendsEmail = myfriendEmails
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds
        noResultsLabel.frame = CGRect(x: view.width/4,
                                      y: (view.height-100)/2,
                                      width: view.width/2,
                                      height: 100)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        var i = 0
        for cell in myFriendsEmail {
            var frinedList = FriendsList(name: "", email: "", picture: "")
            frinedList.email = cell
            DatabaseManager.shared.fetchUserName(email: cell) { [weak self](result) in
                switch result {
                case .success(let name):
                    frinedList.name = name
                    let path = "profile_picture/\(cell)-profile.png"
                    StorageManager.shared.getDownloadURL(for: path, completion: { [weak self]result in
                        switch result {
                        case .success(let url):
                            frinedList.picture = url.absoluteString
                            self?.myFriends.append(frinedList)
                        case .failure(_):
                            frinedList.picture = "defalut"
                            self?.myFriends.append(frinedList)
                        }
                    })
                case .failure(_):
                    print("notification cell error in configure name")
                }
            }
            i += 1
        }
        
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    

}

extension SearchFriendsViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text,
            !text.replacingOccurrences(of: " ", with: "").isEmpty else {
                return
        }
        
        searchBar.resignFirstResponder()
        
        spinner.show(in: view)
        results.removeAll()
        filterUsers(with: text)
    }
    
    
    func filterUsers(with term: String) {
        // updata the UI
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        spinner.dismiss()
        
        let resultsFriends: [SearchResult] = myFriends.filter({
            let email = $0.email
            let name = $0.name
            guard email != safeMyEmail else { return false }
            let lowerName = name.lowercased()
            
            // もしtrueだったらcompactMapへ
            return lowerName.contains(term.lowercased())
        }).compactMap ({
            return SearchResult(name: $0.name, email: $0.email)
        })
        
        results = resultsFriends
        didSearch = true
        updataUI()
    }
    
    func updataUI() {
        if results.isEmpty {
            noResultsLabel.isHidden = false
            tableView.isHidden = true
        }
        else {
            noResultsLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            didSearch = false
            noResultsLabel.isHidden = true
            
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
    
    
}


extension SearchFriendsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if didSearch == true {
            return results.count
        }
        else {
            return myFriendsEmail.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchFriendsTableViewCell.identifier, for: indexPath) as! SearchFriendsTableViewCell
        if didSearch == true {
            let model = results[indexPath.row]
            cell.configureDidSearch(with: model)
        }
        else {
            let model = myFriendsEmail[myFriendsEmail.count - indexPath.row - 1]
            cell.configure(model: model)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if didSearch == true {
            let selectedFriendsForChat = results[indexPath.row]
            dismiss(animated: true) { [weak self] in
                self?.completionForChatFriends?(selectedFriendsForChat)
            }
        }
        else {
            guard let cell = tableView.cellForRow(at: indexPath) as? SearchFriendsTableViewCell,
                  let name = cell.userNameLabel.text else {
                return
            }
            let email = myFriendsEmail[myFriendsEmail.count - indexPath.row - 1]
            let selectedFriendsForChat = SearchResult(name: name, email: email)
            dismiss(animated: true) { [weak self] in
                self?.completionForChatFriends?(selectedFriendsForChat)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
}
