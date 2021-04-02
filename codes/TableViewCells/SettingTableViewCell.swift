//
//  SettingTableViewCell.swift
//  Match
//
//  on 2021/01/30.
//

import UIKit

class SettingTableViewCell: UITableViewCell {

    static let identifier = "SettingTableViewCell"
    
    
    private let settingNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        return label
    }()
    
    public let switchButton: UISwitch = {
        let switchButton = UISwitch()
        return switchButton
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(settingNameLabel)
        contentView.addSubview(switchButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        settingNameLabel.frame = CGRect(x: 20, y: 10, width: contentView.width - 120, height: 30)
        switchButton.frame = CGRect(x: contentView.width - 90, y: 10, width: 60, height: 30)
    }
    
    public func configure(with model: Setting) {
        if model.info == "reaction" {
            settingNameLabel.text = "いいねなどのリアクション"
            if model.on == true {
                switchButton.isOn = true
            }
            else {
                switchButton.isOn = false
            }
        }
        else if model.info == "ashiato" {
            settingNameLabel.text = "足あとの通知"
            if model.on == true {
                switchButton.isOn = true
            }
            else {
                switchButton.isOn = false
            }
        }
        else if model.info == "chat" {
            settingNameLabel.text = "やりとりの通知"
            if model.on == true {
                switchButton.isOn = true
            }
            else {
                switchButton.isOn = false
            }
        }
        else if model.info == "blog" {
            settingNameLabel.text = "新しいブログの通知"
            if model.on == true {
                switchButton.isOn = true
            }
            else {
                switchButton.isOn = false
            }
        }
    }
    
}
