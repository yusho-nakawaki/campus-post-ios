//
//  ConversationTableViewCell.swift
//  Study_Match
//
//  on 2020/11/09.
//  Copyright © 2020 yusho. All rights reserved.
//

import UIKit
import SDWebImage

final class ConversationTableViewCell: UITableViewCell {
    
    static let identifier = "ConversationTableViewCell"
    
    private let dateFormatterYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 30
        imageView.layer.masksToBounds = true
        imageView.tintColor = .gray
        return imageView
    }()
    public let userImageButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 30
        button.layer.masksToBounds = true
        return button
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    private let userMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .gray
        label.textAlignment = .right
        return label
    }()
    private let notificationOffImage: UIImageView = {
        let imageview = UIImageView()
        imageview.image = UIImage(systemName: "bell.slash")
        imageview.tintColor = .gray
        return imageview
    }()
    private let isReadButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 5
        button.isHidden = true
        button.backgroundColor = .orange
        return button
    }()
    

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(userImageView)
        contentView.addSubview(userImageButton)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userMessageLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(notificationOffImage)
        contentView.addSubview(isReadButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.frame = CGRect(x: 10,
                                     y: 15,
                                     width: 60,
                                     height: 60)
        userImageButton.frame = CGRect(x: 10,
                                       y: 15,
                                       width: 60,
                                       height: 60)
        userNameLabel.frame = CGRect(x: userImageView.right + 13,
                                     y: 21,
                                     width: contentView.width - 190,
                                     height: 25)
        userMessageLabel.frame = CGRect(x: userImageView.right + 13,
                                        y: userNameLabel.bottom,
                                        width: contentView.width - 90 - 53,
                                        height: (contentView.height - userNameLabel.height - 40))
        dateLabel.frame = CGRect(x: contentView.width - 100,
                                 y: 28,
                                 width: 80,
                                 height: 15)
        isReadButton.frame = CGRect(x: contentView.width - 50,
                                    y: dateLabel.bottom + 10,
                                    width: 10,
                                    height: 10)
        notificationOffImage.frame = CGRect(x: contentView.width - 52,
                                            y: isReadButton.bottom + 5,
                                            width: 15,
                                            height: 15)
    }
    
    public func configure(with model: Conversation) {
        if model.latest_message.text.contains("//firebasestorage.googleapis.com") {
            userMessageLabel.text = "写真が送信されました"
        }
        else {
            userMessageLabel.text = model.latest_message.text
        }
        
        userNameLabel.text = model.partner_name
        if model.latest_message.isRead == false {
            isReadButton.isHidden = false
        }
        else {
            isReadButton.isHidden = true
        }
        
        if model.notification == true {
            notificationOffImage.isHidden = true
        }
        else {
            notificationOffImage.isHidden = false
        }
        
        let nowDate = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        format.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        // date from string
        let cellDate = model.latest_message.date
        
        if let elapsedDays = Calendar.current.dateComponents([.day], from: cellDate, to: nowDate).day {
            if elapsedDays == 0 {
                if let elapsedHour = Calendar.current.dateComponents([.hour], from: cellDate, to: nowDate).hour {
                    if elapsedHour == 0 {
                        if let elapsedMinute = Calendar.current.dateComponents([.minute], from: cellDate, to: nowDate).minute {
                            dateLabel.text = "\(elapsedMinute)分前"
                        }
                    }
                    else {
                        dateLabel.text = "\(elapsedHour)時間前"
                    }
                }
            }
            else {
                if let elapsedYear = Calendar.current.dateComponents([.year], from: cellDate, to: nowDate).year {
                    if elapsedYear == 0 {
                       let formatterMonth = DateFormatter()
                        formatterMonth.dateFormat = "MM"
                        let month = formatterMonth.string(from: model.latest_message.date)
                        if month == "10" || month == "11" || month == "12"{
                            let formatter = DateFormatter()
                            formatter.dateFormat = "MM月dd日"
                            let dateString = formatter.string(from: model.latest_message.date)
                            dateLabel.text = dateString
                        }
                        else {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "M月dd日"
                            let dateString = formatter.string(from: model.latest_message.date)
                            dateLabel.text = dateString
                        }
                    }
                    else {
                        let dateString = dateFormatterYear.string(from: model.latest_message.date)
                        dateLabel.text = dateString
                    }
                }
            }
        }
        
        
        let path = "profile_picture/\(model.partner_email)-profile.png"
        StorageManager.shared.getDownloadURL(for: path, completion: { [weak self]result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(_):
                self?.userImageView.image = UIImage(systemName: "person.circle")
            }
        })
    }

}
