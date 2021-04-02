//
//  NotificationAshiatoCell.swift
//  Match
//
//  on 2021/01/22.
//

import UIKit

class NotificationAshiatoCell: UITableViewCell {
    
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 25
        imageView.layer.masksToBounds = true
        imageView.tintColor = .gray
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    public let userImageButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 25
        button.layer.masksToBounds = true
        return button
    }()
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.text = "さんが足あとをつけました"
        label.numberOfLines = 0
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .gray
        return label
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
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(isReadButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.frame = CGRect(x: 10,
                                     y: 15,
                                     width: 50,
                                     height: 50)
        userImageButton.frame = CGRect(x: 10,
                                       y: 15,
                                       width: 50,
                                       height: 50)
        dateLabel.frame = CGRect(x: 70,
                                 y: 20,
                                 width: contentView.width - 70,
                                 height: 15)
        descriptionLabel.frame = CGRect(x: 70,
                                        y: dateLabel.bottom + 5,
                                        width: contentView.width - 70,
                                        height: 25)
        
        
    }
    
    public func configure(model: AshiatoModel) {
        DatabaseManager.shared.fetchUserName(email: model.email) { [weak self](result) in
            switch result {
            case .success(let name):
                self?.descriptionLabel.text = "\(name)さんが足あとをつけました。"
            case .failure(_):
                print("notification cell error in configure name")
            }
        }
        
        let path = "profile_picture/\(model.email)-profile.png"
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
        
        
        let nowDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let postDate = formatter.date(from: model.date) ?? nowDate
        
        if let elapsedDays = Calendar.current.dateComponents([.day], from: postDate, to: nowDate).day {
            if elapsedDays == 0 {
                if let elapsedHour = Calendar.current.dateComponents([.hour], from: postDate, to: nowDate).hour {
                    if elapsedHour == 0 {
                        if let elapsedMinute = Calendar.current.dateComponents([.minute], from: postDate, to: nowDate).minute {
                            dateLabel.text = "\(elapsedMinute)分前"
                        }
                    }
                    else {
                        dateLabel.text = "\(elapsedHour)時間前"
                    }
                }
            }
            else {
                if elapsedDays > 7 {
                    dateLabel.text = model.date
                }
                else {
                    dateLabel.text = "\(elapsedDays)日前"
                }
            }
        }
    }
    
}
