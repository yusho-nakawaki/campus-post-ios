//
//  ReplayForCellTableViewCell.swift
//  BulletinBoard
//
//  on 2020/12/02.
//

import UIKit
import SDWebImage

// Replayのセルじゃないよ。remessageの時のBullutinBoardCellのtableViewだよ。
class ReplayForCellTableViewCell: UITableViewCell {
    
    public var remessageOrTask = 0 // 0がremessage, 1がtask

    
    // MARK: - replayForCell
    @IBOutlet weak var remessageAllContainer: UIView!
    @IBOutlet weak var remessageImageView: UIImageView!
    @IBOutlet weak var remessageNameLabel: UILabel!
    @IBOutlet weak var remessageTimeLabel: UILabel!
    @IBOutlet weak var remessageTextView: UITextView!
    @IBOutlet weak var remessageImageContainer: UIStackView!
    @IBOutlet weak var photo1: UIImageView!
    @IBOutlet weak var photo2: UIImageView!
    @IBOutlet weak var photo3: UIImageView!
    @IBOutlet weak var photo4: UIImageView!
    @IBOutlet weak var photo1Height: NSLayoutConstraint!
    @IBOutlet weak var photo2Height: NSLayoutConstraint!
    @IBOutlet weak var photo3Height: NSLayoutConstraint!
    @IBOutlet weak var photo4Height: NSLayoutConstraint!
    
    
    // MARK: - Share Task
    @IBOutlet weak var shareTaskAllContainer: UIView!
    @IBOutlet weak var taskNameTextView: UITextView!
    @IBOutlet weak var taskNameHeight: NSLayoutConstraint!
    @IBOutlet weak var taskLimitLabel: UILabel!
    @IBOutlet weak var otherContainer: UIView!
    @IBOutlet weak var person1ImageView: UIImageView!
    @IBOutlet weak var person2ImageView: UIImageView!
    @IBOutlet weak var person3ImageView: UIImageView!
    @IBOutlet weak var moreThan3Ellipsis: UIImageView!
    @IBOutlet weak var joinMemberLabel: UILabel!
    
    
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        remessageTextView.textContainerInset = UIEdgeInsets.zero
        remessageTextView.textContainer.lineFragmentPadding = 0
        remessageImageContainer.layer.cornerRadius = 5
        remessageImageView.layer.cornerRadius = 12
        remessageImageView.tintColor = .gray
        
        person1ImageView.layer.cornerRadius = 12
        person2ImageView.layer.cornerRadius = 12
        person3ImageView.layer.cornerRadius = 12
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    public func remessageConfigure(model: Remessage) {
        
        remessageAllContainer.isHidden = false
        shareTaskAllContainer.isHidden = true
        
        let path = "profile_picture/\(model.postEmail)-profile.png"
        StorageManager.shared.getDownloadURL(for: path, completion: { [weak self]result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.remessageImageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(_):
                self?.remessageImageView.image = UIImage(systemName: "person.circle")
            }
        })
        
        remessageNameLabel.text = model.postName
        
        let nowDate = Date()
        // date from string
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let postDate = formatter.date(from: model.postTime) else {
            return
        }
        
        if let elapsedDays = Calendar.current.dateComponents([.day], from: postDate, to: nowDate).day {
            if elapsedDays == 0 {
                if let elapsedHour = Calendar.current.dateComponents([.hour], from: postDate, to: nowDate).hour {
                    if elapsedHour == 0 {
                        if let elapsedMinute = Calendar.current.dateComponents([.minute], from: postDate, to: nowDate).minute {
                            remessageTimeLabel.text = "\(elapsedMinute)分前"
                        }
                    }
                    else {
                        remessageTimeLabel.text = "\(elapsedHour)時間前"
                    }
                }
            }
            else {
                if elapsedDays > 7 {
                    remessageTimeLabel.text = model.postTime
                }
                else {
                    remessageTimeLabel.text = "\(elapsedDays)日前"
                }
            }
        }
        remessageTextView.text = model.postMessage
        remessageTextView.isHidden = false
        if remessageTextView.text == "" {
            remessageTextView.isHidden = true
        }
        
        remessageImageContainer.isHidden = true
        photo1.isHidden = true
        photo2.isHidden = true
        photo3.isHidden = true
        photo4.isHidden = true
        
        
        if model.photoUrl?.count ?? 0 >= 1 {
            remessageImageContainer.isHidden = false
            remessageImageContainer.layer.masksToBounds = true
            remessageImageContainer.layer.borderWidth = 1
            remessageImageContainer.layer.borderColor = UIColor.systemGray3.cgColor
        }
        if model.photoUrl?.count == 1 {
            photo1Height.constant = 110
            
            photo1.isHidden = false
            let image1 = URL(string: model.photoUrl?[0] ?? "")
            if let url = image1 {
                DispatchQueue.main.async { [weak self] in
                    self?.photo1.sd_setImage(with: url, completed: nil)
                }
            }
        }
        if model.photoUrl?.count == 2 {
            photo1.isHidden = false
            photo2.isHidden = false
            photo1Height.constant = 110
            photo2Height.constant = 110
            let image1 = URL(string: model.photoUrl?[0] ?? "")
            let image2 = URL(string: model.photoUrl?[1] ?? "")
            if let url1 = image1, let url2 = image2 {
                DispatchQueue.main.async { [weak self] in
                    self?.photo1.sd_setImage(with: url1, completed: nil)
                    self?.photo2.sd_setImage(with: url2, completed: nil)
                }
            }
        }
        if model.photoUrl?.count == 3 {
            photo1.isHidden = false
            photo2.isHidden = false
            photo3.isHidden = false
            photo1Height.constant = 80
            photo2Height.constant = 80
            photo3Height.constant = 80
            let image1 = URL(string: model.photoUrl?[0] ?? "")
            let image2 = URL(string: model.photoUrl?[1] ?? "")
            let image3 = URL(string: model.photoUrl?[2] ?? "")
            if let url1 = image1, let url2 = image2, let url3 = image3 {
                DispatchQueue.main.async { [weak self] in
                    self?.photo1.sd_setImage(with: url1, completed: nil)
                    self?.photo2.sd_setImage(with: url2, completed: nil)
                    self?.photo3.sd_setImage(with: url3, completed: nil)
                }
            }
        }
        if model.photoUrl?.count == 4 {
            photo1.isHidden = false
            photo2.isHidden = false
            photo3.isHidden = false
            photo4.isHidden = false
            photo1Height.constant = 60
            photo2Height.constant = 60
            photo3Height.constant = 60
            photo4Height.constant = 60
            let image1 = URL(string: model.photoUrl?[0] ?? "")
            let image2 = URL(string: model.photoUrl?[1] ?? "")
            let image3 = URL(string: model.photoUrl?[2] ?? "")
            let image4 = URL(string: model.photoUrl?[3] ?? "")
            if let url1 = image1, let url2 = image2, let url3 = image3, let url4 = image4 {
                DispatchQueue.main.async { [weak self] in
                    self?.photo1.sd_setImage(with: url1, completed: nil)
                    self?.photo2.sd_setImage(with: url2, completed: nil)
                    self?.photo3.sd_setImage(with: url3, completed: nil)
                    self?.photo4.sd_setImage(with: url4, completed: nil)
                }
            }
        }
    }
    
    
    
    public func taskConfigure(model: BullutinTask) {
        
        remessageAllContainer.isHidden = true
        shareTaskAllContainer.isHidden = false
        
        taskNameTextView.text = model.taskName
        taskNameTextView.sizeToFit()
        let textHeight = taskNameTextView.height
        taskNameHeight.constant = textHeight
        
        taskLimitLabel.text = model.taskLimit
        joinMemberLabel.text = "\(model.memberCount)人が参加中"
        
        
        if model.memberCount == 1 {
            let path = "profile_picture/\(model.makedEmail)-profile.png"
            StorageManager.shared.getDownloadURL(for: path, completion: { [weak self]result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        self?.person1ImageView.sd_setImage(with: url, completed: nil)
                        self?.person1ImageView.isHidden = false
                    }
                case .failure(_):
                    self?.person1ImageView.image = UIImage(systemName: "person.circle")
                }
            })
            person2ImageView.isHidden = true
            person3ImageView.isHidden = true
            moreThan3Ellipsis.isHidden = false
            joinMemberLabel.transform = CGAffineTransform(translationX: -24, y: 0)
        }
        if model.memberCount == 2 {
            let path1 = "profile_picture/\(model.makedEmail)-profile.png"
            StorageManager.shared.getDownloadURL(for: path1, completion: { [weak self]result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        self?.person1ImageView.sd_setImage(with: url, completed: nil)
                        self?.person1ImageView.isHidden = false
                    }
                case .failure(_):
                    self?.person1ImageView.image = UIImage(systemName: "person.circle")
                }
            })
            var path2Email = ""
            if model.gettingMember.count == 2 { path2Email = model.gettingMember[1] }
            else if model.doneMember.count == 1 { path2Email = model.doneMember[0] }
            else if model.doneMember.count == 2 { path2Email = model.doneMember[1] }
            else if model.gettingMember.count == 1 { path2Email = model.gettingMember[0] }
            let path2 = "profile_picture/\(path2Email)-profile.png"
            StorageManager.shared.getDownloadURL(for: path2, completion: { [weak self]result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        self?.person2ImageView.sd_setImage(with: url, completed: nil)
                        self?.person2ImageView.isHidden = false
                    }
                case .failure(_):
                    self?.person1ImageView.image = UIImage(systemName: "person.circle")
                }
            })
            
            person3ImageView.isHidden = true
            moreThan3Ellipsis.isHidden = false
            joinMemberLabel.transform = CGAffineTransform(translationX: 12, y: 0)
        }
        if model.memberCount == 3 {
            let path1 = "profile_picture/\(model.makedEmail)-profile.png"
            StorageManager.shared.getDownloadURL(for: path1, completion: { [weak self]result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        self?.person1ImageView.sd_setImage(with: url, completed: nil)
                        self?.person1ImageView.isHidden = false
                    }
                case .failure(_):
                    self?.person1ImageView.image = UIImage(systemName: "person.circle")
                }
            })
            
            var path2Email = ""
            if model.gettingMember.count == 2 { path2Email = model.gettingMember[1] }
            else if model.doneMember.count == 1 { path2Email = model.doneMember[0] }
            else if model.doneMember.count == 2 { path2Email = model.doneMember[1] }
            else if model.gettingMember.count == 1 { path2Email = model.gettingMember[0] }
            let path2 = "profile_picture/\(path2Email)-profile.png"
            StorageManager.shared.getDownloadURL(for: path2, completion: { [weak self]result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        self?.person2ImageView.sd_setImage(with: url, completed: nil)
                        self?.person2ImageView.isHidden = false
                    }
                case .failure(_):
                    self?.person1ImageView.image = UIImage(systemName: "person.circle")
                }
            })
            
            var path3Email = ""
            if model.gettingMember.count == 3 { path3Email = model.gettingMember[2] }
            else if model.doneMember.count == 2 { path3Email = model.doneMember[1] }
            else if model.doneMember.count == 3 { path3Email = model.doneMember[2] }
            else if model.doneMember.count == 1 { path3Email = model.doneMember[0] }
            else if model.gettingMember.count == 2 { path3Email = model.doneMember[1] }
            let path3 = "profile_picture/\(path3Email)-profile.png"
            StorageManager.shared.getDownloadURL(for: path3, completion: { [weak self]result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        self?.person3ImageView.sd_setImage(with: url, completed: nil)
                        self?.person3ImageView.isHidden = false
                    }
                case .failure(_):
                    self?.person1ImageView.image = UIImage(systemName: "person.circle")
                }
            })
            moreThan3Ellipsis.isHidden = false
        }
        if model.memberCount >= 4 {
            let path1 = "profile_picture/\(model.makedEmail)-profile.png"
            StorageManager.shared.getDownloadURL(for: path1, completion: { [weak self]result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        self?.person1ImageView.sd_setImage(with: url, completed: nil)
                        self?.person1ImageView.isHidden = false
                    }
                case .failure(_):
                    self?.person1ImageView.image = UIImage(systemName: "person.circle")
                }
            })
            
            var path2Email = ""
            if model.gettingMember.count >= 2 { path2Email = model.gettingMember[1] }
            else if model.doneMember.count >= 2 { path2Email = model.doneMember[1] }
            else if model.doneMember.count == 1 { path2Email = model.doneMember[0] }
            else if model.gettingMember.count == 1 { path2Email = model.gettingMember[0] }
            let path2 = "profile_picture/\(path2Email)-profile.png"
            StorageManager.shared.getDownloadURL(for: path2, completion: { [weak self]result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        self?.person2ImageView.sd_setImage(with: url, completed: nil)
                        self?.person2ImageView.isHidden = false
                    }
                case .failure(_):
                    self?.person1ImageView.image = UIImage(systemName: "person.circle")
                }
            })
            
            var path3Email = ""
            if model.gettingMember.count >= 3 { path3Email = model.gettingMember[2] }
            else if model.doneMember.count >= 3 { path3Email = model.doneMember[2] }
            else if model.doneMember.count == 2 { path3Email = model.doneMember[1] }
            else if model.doneMember.count == 1 { path3Email = model.doneMember[0] }
            else if model.gettingMember.count == 2 { path3Email = model.doneMember[1] }
            let path3 = "profile_picture/\(path3Email)-profile.png"
            StorageManager.shared.getDownloadURL(for: path3, completion: { [weak self]result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        self?.person3ImageView.sd_setImage(with: url, completed: nil)
                        self?.person3ImageView.isHidden = false
                    }
                case .failure(_):
                    self?.person1ImageView.image = UIImage(systemName: "person.circle")
                }
            })
            moreThan3Ellipsis.isHidden = false
        }
    }
    
    
    
}
