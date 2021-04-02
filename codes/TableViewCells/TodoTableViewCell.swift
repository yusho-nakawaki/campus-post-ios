//
//  TodoTableViewCell.swift
//  match
//
//  on 2021/03/02.
//

import UIKit

class TodoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var finishButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var todoName: UITextView!
    @IBOutlet weak var todoHeight: NSLayoutConstraint!
    @IBOutlet weak var deadlineLabel: UILabel!
    
    @IBOutlet weak var otherMemberContainer: UIView!
    @IBOutlet weak var otherMemberContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var person1ImageView: UIImageView!
    @IBOutlet weak var ellipsisImageView: UIImageView!
    @IBOutlet weak var memberCountLabel: UILabel!
    
    
    public let checkButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "checkmark"), for: .normal)
        button.tintColor = .darkGray
        return button
    }()
    
    public let bigFinishButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        return button
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        finishButton.layer.cornerRadius = 14
        finishButton.layer.borderWidth = 1
        finishButton.layer.borderColor = UIColor.systemGray5.cgColor
        person1ImageView.layer.cornerRadius = 12
        person1ImageView.layer.masksToBounds = true
        
        finishButton.addSubview(checkButton)
        contentView.addSubview(bigFinishButton)
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        checkButton.frame = CGRect(x: 4,
                                   y: 4,
                                   width: 20,
                                   height: 20)
        bigFinishButton.frame = CGRect(x: 0,
                                       y: 5,
                                       width: 50,
                                       height: 50)
        
    }
    
    
    public func configureTodo(task: Task) {
        
        todoName.text = task.taskName
        todoName.sizeToFit()
        todoHeight.constant = todoName.height
        
        if task.taskLimit != "" {
            deadlineLabel.isHidden = false
            let deadLineDate = dateFormat(stringDate: task.taskLimit)
            let deadLineString = stringFormat(date: deadLineDate!)
            deadlineLabel.text = deadLineString ?? ""
        }
        else {
            deadlineLabel.text = " - "
        }
        
        if task.shareTask.memberCount == 0 {
            otherMemberContainer.isHidden = true
            otherMemberContainerHeight.constant = 0
            otherMemberContainer.frame.size.height = 0
        }
        else if task.shareTask.memberCount == 1 {
            otherMemberContainer.isHidden = false
            let path = "profile_picture/\(task.shareTask.makedEmail)-profile.png"
            StorageManager.shared.getDownloadURL(for: path, completion: { [weak self]result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        self?.person1ImageView.sd_setImage(with: url, completed: nil)
                    }
                case .failure(_):
                    self?.person1ImageView.image = UIImage(systemName: "person.circle")
                }
            })
            ellipsisImageView.isHidden = true
            memberCountLabel.transform = CGAffineTransform(translationX: -15, y: 0)
            memberCountLabel.text = "-人が参加中"
            
            DatabaseManager.shared.fetchTargetTask(task: task) { [weak self](result) -> (Void) in
                switch result {
                case .success(let resultArray):
                    self?.memberCountLabel.text = "\(resultArray.shareTask.memberCount)人が参加中"
                case .failure(let error):
                    print("failed to fetch task: \(error)")
                }
            }
            
        }
        else if task.shareTask.memberCount >= 2 {
            otherMemberContainer.isHidden = false
            let path = "profile_picture/\(task.shareTask.makedEmail)-profile.png"
            StorageManager.shared.getDownloadURL(for: path, completion: { [weak self]result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        self?.person1ImageView.sd_setImage(with: url, completed: nil)
                    }
                case .failure(_):
                    self?.person1ImageView.image = UIImage(systemName: "person.circle")
                }
            })
            ellipsisImageView.isHidden = false
            memberCountLabel.text = "-人が参加中"
            DatabaseManager.shared.fetchTargetTask(task: task) { [weak self](result) -> (Void) in
                switch result {
                case .success(let resultArray):
                    self?.memberCountLabel.text = "\(resultArray.shareTask.memberCount)人が参加中"
                case .failure(let error):
                    print("failed to fetch task: \(error)")
                }
            }
        }
        
    }
    
    
    
    
    // 文字列をDate型に変換する
    func dateFormat(stringDate: String) -> Date! {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "yyyy年M月d日 H:mm"
        let date = dateFormatter.date(from: stringDate)
        return date
    }
    
    func stringFormat(date: Date) -> String! {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "M月d日 H:mm（EEE）"
        let dateString = dateFormatter.string(from: date)
        return dateString
    }

}
