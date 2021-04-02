//
//  GoodListTableViewCell.swift
//  Match
//
//  on 2020/12/31.
//

import UIKit
import SDWebImage

class GoodListTableViewCell: UITableViewCell {
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = .gray
        imageView.layer.cornerRadius = 25
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.systemGray2.cgColor
        return imageView
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.text = "名前"
        return label
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.frame = CGRect(x: 20,
                                     y: 10,
                                     width: 50,
                                     height: 50)
        userNameLabel.frame = CGRect(x: userImageView.right + 15,
                                     y: 21,
                                     width: contentView.width - 70,
                                     height: 30)
    }
    
    
    public func configure(email: String) {
        
        DatabaseManager.shared.fetchUserName(email: email) { [weak self](result) in
            switch result {
            case .success(let name):
                self?.userNameLabel.text = name
            case .failure(_):
                print("notification cell error in configure name")
            }
        }
        let path = "profile_picture/\(email)-profile.png"
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
