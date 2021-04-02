//
//  SearchFriendsTableViewCell.swift
//  Study_Match
//
//  on 2020/11/20.
//  Copyright © 2020 yusho. All rights reserved.
//

import Foundation
import SDWebImage

final class SearchFriendsTableViewCell: UITableViewCell {
    
    static let identifier = "SearchFriendsTableViewCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 30
        imageView.layer.masksToBounds = true
        imageView.tintColor = .gray
        return imageView
    }()
    
    public let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
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
                                     width: 60,
                                     height: 60)
        userNameLabel.frame = CGRect(x: userImageView.right + 15,
                                     y: 26,
                                     width: contentView.width - 80,
                                     height: 30)
    }
    
    public func configureDidSearch(with model: SearchResult) {
        userNameLabel.text = model.name
        
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
    }
    
    public func configure(model: String) {
        
        DatabaseManager.shared.fetchUserName(email: model) { [weak self](result) in
            switch result {
            case .success(let name):
                self?.userNameLabel.text = name
            case .failure(_):
                print("notification cell error in configure name")
            }
        }
        let path = "profile_picture/\(model)-profile.png"
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
