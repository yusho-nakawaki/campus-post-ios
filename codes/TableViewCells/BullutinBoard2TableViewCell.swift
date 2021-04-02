//
//  BullutinBoard2TableViewCell.swift
//  BulletinBoard
//
//  on 2020/11/27.
//

import UIKit
import SDWebImage

class BullutinBoard2TableViewCell: UITableViewCell, UITextViewDelegate {
    
    
    private var repeatPost = Remessage(parentPostId: "", postMessage: "", postEmail: "", postName: "", postTime: "", good: 0, goodList: ["0_nil"], remessage: 0, remessagePostArray: ["0_nil"], isRemessage: nil, comment: 0, isComment: nil, photoUrl: nil)
    private var repeatTask = BullutinTask(taskId: "", taskName: "", taskLimit: "", timeSchedule: "", documentPath: "", memberCount: 0, makedEmail: "", doneMember: [], gettingMember: [], wantToTalkMember: [])
    public var isRepeat = false
    public var isTask = false
    public var bbCellId: String?
    public var whichCell = 0 // 0がCommunityVCで表示されるcell, 1がcomment用
    
    
    @IBOutlet weak var userImageButton: UIButton!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userPostTimeLabel: UILabel!
    @IBOutlet weak var nameAndTextViewMargin: NSLayoutConstraint!
    @IBOutlet weak var messageTextView: UITextView!
    
    @IBOutlet weak var replayButton: UIButton!
    @IBOutlet weak var replayNumberButton: UIButton!
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var repeatNumberButton: UIButton!
    @IBOutlet weak var goodButton: UIButton!
    @IBOutlet weak var goodNumberButton: UIButton!
    @IBOutlet weak var otherMenuButton: UIButton!
    
    
    @IBOutlet weak var imageContainer: UIStackView!
    @IBOutlet weak var postImage1: UIImageView!
    @IBOutlet weak var postImage2: UIImageView!
    @IBOutlet weak var postImage3: UIImageView!
    @IBOutlet weak var postImage4: UIImageView!
    
    @IBOutlet weak var image1Height: NSLayoutConstraint!
    @IBOutlet weak var image2Height: NSLayoutConstraint!
    @IBOutlet weak var image3Height: NSLayoutConstraint!
    @IBOutlet weak var image4Height: NSLayoutConstraint!
    @IBOutlet weak var imageContainerMerginLeft: NSLayoutConstraint!
    @IBOutlet weak var imageContainerMerginRight: NSLayoutConstraint!
    
    @IBOutlet weak var replayContainer: UIStackView!
    @IBOutlet weak var replayHeight: NSLayoutConstraint!
    @IBOutlet weak var toReplayName: UILabel!
    @IBOutlet weak var imageButtonMarginLeft: NSLayoutConstraint!
    @IBOutlet weak var imageButtonMarginHeigth: NSLayoutConstraint!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    @IBOutlet weak var imageWeight: NSLayoutConstraint!
    @IBOutlet weak var replayContainerRight: NSLayoutConstraint!
    
    @IBOutlet weak var repeatTableView: UITableView!
    @IBOutlet weak var repeatTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var repeatTableViewButton: UIButton!
    @IBOutlet weak var repeatTableViewButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var buttonContainer: UIStackView!
    
    private let imageViewForUserPicture: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.image = UIImage(systemName: "person.circle")
        return imageView
    }()
  
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        setUp()
        setUpRepeat()
        contentView.addSubview(imageViewForUserPicture)

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if whichCell == 0 {
            imageViewForUserPicture.frame = CGRect(x: 12,
                                                   y: 12,
                                                   width: 52,
                                                   height: 52)
            imageViewForUserPicture.layer.cornerRadius = 26
        }
        else if whichCell == 1 {
            imageViewForUserPicture.frame = CGRect(x: 67,
                                                   y: 45,
                                                   width: 40,
                                                   height: 40)
            imageViewForUserPicture.layer.cornerRadius = 20
            imageButtonMarginLeft.constant = 54
            imageButtonMarginHeigth.constant = 47
        }
        else if whichCell == 2 {
            imageViewForUserPicture.frame = CGRect(x: 12,
                                                   y: 47,
                                                   width: 52,
                                                   height: 52)
            imageViewForUserPicture.layer.cornerRadius = 26
        }
        
        
        imageViewForUserPicture.layer.borderWidth = 1
        imageViewForUserPicture.layer.borderColor = UIColor.systemGray5.cgColor
        imageViewForUserPicture.tintColor = .gray
        
    }
    
    
    private func setUp() {
        imageContainer.layer.borderColor = UIColor.lightGray.cgColor
        imageContainer.layer.cornerRadius = 5
        
        messageTextView.textContainerInset = UIEdgeInsets.zero
        messageTextView.textContainer.lineFragmentPadding = 0
        
        imageButtonMarginHeigth.constant = 12
        replayContainer.isHidden = true
        replayHeight.constant = 0
        userImageButton.contentHorizontalAlignment = .fill
        userImageButton.contentVerticalAlignment = .fill
        userImageButton.layer.masksToBounds = true
        userImageButton.layer.cornerRadius = 26
    }
    
    private func setUpRepeat() {
        repeatTableView.register(UINib(nibName: "BullutinCellTableViewCell", bundle: nil), forCellReuseIdentifier: "ReplayForCellTableViewCell")
        repeatTableView.delegate = self
        repeatTableView.dataSource = self
        
        repeatTableView.layer.borderWidth = 1
        repeatTableView.layer.borderColor = UIColor.systemGray3.cgColor
        repeatTableView.layer.cornerRadius = 10
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    
     
    public func configure(model: Post) {
        bbCellId = model.postId
        userNameLabel.text = model.postName
        
        let nowDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let postDate = formatter.date(from: model.postTime) ?? nowDate
        
        if let elapsedDays = Calendar.current.dateComponents([.day], from: postDate, to: nowDate).day {
            if elapsedDays == 0 {
                if let elapsedHour = Calendar.current.dateComponents([.hour], from: postDate, to: nowDate).hour {
                    if elapsedHour == 0 {
                        if let elapsedMinute = Calendar.current.dateComponents([.minute], from: postDate, to: nowDate).minute {
                            userPostTimeLabel.text = "\(elapsedMinute)分前"
                        }
                    }
                    else {
                        userPostTimeLabel.text = "\(elapsedHour)時間前"
                    }
                }
            }
            else {
                if elapsedDays > 7 {
                    userPostTimeLabel.text = model.postTime
                }
                else {
                    userPostTimeLabel.text = "\(elapsedDays)日前"
                }
            }
        }
        
        messageTextView.text = model.postMessage
        messageTextView.isHidden = false
        if messageTextView.text == "" {
            messageTextView.isHidden = true
        }
        
        
        if model.good == 0 {
            goodNumberButton.setTitle(" ", for: .normal)
        } else {
            goodNumberButton.setTitle("\(model.good)", for: .normal)
        }
        if model.comment == 0 {
            replayNumberButton.setTitle(" ", for: .normal)
        } else {
            replayNumberButton.setTitle("\(model.comment)", for: .normal)
        }
        if model.remessage == 0 {
            repeatNumberButton.setTitle(" ", for: .normal)
        } else {
            repeatNumberButton.setTitle("\(model.remessage)", for: .normal)
        }
        
        let path = "profile_picture/\(model.postEmail)-profile.png"
        StorageManager.shared.getDownloadURL(for: path, completion: { [weak self]result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.imageViewForUserPicture.sd_setImage(with: url, completed: nil)
                }
            case .failure(_):
                self?.imageViewForUserPicture.image = UIImage(systemName: "person.circle")
            }
        })
        
        
        postImage1.isHidden = true
        postImage2.isHidden = true
        postImage3.isHidden = true
        postImage4.isHidden = true
        imageContainer.layer.borderWidth = 0
        
        
        if model.photoUrl?.count ?? 0 >= 1 {
            imageContainer.layer.borderWidth = 1
            imageContainer.layer.masksToBounds = true
        }
        if model.photoUrl?.count == 1 {
            image1Height.constant = 180
            postImage1.isHidden = false
            let image1 = URL(string: model.photoUrl?[0] ?? "")
            if let url = image1 {
                DispatchQueue.main.async { [weak self] in
                    self?.postImage1.sd_setImage(with: url, completed: nil)
                }
            }
        }
        if model.photoUrl?.count == 2 {
            postImage1.isHidden = false
            postImage2.isHidden = false
            let image2 = URL(string: model.photoUrl?[1] ?? "")
            let image1 = URL(string: model.photoUrl?[0] ?? "")
            if let url1 = image1, let url2 = image2 {
                DispatchQueue.main.async { [weak self] in
                    self?.postImage1.sd_setImage(with: url1, completed: nil)
                    self?.postImage2.sd_setImage(with: url2, completed: nil)
                }
            }
            image1Height.constant = 150
            image2Height.constant = 150
        }
        if model.photoUrl?.count == 3 {
            postImage1.isHidden = false
            postImage2.isHidden = false
            postImage3.isHidden = false
            let image3 = URL(string: model.photoUrl?[2] ?? "")
            let image2 = URL(string: model.photoUrl?[1] ?? "")
            let image1 = URL(string: model.photoUrl?[0] ?? "")
            if let url1 = image1, let url2 = image2, let url3 = image3 {
                DispatchQueue.main.async { [weak self] in
                    self?.postImage1.sd_setImage(with: url1, completed: nil)
                    self?.postImage2.sd_setImage(with: url2, completed: nil)
                    self?.postImage3.sd_setImage(with: url3, completed: nil)
                }
            }
            image1Height.constant = 100
            image2Height.constant = 100
            image3Height.constant = 100
        }
        if model.photoUrl?.count == 4 {
            postImage1.isHidden = false
            postImage2.isHidden = false
            postImage3.isHidden = false
            postImage4.isHidden = false
            let image4 = URL(string: model.photoUrl?[3] ?? "")
            let image3 = URL(string: model.photoUrl?[2] ?? "")
            let image2 = URL(string: model.photoUrl?[1] ?? "")
            let image1 = URL(string: model.photoUrl?[0] ?? "")
            if let url1 = image1, let url2 = image2, let url3 = image3, let url4 = image4 {
                DispatchQueue.main.async { [weak self] in
                    self?.postImage1.sd_setImage(with: url1, completed: nil)
                    self?.postImage2.sd_setImage(with: url2, completed: nil)
                    self?.postImage3.sd_setImage(with: url3, completed: nil)
                    self?.postImage4.sd_setImage(with: url4, completed: nil)
                }
            }
            image1Height.constant = 80
            image2Height.constant = 80
            image3Height.constant = 80
            image4Height.constant = 80
        }
        
        if isRepeat == false {
            repeatTableView.isHidden = true
            repeatTableViewButton.isHidden = true
        }
        else {
            let str = model.isRemessage?.postMessage ?? ""
            let newLine = "\n"
            let charCount = model.isRemessage?.postMessage.lengthOfBytes(using: String.Encoding.shiftJIS) ?? 0
            var newLineCount = 0
            var nextRange = str.startIndex..<str.endIndex //最初は文字列全体から探す
            while let range = str.range(of: newLine, options: .caseInsensitive, range: nextRange) { //.caseInsensitiveで探す方が、lowercaseStringを作ってから探すより普通は早い
                newLineCount += 1
                nextRange = range.upperBound..<str.endIndex
                //見つけた単語の次(range.upperBound)から元の文字列の最後までの範囲で次を探す
            }
            
            if let urlArray = model.isRemessage?.photoUrl {
                let imageCount = urlArray.count
                if imageCount < 3 {
                    repeatTableViewHeight.constant = 150
                    repeatTableViewButtonHeight.constant = 150
                }
                else if imageCount >= 3 && charCount >= 68 {
                    repeatTableViewHeight.constant = 150
                    repeatTableViewButtonHeight.constant = 150
                }
                else if imageCount >= 3  {
                    repeatTableViewHeight.constant = 110
                    repeatTableViewButtonHeight.constant = 110
                }
            }
            else {
                if charCount <= 15 && newLineCount == 0 {
                    repeatTableViewHeight.constant = 60
                    repeatTableViewButtonHeight.constant = 60
                }
                else if charCount <= 40 && newLineCount == 0 {
                    repeatTableViewHeight.constant = 75
                    repeatTableViewButtonHeight.constant = 75
                }
                else if charCount <= 68 || newLineCount == 1 {
                    repeatTableViewHeight.constant = 90
                    repeatTableViewButtonHeight.constant = 90
                }
                else if charCount <= 136,
                        charCount <= 102 && (1 <= newLineCount && newLineCount >= 4) {
                    repeatTableViewHeight.constant = 110
                    repeatTableViewButtonHeight.constant = 110
                }
                else {
                    repeatTableViewHeight.constant = 140
                    repeatTableViewButtonHeight.constant = 140
                }
            }
            
            repeatTableView.isHidden = false
            repeatTableViewButton.isHidden = false
            repeatTableView.separatorStyle = .none
            if let remessage = model.isRemessage {
                repeatPost = remessage
            }
            repeatTableView.reloadData()
        }
        
        // share task
        if isRepeat == false {
            if isTask == false {
                repeatTableView.isHidden = true
                repeatTableViewButton.isHidden = true
            }
            else {
                repeatTableView.isHidden = false
                repeatTableViewButton.isHidden = false
                repeatTableViewButtonHeight.constant = 130
                repeatTableView.separatorStyle = .none
                if let task = model.shareTask {
                    repeatTask = task
                }
                repeatTableView.reloadData()
            }
        }
    }
    
    
    func dateFormatStr(dateString: String) -> DateFormatter {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = dateString
        return dateFormatter
    }
    

}

extension BullutinBoard2TableViewCell: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReplayForCellTableViewCell", for: indexPath) as! ReplayForCellTableViewCell
        cell.selectionStyle = .none
        
        if isRepeat == true {
            cell.remessageConfigure(model: repeatPost)
        }
        if isTask == true {
            cell.taskConfigure(model: repeatTask)
        }
        return cell
        
        
    }
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return repeatTableView.estimatedRowHeight
    }
    
    
}
