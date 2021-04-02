//
//  SettingViewController.swift
//  Match
//
//  on 2021/01/07.
//

import UIKit

struct Setting {
    let info: String
    var on: Bool
}

class SettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var settingInfo = [Setting]()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(SettingTableViewCell.self, forCellReuseIdentifier: "SettingTableViewCell")
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "通知設定"
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableHeaderView = createTableHeader()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "戻る",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        navigationController?.navigationBar.tintColor = .label
        
        if let settingLists = UserDefaults.standard.value(forKey: "setting") as? [[String: Any]] {
            var settingList = [Setting]()
            for cell in settingLists {
                guard let info = cell["info"] as? String,
                      let on = cell["on"] as? Bool else {
                    return
                }
                settingList.append(Setting(info: info, on: on))
            }
            settingInfo = settingList
        }
        else {
            settingInfo = [
                Setting(info: "chat", on: true), //0番目はチャット通知で固定
//                Setting(info: "reaction", on: true),
//                Setting(info: "ashiato", on: false),
//                Setting(info: "blog", on: true)
            ]
        }
        tableView.reloadData()
        
        tableView.frame = CGRect(x: 0, y: 0, width: view.width, height: view.height)
        view.addSubview(tableView)
    }
    
    
    
    @objc private func dismissSelf() {
        navigationController?.popViewController(animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingInfo.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingTableViewCell", for: indexPath) as! SettingTableViewCell
        cell.selectionStyle = .none
        let model = settingInfo[indexPath.row]
        cell.configure(with: model)
        
        cell.switchButton.tag = indexPath.row
        cell.switchButton.addTarget(self, action: #selector(tapSwitchButton), for: .valueChanged)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    
    @objc private func tapSwitchButton(_ sender: UISwitch) {
        let indexpath = sender.tag
        if settingInfo[indexpath].on == true {
            // 通知オフに
            settingInfo[indexpath].on = false
            guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                return
            }
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            DatabaseManager.shared.deleteToken(email: safeEmail)
            let data: [[String: Any]] = [
                ["info": settingInfo[0].info, "on": settingInfo[0].on],
//                ["info": settingInfo[1].info, "on": settingInfo[1].on],
//                ["info": settingInfo[2].info, "on": settingInfo[2].on],
//                ["info": settingInfo[3].info, "on": settingInfo[3].on]
            ]
            UserDefaults.standard.setValue(data, forKey: "setting")
        }
        else {
            settingInfo[indexpath].on = true
            let data: [[String: Any]] = [
                ["info": settingInfo[0].info, "on": settingInfo[0].on],
//                ["info": settingInfo[1].info, "on": settingInfo[1].on],
//                ["info": settingInfo[2].info, "on": settingInfo[2].on],
//                ["info": settingInfo[3].info, "on": settingInfo[3].on]
            ]
            UserDefaults.standard.setValue(data, forKey: "setting")
        }
    }
    
    private func createTableHeader() -> UIView {
        let blockImage = UIImageView(frame: CGRect(x: 20, y: 14, width: 22, height: 22))
        blockImage.image = UIImage(systemName: "nosign")
        blockImage.tintColor = .label
        blockImage.isUserInteractionEnabled = true
        let blockLable = UILabel(frame: CGRect(x: 50, y: 10, width: view.width, height: 30))
        blockLable.isUserInteractionEnabled = true
        blockLable.text = "ブロックした人 →"
        let tapBlock = UITapGestureRecognizer(target: self, action: #selector(tapBlockButton))
        blockImage.addGestureRecognizer(tapBlock)
        blockLable.addGestureRecognizer(tapBlock)
        
        let headerView = UIView()
        headerView.addSubview(blockImage)
        headerView.addSubview(blockLable)
        headerView.frame = CGRect(x: 0, y: 0, width: view.width, height: 50)
        
        let topBorder = CALayer()
        topBorder.frame = CGRect(x: 5, y: 49, width: view.width - 10, height: 1.0)
        topBorder.backgroundColor = UIColor.systemGray5.cgColor
        headerView.layer.addSublayer(topBorder)
        
        return headerView
    }
    
    @objc private func tapBlockButton() {
        let vc = BlockListViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}
