//
//  BasicUserInfo.swift
//  Match
//
//  on 2020/12/15.
//

import UIKit

class BasicUserInfo: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    var safeMyEmail: String
    var myName: String
    public var profilePicture: String?
    
    private var isChange = false
    public var currentInfo = ProfileInfo(name: "", picutre: "", introduction: "", age: "", university: "", faculty: "", department: "", friendCount: "")
    
    public var fromSettingBasicCompletion: ((Bool) -> (Void))?
    
    private var pickerView: UIPickerView = UIPickerView()
    private var active_textfield : UITextField!
    private var current_arr : [String] = []
    
    private let facultyList: [String: [String]] =
        [ "選んでください":["先に大学を選択してください"],
          "早稲田大学": ["政治経済学部","法学部","商学部","国際教育学部","社会科学部","教育学部","文学部","文化構想学部","スポーツ学部","人間科学部","基幹理工学部","創造理工学部","先進理工学部"],
          "慶應義塾大学":["文学部","経済学部","法学部","商学部","医学部","理工学部","総合政策学部","環境情報学部","看護医療学部","薬学部"],
          "上智大学":["神学部","文学部","総合人間科学部","法学部","経済学部","外国語学部","総合グローバル学部","国際教養学部","理工学部"],
          "明治大学":["法学部","商学部","政治経済学部","文学部","理工学部","農学部","経営学部","情報コミュニケーション学部","国際日本学部","総合数理学部"],
          "青山学院大学":["文学部","教育人間科学部","経済学部","法学部","経営学部","国際政治経済学部","総合文化政策学部","理工学部","社会情報学部","地球社会共生学部","コミュニティ人間科学部"],
          "立教大学":["文学部","異文化コミュニケーション学部","経済学部","経営学部","社会学部","法学部","理学部","観光学部","コミュニティ福祉学部","現代心理学部","グローバル リベラルアーツ プログラム"],
          "中央大学":
            ["法学部","経済学部","商学部","理工学部","文学部","総合政策学部","国際経営学部","国際情報学部"],
          "法政大学":["法学部","文学部","経営学部","経済学部","社会学部","国際文化学部","人間環境学部","キャリアデザイン学部","デザイン工学部","グローバル教養学部","現代福祉学部","スポーツ健康学部","情報科学部","理工学部","生命科学部"]
    ]
    
    private let departmentList: [String: [String: [String]]] =
    [
        "選んでください":["先に大学を選択してください": ["先に学部を選んでください"]],
        "早稲田大学": ["政治経済学部": ["","政治学科","経済学科","国際政治経済学科"],
                     "法学部": [""],
                     "商学部": ["","経営トラック","会計トラック","マーケティング・国際ビジネストラック","金融・保険トラック","経済トラック","産業トラック"],
                     "国際教育学部": ["","国際教養学科"],
                     "社会科学部":["","社会科学科"],
                     "教育学部": ["","教育学科","国語国文学科","英語英文学科","社会科","理学科","数学科","複合文化学科"],
                     "文学部": [""],
                     "文化構想学部": ["","文化構想学科"],
                     "スポーツ学部": ["","スポーツ科学科"],
                     "人間科学部": ["","人間環境科学科", "健康福祉科学科", "人間情報科学科"],
                     "基幹理工学部": ["","学系Ⅰ","学系Ⅱ","学系Ⅲ","数学科","応用数理学科","機械科学・航空宇宙学科","電子物理システム学科","情報理工学科","情報通信学科","表現工学科"],
                     "創造理工学部": ["","建築学科","総合機械工学科","経営システム工学科","社会環境工学科","環境資源工学科"],
                     "先進理工学部": ["","物理学科","応用物理学科","化学・生命化学科","応用化学科","生命医科学科","電気・情報生命工学科"]
        ],
        "慶應義塾大学":["文学部": ["","人文社会学科"],
                     "経済学部": ["","経済学科"],
                     "法学部": ["","法律学科", "政治学科"],
                     "商学部": ["","商学科"],
                     "医学部": ["","医学科"],
                     "理工学部": ["","機械工学科","電気情報工学科","応用化学科","物理情報工学科","管理工学科","数理科学科","物理学科","化学科","システムデザイン工学科","情報工学科","生命情報学科"],
                     "総合政策学部": ["","総合政策学科"],
                     "環境情報学部": ["","環境情報学科"],
                     "看護医療学部": ["","看護学科"],
                     "薬学部": ["","薬学科","薬科学科"]
        ],
        "上智大学": ["神学部": ["","神学科"],
                   "文学部": ["","哲学科","史学科","国文学科","英文学科","ドイツ文学科","フランス文学科","新聞学科"],
                   "総合人間科学部": ["","教育学科","心理学科","社会学科","社会福祉学科","看護学科"],
                   "法学部": ["","法律学科","国際関係法学科","地球環境法学科"],
                   "経済学部": ["","経済学科","経営学科"],
                   "外国語学部": ["","英語学科","ドイツ語学科","フランス語学科","イスパニア語学科","ロシア語学科","ポルトガル語学科"],
                   "総合グローバル学部": ["","総合グローバル学科"],
                   "国際教養学部": ["","国際教養学科"],
                   "理工学部": ["","物質生命理工学科","機能創造理工学科","情報理工学科"]
        ],
        "明治大学": ["法学部": ["","法律学科"],
                    "商学部": ["","商学科"],
                    "政治経済学部": ["","政治学科","経済学科","地域行政学科"],
                    "文学部": ["","文学科","史学地理学科","心理社会学科"],
                    "理工学部": ["","電気電子生命学科","機械工学科","機械情報工学科","建築学科","応用化学科","情報科学科","数学科","物理学科"],
                    "農学部": ["","農学科","農芸化学科","生命科学科","食料環境政策学科"],
                    "経営学部": ["","経営学科","会計学科","公共経営学科"],
                    "情報コミュニケーション学部": ["","情報コミュニケーション学科"],
                    "国際日本学部": ["","国際日本学科"],
                    "総合数理学部": ["","現象数理学科","先端メディアサイエンス学科","ネットワークデザイン学科"]
        ],
        "青山学院大学": ["文学部": ["","英米文学科","フランス文学科","日本文学科","史学科","比較芸術学科"],
                      "教育人間科学部": ["","教育学科","心理学科"],
                      "経済学部": ["","経済学科","現代経済デザイン学科"],
                      "法学部": ["","法学科"],
                      "経営学部": ["","経営学科","マーケティング学科"],
                      "国際政治経済学部": ["","国際政治学科","国際経済学科","国際コミュニケーション学科"],
                      "総合文化政策学部": ["","総合文化政策学科"],
                      "理工学部": ["","物理科学科","数理サイエンス学科","化学・生命科学科","電気電子工学科","機械創造工学科","経営システム工学科","情報テクノロジー学科"],
                      "社会情報学部": ["","社会情報学科"],
                      "地球社会共生学部": ["","地球社会共生学科"],
                      "コミュニティ人間科学部": ["","コミュニティ人間科学科"]
        ],
        "立教大学": ["文学部": ["","キリスト教学科","文学科","史学科","教育学科"],
                    "異文化コミュニケーション学部": ["","異文化コミュニケーション学科"],
                    "経済学部": ["","経済学科","経済政策学科","会計ファイナンス学科"],
                    "経営学部": ["","経営学科","国際経営学科"],
                    "社会学部": ["","社会学科","現代文化学科","メディア社会学科"],
                    "法学部": ["","法学科","国際ビジネス法学科","政治学科"],
                    "理学部": ["","数学科","物理学科","化学科","生命理学科"],
                    "観光学部": ["","観光学科","交流文化学科"],
                    "コミュニティ福祉学部": ["","コミュニティ政策学科","福祉学科","スポーツウエルネス学科"],
                    "現代心理学部": ["","心理学科","映像身体学科"],
                    "グローバル リベラルアーツ プログラム": [""]
        ],
        "中央大学": ["法学部": ["","法律学科","国際企業関係法学科","政治学科"],
                   "経済学部": ["","経済学科","経済情報システム学科","国際経済学科","公共・環境経済学科"],
                   "商学部": ["","経営学科","会計学科","商業・貿易学科","金融学科"],
                   "理工学部": ["","数学科","物理学科","都市環境学科","精密機械工学科","電気電子情報通信工学科","応用化学科","ビジネスデータサイエンス学科","情報工学科","生命科学科","人間総合理工学科"],
                   "文学部": ["","国文学専攻","英語文学文化専攻","ドイツ語文学文化専攻","フランス語文学文化専攻","中国言語文化専攻","日本史学専攻","東洋史学専攻","西洋史学専攻","哲学専攻","社会学専攻","社会情報学専攻","教育学専攻","心理学専攻","学びのパスポートプログラム"],
                   "総合政策学部": ["","政策科学科","国際政策文化学科"],
                   "国際経営学部": ["","国際経営学科"],
                   "国際情報学部": ["","国際情報学科"]
        ],
        "法政大学": ["法学部": ["","法律学科","政治学科","国際政治学科"],
                   "文学部": ["","哲学科","日本文学科","英文学科","史学科","地理学科","心理学科"],
                   "経営学部": ["","経営学科","経営戦略学科","市場経営学科"],
                   "経済学部": ["","経済学科","国際経済学科","現代ビジネス学科"],
                   "社会学部": ["","社会政策科学科","社会学科","メディア社会学科"],
                   "国際文化学部": ["","国際文化学科"],
                   "人間環境学部": ["","人間環境学科"],
                   "キャリアデザイン学部": ["","キャリアデザイン学科"],
                   "デザイン工学部": ["","建築学科","都市環境デザイン工学科","システムデザイン学科"],
                   "グローバル教養学部": ["","グローバル教養学科"],
                   "現代福祉学部": ["","福祉コミュニティ学科"],
                   "スポーツ健康学部": ["","スポーツ健康学科"],
                   "情報科学部": ["","コンピュータ科学科","ディジタルメディア学科"],
                   "理工学部": ["","機械工学科","電気電子工学科","応用情報工学科","経営システム工学科","創生科学科"],
                   "生命科学部": ["","生命機能学科","環境応用化学科","応用植物科学科"]
        ]
    
    ]
    
    private let allContainer: UIView = {
        let view = UIView()
        return view
    }()
    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 40
        imageView.tintColor = .gray
        imageView.image = UIImage(systemName: "person.circle")
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.gray.cgColor
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    private let imageViewDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "写真を選択する"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .black
        label.backgroundColor = UIColor(red: 60, green: 60, blue: 60, alpha: 0.7)
        return label
    }()
    private let userNameLabel: UITextField = {
        let label = UITextField()
        label.autocapitalizationType = .none
        label.autocorrectionType = .no
        label.placeholder = "名前"
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        return label
    }()
    private let userIntroduction: UITextView = {
        let text = UITextView()
        text.isEditable = true
        text.isSelectable = true
        text.font = .systemFont(ofSize: 22)
        text.layer.borderWidth = 1
        text.layer.borderColor = UIColor.systemGray4.cgColor
        return text
    }()
    private let introductionPlaceholder: UILabel = {
        let label = UILabel()
        label.text = "自己紹介文: 普段どんなことをしている？"
        label.textColor = .systemGray3
        label.isEnabled = false
        label.font = .systemFont(ofSize: 22)
        label.isUserInteractionEnabled = false
        return label
    }()
    private var scrollUserInfo: UIScrollView = {
        let scroll = UIScrollView()
        return scroll
    }()
    
    // 年齢や大学名のlabel
    private let textField3: CustomTextField = {
        let textField = CustomTextField()
        textField.font = .systemFont(ofSize: 20, weight: .regular)
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()
    private let textField4: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 20, weight: .regular)
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()
    
    
    init(email: String, name: String) {
        self.safeMyEmail = email
        self.myName = name
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "登録", style: .done, target: self, action: #selector(tapRightBarButton))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: " ← ", style: .done, target: self, action: #selector(cancelButton))
        
        
        if let myPicture = UserDefaults.standard.value(forKey: "my_picture") as? Data {
            imageView.image = UIImage(data: myPicture)
            imageViewDescriptionLabel.isHidden = true
        }
        
        userNameLabel.text = currentInfo.name
        userIntroduction.text = currentInfo.introduction
        textField3.text = currentInfo.faculty
        textField4.text = currentInfo.department
        
        if userIntroduction.text != "" {
            introductionPlaceholder.isHidden = true
        }
        

        
        navigationController?.navigationBar.tintColor = .label
        
        
        let gesture = UITapGestureRecognizer(target: self,
                                             action: #selector(didTapUserPic))
        imageView.addGestureRecognizer(gesture)
        
        
        pickerView.delegate = self
        pickerView.dataSource = self
        userIntroduction.delegate = self
        textField3.delegate = self
        textField4.delegate = self
        
        
        // 決定バーの生成
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 45))
        let spacelItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        toolbar.setItems([spacelItem, doneItem], animated: true)
        
        // インプットビュー設定
        textField3.inputView = pickerView
        textField4.inputView = pickerView
        textField3.inputAccessoryView = toolbar
        textField4.inputAccessoryView = toolbar
        
    }
    
    // 決定ボタン押下
    @objc func done() {
        if active_textfield == textField3 {
            textField3.endEditing(true)
            textField3.text = facultyList[currentInfo.university]?[pickerView.selectedRow(inComponent: 0)]
        }
        else if active_textfield == textField4 {
            textField4.endEditing(true)
            guard let text3 = textField3.text else {
                return
            }
            textField4.text = departmentList[currentInfo.university]?[text3]?[pickerView.selectedRow(inComponent: 0)]
        }
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        var viewWidth = view.width
        let safeY = view.safeAreaInsets.top
        if view.width > 700 {
            allContainer.frame = CGRect(x: (view.width - 700)/2,
                                        y: safeY + 20,
                                        width: 700,
                                        height: view.height - 20)
            viewWidth = 700
        }
        else {
            allContainer.frame = CGRect(x: 0,
                                        y: safeY,
                                        width: view.width,
                                        height: view.height)
        }
        
        imageView.frame =  CGRect(x: 15,
                                  y: 15,
                                  width: 80,
                                  height: 80)
        imageViewDescriptionLabel.frame = CGRect(x: 10,
                                                 y: 43,
                                                 width: 100,
                                                 height: 30)
        userNameLabel.frame = CGRect(x: imageView.right + 15,
                                     y: 35,
                                     width: viewWidth - imageView.width - 60,
                                     height: 40)
        userNameLabel.text = myName
        scrollUserInfo.frame = CGRect(x: 20,
                                      y: imageView.bottom + 20,
                                      width: viewWidth - 40,
                                      height: view.height - imageView.height - 50)
        
        
        userIntroduction.frame = CGRect(x: 0,
                                        y: 0,
                                        width: scrollUserInfo.width,
                                        height: 120)
        introductionPlaceholder.frame = CGRect(x: 5,
                                               y: 10,
                                               width: userIntroduction.width - 20,
                                               height: 24)
        scrollUserInfo.addSubview(userIntroduction)
        scrollUserInfo.addSubview(introductionPlaceholder)
        
        //タブのy座標．0から始まり，少しずつずらしていく．
        var originY: CGFloat = userIntroduction.bottom + 20
        var i = 1
        //titlesで定義したタブを1つずつ用意していく
        for _ in 1...2 {
            //タブになるUILabelを作る
            let description = UILabel()
            description.frame = CGRect(x: 0, y: originY, width: 60, height: 40)
            description.font = .systemFont(ofSize: 18)
            if i == 1 { description.text = "学部：" }
            if i == 2 {  description.text = "学科：" }
            
            //scrollViewにぺたっとする
            scrollUserInfo.addSubview(description)
            
            //次のタブのx座標を用意する
            originY += description.height + 20
            i += 1
        }
        
        textField3.frame = CGRect(x: 65, y: 140, width: viewWidth - 140, height: 40)
        textField4.frame = CGRect(x: 65, y: 200, width: viewWidth - 140, height: 40)
        // 線を引く
        let topBorder3 = CALayer()
        let topBorder4 = CALayer()
        topBorder3.frame = CGRect(x: -5, y: 40, width: textField3.width, height: 1.0)
        topBorder4.frame = CGRect(x: -5, y: 40, width: textField4.width, height: 1.0)
        topBorder3.backgroundColor = UIColor.gray.cgColor
        topBorder4.backgroundColor = UIColor.gray.cgColor
        
        //作成したViewに上線を追加
        textField3.layer.addSublayer(topBorder3)
        textField4.layer.addSublayer(topBorder4)
        scrollUserInfo.addSubview(textField3)
        scrollUserInfo.addSubview(textField4)
        
        
        //scrollViewのcontentSizeを，タブ全体のサイズに合わせてあげる
        //最終的なoriginX = タブ全体の横幅 になります
        scrollUserInfo.contentSize = CGSize(width: viewWidth - 40, height: originY + 500)
        
        allContainer.addSubview(imageView)
        allContainer.addSubview(imageViewDescriptionLabel)
        allContainer.addSubview(userNameLabel)
        allContainer.addSubview(scrollUserInfo)
        view.addSubview(allContainer)
        
        
        
    }
    
    @objc private func tapRightBarButton() {
        guard let newName = userNameLabel.text else {
            return
        }
        
        if newName == "" {
            alertUserError(alertMessage: "名前が入力されていません")
            return
        }
        
        guard newName.count < 21 else {
            // １５文字以下が好ましい
            alertUserError(alertMessage: "名前は20文字以下にしてください")
            return
        }
        guard userIntroduction.text.count < 100 else {
            alertUserError(alertMessage: "自己紹介文は100文字以下にしてください")
            return
        }
        
        var introduction = userIntroduction.text ?? ""
        introduction = introduction.trimmingCharacters(in: .newlines)
        let newLine = "\n"
        var newLineCount = 0
        var nextRange = introduction.startIndex..<introduction.endIndex //最初は文字列全体から探す
        while let range = introduction.range(of: newLine, options: .caseInsensitive, range: nextRange) { //.caseInsensitiveで探す方が、lowercaseStringを作ってから探すより普通は早い
            newLineCount += 1
            //見つけた単語の次(range.upperBound)から元の文字列の最後までの範囲で次を探す
            nextRange = range.upperBound ..< introduction.endIndex
        }
        
        
        if newLineCount > 3 {
            alertUserError(alertMessage: "改行は3つまでです")
            return
        }
        
        
        guard let age = UserDefaults.standard.value(forKey: "year") as? String,
              let university = UserDefaults.standard.value(forKey: "uni") as? String else {
            return
        }

        let faculty = textField3.text ?? ""
        let department = textField4.text ?? ""
        let info = ProfileInfo(name: newName, picutre: profilePicture ?? "defalut", introduction: introduction, age: age, university: university, faculty: faculty, department: department, friendCount: currentInfo.friendCount)
        
        // userdefalutsの設定
        if info.faculty == "" { UserDefaults.standard.setValue("none", forKey: "fac") }
        if info.faculty != "" { UserDefaults.standard.setValue(faculty, forKey: "fac") }
        
        if let _ = UserDefaults.standard.value(forKey: "name") as? String { }
        else {
            UserDefaults.standard.set(newName, forKey: "name")
            afterRegister()
        }

        UserDefaults.standard.set(newName, forKey: "name")
        
        var isPreviousInfo: ProfileInfo?
        if currentInfo.university != "" {
            isPreviousInfo = currentInfo
        }
        
        let nav = self.navigationController
        let friendVC = nav?.viewControllers[(nav?.viewControllers.count)!-2] as! FriendProfileViewController
        friendVC.completionChangePicture?(true)
        
        DatabaseManager.shared.insertProfileInfo(myEmail: safeMyEmail, info: info, isPreviousInfo: isPreviousInfo) { [weak self](success) in
            if success == true {
                self?.dismiss(animated: true, completion: nil)
            }
            else {
                self?.alertUserError(alertMessage: "ネットワーク環境を見直して、もう一度試してください。")
                print("error in BasicUserInfo (tapRightBarButton)")
            }
        }
        
    }
    
    @objc private func cancelButton() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func didTapUserPic() {
        presentPhotoPicker()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func alertUserError(alertMessage: String) {
        let alert = UIAlertController(title: "エラー",
                                      message: alertMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true)
    }
    
    // はじめての投稿
    private func afterRegister() {
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let myName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        //はじめての投稿
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        format.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        let dateString = format.string(from: date)
        
        let dayformat = DateFormatter()
        dayformat.dateFormat = "yyMM"
        dayformat.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        let collectionString = dayformat.string(from: date)
        
        let ramdomID = randomString(length: 20)
        
        // ex) 140258_yusho-gmail-com_2210203
        let makePostId = "\(ramdomID)_1\(collectionString)"
        
        
        let post = Post(postId: makePostId,
                        postMessage: "はじめまして\(myName)です！よろしくお願いします！",
                        postEmail: safeMyEmail,
                        postName: myName,
                        postTime: dateString,
                        good: 0, goodList: ["0_nil"], remessage: 0, remessagePostArray: ["0_nil"], isRemessage: nil, comment: 0,
                        photoUrl: nil)
       
        DatabaseManager.shared.insertPostInfo(post: post, dateForCollection: collectionString, whichTable: 1, isAll: false, isUni: true, isFac: true) { [weak self](success) -> (Void) in
            if success == true {
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }
    func randomString(length: Int) -> String {
        let letters: NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        return randomString
    }
    
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        active_textfield = textField

        switch textField {
        case textField3 :
            current_arr = facultyList[currentInfo.university]!
        case textField4:
            if let faculty = textField3.text, !faculty.isEmpty {
                current_arr = departmentList[currentInfo.university]![faculty]!
            }
            else {
                current_arr = departmentList["選んでください"]!["先に大学を選択してください"]!
            }
        default:
            print("default")
        }
        pickerView.reloadAllComponents()

        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if userIntroduction.text == "" {
            introductionPlaceholder.isHidden = false
        }
        else {
            introductionPlaceholder.isHidden = true
        }
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if textField == textField3 {
            textField4.text = ""
        }
    }
    
}



// 年齢や大学などを選択
extension BasicUserInfo: UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return current_arr.count
    }
    
    // ドラムロールの各タイトル
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return current_arr[row]
    }
    
    
    // ドラムロール選択時
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        active_textfield.text = current_arr[row]
    }
    
}



extension BasicUserInfo: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        imageView.image = selectedImage
        
        // ※画像のデータサイズをKBで表示。
        let imageData:Int = NSData(data: selectedImage.pngData()!).count
        let dataToKB = Double(imageData) / 1000.0
        
        //バリデーションを実装
        var data: Data?
        if dataToKB <= 150.0 {
            data = selectedImage.pngData()
        }
        else {
            var resizedImage: UIImage?
            if (dataToKB > 150.0) && (300.0 > dataToKB) {
                resizedImage = selectedImage.resized(withPercentage: 0.9)
            }
            else if (dataToKB >= 300.0) && (600.0 > dataToKB) {
                resizedImage = selectedImage.resized(withPercentage: 0.8)
            }
            else if (dataToKB >= 600.0) && (1200.0 > dataToKB) {
                resizedImage = selectedImage.resized(withPercentage: 0.7)
            }
            else if (dataToKB >= 1200.0) && (2400.0 > dataToKB) {
                resizedImage = selectedImage.resized(withPercentage: 0.6)
            }
            else if (dataToKB >= 2400.0) && (4800.0 > dataToKB) {
                resizedImage = selectedImage.resized(withPercentage: 0.5)
            }
            else if (dataToKB >= 4800.0) && (10000.0 > dataToKB) {
                resizedImage = selectedImage.resized(withPercentage: 0.45)
            }
            else if (dataToKB >= 10000.0) && (20000.0 > dataToKB) {
                resizedImage = selectedImage.resized(withPercentage: 0.4)
            }
            else if (dataToKB >= 20000.0) && (40000.0 > dataToKB) {
                resizedImage = selectedImage.resized(withPercentage: 0.35)
            }
            else if (dataToKB >= 40000.0) && (80000.0 > dataToKB) {
                resizedImage = selectedImage.resized(withPercentage: 0.3)
            }
            else {
                resizedImage = selectedImage.resized(withPercentage: 0.2)
            }
            
            var resizeData: Int = NSData(data: (resizedImage?.pngData())!).count / 1000
            
//            print("original size: \(dataToKB)")
//            print(resizeData)
            
            if resizeData > 200 { // 200KB以下にしたい
                data = resizedImage?.jpegData(compressionQuality: 0.8)
                if NSData(data: data!).count/1000 > 200 {
                    while NSData(data: data!).count/1000 > 200 {
                        resizedImage = resizedImage?.resized(withPercentage: 0.9)
                        data = resizedImage?.jpegData(compressionQuality: 0.8)
                        resizedImage = UIImage(data: data!)
                    }
                }
            }
            else {
                data = resizedImage?.pngData()
            }
        }
        imageViewDescriptionLabel.isHidden = true
        
        guard let rowDate = data else {
            return
        }
        UserDefaults.standard.set(rowDate, forKey: "my_picture")
        let fileName = "\(safeMyEmail)-profile.png"
        
        // なんかたまにバグるので
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        let nav = self.navigationController
        let friendVC = nav?.viewControllers[(nav?.viewControllers.count)!-2] as! FriendProfileViewController
        friendVC.completionChangePicture?(true)
        friendVC.imageView.image = UIImage(data: rowDate)

        StorageManager.shared.uploadProfilePicture(with: rowDate, fileName: fileName) { [weak self]result in
            switch result {
            case .success(let url):
                UserDefaults.standard.set(url, forKey: "profile_picutre_url")
                self?.profilePicture = url
                DatabaseManager.shared.insertProfileToUsers(with: self?.safeMyEmail ?? safeEmail, url: url, completion: { success in
                    if success == true {
                        print("you could insert profileUrl to users node")
                    }
                    else {
                        print("failed to insert profileUrl to users node")
                    }
                })
            case .failure(let error):
                print("storage manager error: \(error)")
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    
}


// 上らへんに斜めの線ができる（適当な線）

// 線を引くための準備 viewdidLoadにこの２つをつける
//let drawView = DrawView(frame: self.view.bounds)
//self.view.addSubview(drawView)


//class DrawView: UIView {
//
//    override init(frame: CGRect) {
//        super.init(frame: frame);
//        self.backgroundColor = UIColor.clear;
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func draw(_ rect: CGRect) {
//
//        // 線
//        let line = UIBezierPath()
//        // 最初の位置
//        line.move(to: CGPoint(x: 100, y: 100))
//        // 次の位置
//        line.addLine(to:CGPoint(x: 300, y: 150))
//        // 終わる
//        line.close()
//        // 線の色
//        UIColor.gray.setStroke()
//        // 線の太さ
//        line.lineWidth = 2.0
//        // 線を塗りつぶす
//        line.stroke()
//    }
//
//}
