//
//  SelectUniveristyViewController.swift
//  match
//
//  on 2021/03/22.
//

import UIKit

class SelectUniveristyViewController: UIViewController {

    
    // 名前はゲストにする
    private let uniList = ["五十音順", "青山学院大学", "桜美林大学", "大阪大学", "大妻女子大学", "学習院大学", "神奈川大学", "関西大学", "関西学院大学", "九州大学", "京都大学", "京都産業大学", "近畿大学", "慶應義塾大学", "神戸大学", "国士舘大学", "駒澤大学", "上智大学", "成蹊大学", "専修大学", "名古屋大学", "中央大学", "中京大学", "帝京大学", "筑波大学", "東洋大学", "同志社大学", "東京大学", "東京工業大学", "東京理科大学", "東北大学", "日本大学", "日本女子大学", "東京農業大学", "北海道大学", "一橋大学", "福岡大学", "法政大学", "武庫川女子大学", "明治大学", "明治学院大学", "名城大学", "横浜国立大学", "龍谷大学", "立教大学", "立命館大学", "早稲田大学"]
    private var results = [String]()
    private var didSearch = false
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(SelectUniveristyTableViewCell.self, forCellReuseIdentifier: "SelectUniveristyTableViewCell")
        return table
    }()
    
    private let searchUniBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "大学を検索・・・"
        return bar
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "見つかりませんでした"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 18, weight: .regular)
        return label
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: " ← ", style: .done, target: self, action: #selector(cancelButton))
        navigationController?.navigationBar.tintColor = .label
        
        tableView.delegate = self
        tableView.dataSource = self
        searchUniBar.delegate = self
//        navigationController?.navigationBar.topItem?.titleView = searchUniBar
        
        view.addSubview(noResultsLabel)
        view.addSubview(searchUniBar)
        view.addSubview(tableView)
        
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let safeY = view.safeAreaInsets.top
        noResultsLabel.frame = CGRect(x: view.width/4,
                                      y: (view.height-100)/2,
                                      width: view.width/2,
                                      height: 100)
        searchUniBar.frame = CGRect(x: 0,
                                    y: safeY,
                                    width: view.width,
                                    height: 50)
        searchUniBar.isHidden = false
        searchUniBar.searchTextField.backgroundColor = .secondarySystemBackground
        tableView.frame = CGRect(x: 0,
                                 y: safeY + 55,
                                 width: view.width,
                                 height: view.height - 50 - safeY)
    }
    
    @objc private func cancelButton() {
        navigationController?.popViewController(animated: true)
    }
    
    
}



extension SelectUniveristyViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text,
            !text.replacingOccurrences(of: " ", with: "").isEmpty else {
                return
        }
        
        searchBar.resignFirstResponder()
        
        results.removeAll()
        filterUsers(with: text)
    }
    
    
    func filterUsers(with term: String) {
        // updata the UI
        
        let resultsFriends: [String] = uniList.filter({
            return $0.contains(term.lowercased())
        }).compactMap ({
            return $0
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
            tableView.reloadData()
        }
        else {
            didSearch = true
            noResultsLabel.isHidden = true
            results.removeAll()
            filterUsers(with: searchText)
            tableView.reloadData()
        }
    }
    
    
}


extension SelectUniveristyViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if didSearch == true {
            return results.count
        }
        else {
            return uniList.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectUniveristyTableViewCell", for: indexPath) as! SelectUniveristyTableViewCell
        if didSearch == true {
            let model = results[indexPath.row]
            cell.configure(uni: model)
        }
        else {
            let model = uniList[indexPath.row]
            cell.configure(uni: model)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if didSearch == true {
            let selectedUniveristy = results[indexPath.row]
            if selectedUniveristy == "五十音順" { return }
            UserDefaults.standard.setValue(selectedUniveristy, forKey: "uni")
            
            let storyboard: UIStoryboard = UIStoryboard(name: "RegisterNameAge", bundle: nil)
            let selectFacDepVC = storyboard.instantiateViewController(withIdentifier: "SelectFacDepViewController") as! SelectFacDepViewController
            selectFacDepVC.uni = selectedUniveristy
            navigationController?.pushViewController(selectFacDepVC, animated: true)
        }
        else {
            let selectedUniveristy = uniList[indexPath.row]
            if selectedUniveristy == "五十音順" { return }
            UserDefaults.standard.setValue(selectedUniveristy, forKey: "uni")
            
            let storyboard: UIStoryboard = UIStoryboard(name: "RegisterNameAge", bundle: nil)
            let selectFacDepVC = storyboard.instantiateViewController(withIdentifier: "SelectFacDepViewController") as! SelectFacDepViewController
            selectFacDepVC.uni = selectedUniveristy
            navigationController?.pushViewController(selectFacDepVC, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
}
