//
//  NotificationTableViewCell.swift
//  Match
//
//  on 2020/12/29.
//

import UIKit

class NotificationTableViewCell: UITableViewCell {
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var friendProfile1: UIImageView!
    @IBOutlet weak var friendProfile2: UIImageView!
    @IBOutlet weak var friendProfile3: UIImageView!
    @IBOutlet weak var friendProfile4: UIImageView!
    @IBOutlet weak var ellipsis: UIButton!
    @IBOutlet weak var friendNameLabel: UILabel!
    @IBOutlet weak var friendExplaneLabel: UILabel!
    @IBOutlet weak var replayContainer: UIStackView!
    @IBOutlet weak var postTextView: UITextView!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    
    public let profileButton1: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.layer.cornerRadius = 20
        return button
    }()
    public let profileButton2: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.layer.cornerRadius = 20
        return button
    }()
    public let profileButton3: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.layer.cornerRadius = 20
        return button
    }()
    public let profileButton4: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.layer.cornerRadius = 20
        return button
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        
        friendProfile1.layer.cornerRadius = 20
        friendProfile1.layer.borderWidth = 1
        friendProfile1.contentMode = .scaleAspectFill
        friendProfile1.layer.masksToBounds = true
        friendProfile1.layer.borderColor = UIColor.systemGray3.cgColor
        friendProfile1.tintColor = .gray
        friendProfile2.layer.cornerRadius = 20
        friendProfile2.layer.borderWidth = 1
        friendProfile2.contentMode = .scaleAspectFill
        friendProfile2.layer.masksToBounds = true
        friendProfile2.layer.borderColor = UIColor.systemGray3.cgColor
        friendProfile2.tintColor = .gray
        friendProfile3.layer.cornerRadius = 20
        friendProfile3.layer.borderWidth = 1
        friendProfile3.contentMode = .scaleAspectFill
        friendProfile3.layer.masksToBounds = true
        friendProfile3.layer.borderColor = UIColor.systemGray3.cgColor
        friendProfile3.tintColor = .gray
        friendProfile4.layer.cornerRadius = 20
        friendProfile4.layer.borderWidth = 1
        friendProfile4.contentMode = .scaleAspectFill
        friendProfile4.layer.masksToBounds = true
        friendProfile4.layer.borderColor = UIColor.systemGray3.cgColor
        friendProfile4.tintColor = .gray
        
        contentView.addSubview(profileButton1)
        contentView.addSubview(profileButton2)
        contentView.addSubview(profileButton3)
        contentView.addSubview(profileButton4)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        profileButton1.frame = CGRect(x: 70, y: 10, width: 40, height: 40)
        profileButton2.frame = CGRect(x: 120, y: 10, width: 40, height: 40)
        profileButton3.frame = CGRect(x: 170, y: 10, width: 40, height: 40)
        profileButton4.frame = CGRect(x: 220, y: 10, width: 40, height: 40)
    }
    
    public func configure(model: NotificationModel) {
        
        if model.model == "good" {
            logoImageView.image = UIImage(systemName: "heart.fill")
            logoImageView.tintColor = .systemPink
            friendProfile1.isHidden = true
            friendProfile2.isHidden = true
            friendProfile3.isHidden = true
            friendProfile4.isHidden = true
            profileButton2.isHidden = true
            profileButton3.isHidden = true
            profileButton4.isHidden = true
            ellipsis.isHidden = true
            postTextView.text = model.textView
            postTextView.sizeToFit()
            textViewHeight.constant = postTextView.height
            replayContainer.isHidden = true
            
            var count = model.friendEmail.count
            DatabaseManager.shared.fetchUserName(email: model.friendEmail[0]) { [weak self](result) in
                switch result {
                case .success(let name):
                    self?.friendNameLabel.text = name
                case .failure(_):
                    print("notification cell error in good")
                }
            }
            if count == 1 {
                friendExplaneLabel.text = "さんがいいねしました。"
            }
            else if count >= 5 {
                ellipsis.isHidden = false
                count = 4
            }
            else  {
                friendExplaneLabel.text = "さん他がいいねしました。"
            }
            
            var i = 0
            var flag = 1
            while i < count {
                let path = "profile_picture/\(model.friendEmail[i])-profile.png"
                StorageManager.shared.getDownloadURL(for: path, completion: { [weak self]result in
                    switch result {
                    case .success(let url):
                        DispatchQueue.main.async {
                            if flag == 1 {
                                self?.friendProfile1.sd_setImage(with: url, completed: nil)
                                self?.friendProfile1.isHidden = false
                                flag += 1
                            }
                            else if flag == 2 {
                                self?.friendProfile2.sd_setImage(with: url, completed: nil)
                                self?.friendProfile2.isHidden = false
                                self?.profileButton2.isHidden = false
                                flag += 1
                            }
                            else if flag == 3 {
                                self?.friendProfile3.sd_setImage(with: url, completed: nil)
                                self?.friendProfile3.isHidden = false
                                self?.profileButton3.isHidden = false
                                flag += 1
                            }
                            else if flag == 4 {
                                self?.friendProfile4.sd_setImage(with: url, completed: nil)
                                self?.friendProfile4.isHidden = false
                                self?.profileButton4.isHidden = false
                            }
                        }
                    case .failure(_):
                        if flag == 1 {
                            self?.friendProfile1.image = UIImage(systemName: "person.circle")
                            self?.friendProfile1.isHidden = false
                            flag += 1
                        }
                        else if flag == 2 {
                            self?.friendProfile2.image = UIImage(systemName: "person.circle")
                            self?.friendProfile2.isHidden = false
                            self?.profileButton2.isHidden = false
                            flag += 1
                        }
                        else if flag == 3 {
                            self?.friendProfile3.image = UIImage(systemName: "person.circle")
                            self?.friendProfile3.isHidden = false
                            self?.profileButton3.isHidden = false
                            flag += 1
                        }
                        else if flag == 4 {
                            self?.friendProfile4.image = UIImage(systemName: "person.circle")
                            self?.friendProfile4.isHidden = false
                            self?.profileButton4.isHidden = false
                        }
                    }
                })
                i += 1
            }
            
        }
        else if model.model == "repeat" {
            logoImageView.image = UIImage(systemName: "repeat")
            logoImageView.tintColor = .systemGreen
            friendExplaneLabel.text = "さんがリピートしました。"
            postTextView.text = model.textView
            postTextView.sizeToFit()
            textViewHeight.constant = postTextView.height
            friendProfile1.isHidden = true
            
            DatabaseManager.shared.fetchUserName(email: model.friendEmail[0]) { [weak self](result) in
                switch result {
                case .success(let name):
                    self?.friendNameLabel.text = name
                case .failure(_):
                    print("notification cell error in repeat")
                }
            }
            let path = "profile_picture/\(model.friendEmail[0])-profile.png"
            StorageManager.shared.getDownloadURL(for: path, completion: { [weak self]result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        self?.friendProfile1.sd_setImage(with: url, completed: nil)
                        self?.friendProfile1.isHidden = false
                    }
                case .failure(_):
                    self?.friendProfile1.image = UIImage(systemName: "person.circle")
                    self?.friendProfile1.isHidden = false
                }
            })
            friendProfile2.isHidden = true
            friendProfile3.isHidden = true
            friendProfile4.isHidden = true
            profileButton2.isHidden = true
            profileButton3.isHidden = true
            profileButton4.isHidden = true
            ellipsis.isHidden = true
            replayContainer.isHidden = true
        }
        else if model.model == "replay" {
            logoImageView.image = UIImage(systemName: "arrowshape.turn.up.backward")
            logoImageView.tintColor = .label
            friendExplaneLabel.text = "さんがコメントしました。"
            postTextView.text = model.textView
            postTextView.sizeToFit()
            textViewHeight.constant = postTextView.height
            friendProfile1.isHidden = true
            
            DatabaseManager.shared.fetchUserName(email: model.friendEmail[0]) { [weak self](result) in
                switch result {
                case .success(let name):
                    self?.friendNameLabel.text = name
                case .failure(_):
                    print("notification cell error in replay")
                }
            }
            let path = "profile_picture/\(model.friendEmail[0])-profile.png"
            StorageManager.shared.getDownloadURL(for: path, completion: { [weak self]result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        self?.friendProfile1.sd_setImage(with: url, completed: nil)
                        self?.friendProfile1.isHidden = false
                    }
                case .failure(_):
                    self?.friendProfile1.image = UIImage(systemName: "person.circle")
                    self?.friendProfile1.isHidden = false
                }
            })
            friendProfile2.isHidden = true
            friendProfile3.isHidden = true
            friendProfile4.isHidden = true
            profileButton2.isHidden = true
            profileButton3.isHidden = true
            profileButton4.isHidden = true
            ellipsis.isHidden = true
            replayContainer.isHidden = false
        }
        else if model.model == "friend" {
            logoImageView.image = UIImage(systemName: "person")
            logoImageView.tintColor = .link
            friendExplaneLabel.text = "さんがあなたを友達追加しました"
            friendProfile2.isHidden = true
            friendProfile3.isHidden = true
            friendProfile4.isHidden = true
            profileButton2.isHidden = true
            profileButton3.isHidden = true
            profileButton4.isHidden = true
            ellipsis.isHidden = true
            postTextView.isHidden = true
            postTextView.sizeToFit()
            textViewHeight.constant = postTextView.height
            replayContainer.isHidden = true
            
            DatabaseManager.shared.fetchUserName(email: model.friendEmail[0]) { [weak self](result) in
                switch result {
                case .success(let name):
                    self?.friendNameLabel.text = name
                case .failure(_):
                    print("notification cell error in good")
                }
            }
            let path = "profile_picture/\(model.friendEmail[0])-profile.png"
            StorageManager.shared.getDownloadURL(for: path, completion: { [weak self]result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        self?.friendProfile1.sd_setImage(with: url, completed: nil)
                    }
                case .failure(_):
                    self?.friendProfile1.image = UIImage(systemName: "person.circle")
                }
            })
            
        }
    }
    
}
