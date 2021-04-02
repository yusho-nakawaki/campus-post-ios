//
//  replayViewController.swift
//  BulletinBoard
//
//  on 2020/11/29.
//

import UIKit
import JGProgressHUD
import CropViewController

class ReplayViewController: UIViewController, UITextViewDelegate {

    public var replayCompletion: ((Bool) -> Void)?
    public var repeatParentPost: Post?
    public var replayParentPost: Post?
    public var isRepeatMessage = false
    public var isCommentOfCommet: String?
    
    private var replayPhotoDataArray: [Data]?
    private let spinner = JGProgressHUD()
    private var tapPost = false
    
    public var isReplayRepeat: Int? // 0がreplay, 1がrepeat
    public var whichTable = 0 // 0が全体, 1が大学, 2が学部
    
    @IBOutlet weak var replayTableView: UITableView!
    @IBOutlet weak var replayTbleViewHeight: NSLayoutConstraint!
    @IBOutlet weak var SubjectLabel: UIButton!
    @IBOutlet weak var replayToNameLabel: UILabel!
    @IBOutlet weak var replayTextView: UITextView!
    @IBOutlet weak var replayImageContainer: UIStackView!
    
    @IBOutlet weak var replayPhoto1: UIImageView!
    @IBOutlet weak var photo1Cancel: UIButton!
    @IBOutlet weak var replayPhoto2: UIImageView!
    @IBOutlet weak var photo2Cancel: UIButton!
    @IBOutlet weak var replayPhoto3: UIImageView!
    @IBOutlet weak var photo3Cancel: UIButton!
    @IBOutlet weak var replayPhoto4: UIImageView!
    @IBOutlet weak var photo4Cancel: UIButton!
    
    @IBOutlet weak var repeatTableView: UITableView!
    @IBOutlet weak var repeatTableViewheight: NSLayoutConstraint!
    @IBOutlet weak var textContainerForRepeatHeight: NSLayoutConstraint!
    @IBOutlet weak var repeatButtonMargin: UILabel!
    

    
    override func viewDidLoad() {
        super.viewDidLoad()

        replayTableView.delegate = self
        replayTableView.dataSource = self
        replayTableView.register(UINib(nibName: "BullutinBoard2TableViewCell", bundle: nil), forCellReuseIdentifier: "BullutinBoard2TableViewCell")
        replayTableView.separatorStyle = .none
        
        repeatTableView.delegate = self
        repeatTableView.dataSource = self
        repeatTableView.register(UINib(nibName: "BullutinBoard2TableViewCell", bundle: nil), forCellReuseIdentifier: "BullutinBoard2TableViewCell")
        repeatTableView.separatorStyle = .none

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"),
                                                           style: .done,
                                                           target: self,
                                                           action: #selector(dismissSelf))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "投稿する",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(tappedRightBarButton))
        navigationItem.leftBarButtonItem?.tintColor = UIColor(named: "gentle")
        navigationItem.rightBarButtonItem?.tintColor = UIColor(red: 0.12, green: 0.71, blue: 0.12, alpha: 1)
        navigationController?.navigationBar.barTintColor = UIColor(named: "appBackground")


        
        replayTextView.delegate = self
        replayTextView.becomeFirstResponder()
        
        if isReplayRepeat == 0 {
            replayTableView.isHidden = false
            repeatTableView.isHidden = true
            repeatButtonMargin.isHidden = true
            SubjectLabel.setImage(UIImage(systemName: "arrowshape.turn.up.left.fill"), for: .normal)
            SubjectLabel.tintColor = .label
        }
        else {
            replayTableView.isHidden = true
            repeatTableView.isHidden = false
            repeatButtonMargin.isHidden = false
            SubjectLabel.setImage(UIImage(systemName: "arrow.turn.left.up"), for: .normal)
            SubjectLabel.tintColor = .label
            repeatTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20)
            repeatTableView.layer.borderWidth = 2
            repeatTableView.layer.borderColor = UIColor.systemGray3.cgColor
            repeatTableView.layer.cornerRadius = 10
            repeatTableView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }
        
        
        photo1Cancel.addTarget(self, action: #selector(tappedCancelPhoto1), for: .touchUpInside)
        photo2Cancel.addTarget(self, action: #selector(tappedCancelPhoto2), for: .touchUpInside)
        photo3Cancel.addTarget(self, action: #selector(tappedCancelPhoto3), for: .touchUpInside)
        photo4Cancel.addTarget(self, action: #selector(tappedCancelPhoto4), for: .touchUpInside)
        photo1Cancel.isHidden = true
        photo2Cancel.isHidden = true
        photo3Cancel.isHidden = true
        photo4Cancel.isHidden = true
        photo1Cancel.layer.cornerRadius = 13
        photo2Cancel.layer.cornerRadius = 13
        photo3Cancel.layer.cornerRadius = 13
        photo4Cancel.layer.cornerRadius = 13
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let post = repeatParentPost {
            let str = post.postMessage
            let newLine = "\n"
            let charCount = str.lengthOfBytes(using: String.Encoding.shiftJIS)
            var newLineCount = 0
            var nextRange = str.startIndex..<str.endIndex //最初は文字列全体から探す
            while let range = str.range(of: newLine, options: .caseInsensitive, range: nextRange) { //.caseInsensitiveで探す方が、lowercaseStringを作ってから探すより普通は早い
                newLineCount += 1
                nextRange = range.upperBound..<str.endIndex
                //見つけた単語の次(range.upperBound)から元の文字列の最後までの範囲で次を探す
            }
            
            if post.photoUrl == nil {
                if charCount <= 43 && newLineCount == 0 {
                    repeatTableViewheight.constant = 135
                }
                else if charCount <= 86 || newLineCount == 1 {
                    repeatTableViewheight.constant = 155
                }
                else if charCount <= 192,
                        charCount <= 129 && (1 <= newLineCount && newLineCount >= 4) {
                    repeatTableViewheight.constant = 175
                }
                else {
                    repeatTableViewheight.constant = 200
                }
            }
            else {
                repeatTableViewheight.constant = 200
            }
        }
        
        if let post = replayParentPost {
            let str = post.postMessage
            if str.count <= 43 {
                replayTbleViewHeight.constant = 100
            }
        }
        tapPost = false
    }
    

    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    @objc private func tappedRightBarButton() {
        
        guard tapPost == false else { return }
        tapPost = true
        
        var isComment: Bool
        var isRemessage: Bool
        if isReplayRepeat == 0 {
            isRemessage = false
            isComment = true
        }
        else {
            isRemessage = true
            isComment = false
            replayParentPost = repeatParentPost
        }
        
        spinner.show(in: view)
        
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let myName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        guard var postText = replayTextView.text,
                  postText.count < 151 else {
            tapPost = false
            alertUserError(alertMessage: "150文字以下にしてください")
            return
        }
        
        postText = postText.trimmingCharacters(in: .newlines)
        let newLine = "\n"
        var newLineCount = 0
        var nextRange = postText.startIndex ..< postText.endIndex //最初は文字列全体から探す
        while let range = postText.range(of: newLine, options: .caseInsensitive, range: nextRange) { //.caseInsensitiveで探す方が、lowercaseStringを作ってから探すより普通は早い
            newLineCount += 1
            //見つけた単語の次(range.upperBound)から元の文字列の最後までの範囲で次を探す
            nextRange = range.upperBound ..< postText.endIndex
        }
        
        
        if newLineCount > 5 {
            tapPost = false
            alertUserError(alertMessage: "改行は5つまでです")
            return
        }
        
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        format.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        let dateString = format.string(from: date)
        
        
        let dayformat = DateFormatter()
        dayformat.dateFormat = "yyMM"
        dayformat.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        let collectionString = dayformat.string(from: date)
        
        let dandomID = randomString(length: 15)
        
        let pictureFormat = DateFormatter()
        pictureFormat.dateFormat = "HHmmss"
        pictureFormat.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let datePictureString = pictureFormat.string(from: date)
        
        // ex) 140258_yusho-gmail-com_2102 → 2021年2月の14時2分58秒に投稿
        let makePostId = "\(dandomID)_\(whichTable)\(collectionString)"
        
        
        if let photoDataArray1 = replayPhotoDataArray {
            // 写真ありバージョン
            StorageManager.shared.insertPostPicture(email: safeMyEmail, date: datePictureString, photoArray: photoDataArray1) { [weak self] (result) in
                switch result {
                case .success(let urlStringArray):
                    var resultArray = [String]()
                    let key1 = "\(datePictureString)_4"
                    let key2 = "\(datePictureString)_3"
                    let key3 = "\(datePictureString)_2"
                    let key4 = "\(datePictureString)_1"
                    for array in urlStringArray {
                        if array.contains(key4) {
                            resultArray.append(array)
                        }
                    }
                    for array in urlStringArray {
                        if array.contains(key3) {
                            resultArray.append(array)
                        }
                    }
                    for array in urlStringArray {
                        if array.contains(key2) {
                            resultArray.append(array)
                        }
                    }
                    for array in urlStringArray {
                        if array.contains(key1) {
                            resultArray.append(array)
                        }
                    }
                    let post = Post(postId: makePostId,
                                    postMessage: postText,
                                    postEmail: safeMyEmail,
                                    postName: myName,
                                    postTime: dateString,
                                    good: 0, goodList: ["0_nil"], remessage: 0, remessagePostArray: ["0_nil"], isRemessage: nil, comment: 0,
                                    photoUrl: resultArray)
                    
                    guard let rowReplayParentPost = self?.replayParentPost else { return }
                    DatabaseManager.shared.insertRemessagePostInfo(post: post, parentPost: rowReplayParentPost, whichTable: self?.whichTable ?? 0, dateForCollection: collectionString, isRemessage: isRemessage, isCommet: isComment) { (success) -> (Void) in
                        if success == true {
                            self?.spinner.dismiss()
                            self?.dismiss(animated: true, completion: {
                                self?.replayCompletion?(true)
                            })
                        }
                        else {
                            self?.tapPost = false
                            print("fail to insert post to database (ReplayViewController image)")
                        }
                   }
                   
                case .failure(let err):
                    self?.tapPost = false
                    print("message photo upload error: \(err)")
                }
            }
        }
        else {
            // 写真なしバージョン
            let post = Post(postId: makePostId,
                            postMessage: postText,
                            postEmail: safeMyEmail,
                            postName: myName,
                            postTime: dateString,
                            good: 0, goodList: ["0_nil"], remessage: 0, remessagePostArray: ["0_nil"], isRemessage: nil, comment: 0,
                            photoUrl: nil)
           
            DatabaseManager.shared.insertRemessagePostInfo(post: post, parentPost: replayParentPost!, whichTable: whichTable, dateForCollection: collectionString, isRemessage: isRemessage, isCommet: isComment) { [weak self](success) -> (Void) in
                if success == true {
                    self?.spinner.dismiss()
                    self?.dismiss(animated: true, completion: {
                        self?.replayCompletion?(true)
                    })
                }
                else {
                    self?.tapPost = false
                    print("fail to insert post to database (ReplayViewController no Image)")
               }
           }
        }

    }
    
//    private static let dateFormatter: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.dateStyle = .long
//        formatter.timeStyle = .medium
//        formatter.locale = Locale(identifier: "ja_JP")
//        return formatter
//    }()
    
    
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
    
    
    func alertUserError(alertMessage: String) {
        let alert = UIAlertController(title: "エラー",
                                      message: alertMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true)
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        keyboardToolbar(textView: textView)
        return true
    }
    func keyboardToolbar(textView: UITextView) {
        
        let toolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        toolbar.barStyle = UIBarStyle.default
        toolbar.bounds.size.height = 28
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let image: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "camera"), style: .done, target: self, action: #selector(barCameraButton))
        image.tintColor = UIColor.label
        let library: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "photo"), style: .done, target: self, action: #selector(barImageButton))
        library.tintColor = UIColor.label
        
        
        
        var items = [UIBarButtonItem]()
        
        items.append(image)
        items.append(library)
        items.append(flexSpace)
        toolbar.items = items
        toolbar.sizeToFit()
        textView.inputAccessoryView = toolbar
    }
    
        
    @objc private func barImageButton() {
        if replayPhoto4.image == nil {
            replayPresentPhotoPicker()
        }
        else {
            alertUserError(alertMessage: "写真は４枚までです")
        }
    }
    
    @objc private func barCameraButton() {
        if replayPhoto4.image == nil {
            replayPresentCamera()
        }
        else {
            alertUserError(alertMessage: "写真は４枚までです")
        }
    }

    
    @objc private func tappedCancelPhoto1() {
        replayPhoto1.image = replayPhoto2.image
        replayPhoto2.image = replayPhoto3.image
        replayPhoto3.image = replayPhoto4.image
        replayPhoto4.image = nil
        if replayPhoto1.image == nil { photo1Cancel.isHidden = true }
        if replayPhoto2.image == nil { photo2Cancel.isHidden = true }
        if replayPhoto3.image == nil { photo3Cancel.isHidden = true }
        if replayPhoto4.image == nil { photo4Cancel.isHidden = true }
        replayPhotoDataArray?.remove(at: 0)
    }
    @objc private func tappedCancelPhoto2() {
        replayPhoto2.image = replayPhoto3.image
        replayPhoto3.image = replayPhoto4.image
        replayPhoto4.image = nil
        if replayPhoto2.image == nil { photo2Cancel.isHidden = true }
        if replayPhoto3.image == nil { photo3Cancel.isHidden = true }
        if replayPhoto4.image == nil { photo4Cancel.isHidden = true }
        replayPhotoDataArray?.remove(at: 1)
    }
    @objc private func tappedCancelPhoto3() {
        replayPhoto3.image = replayPhoto4.image
        replayPhoto4.image = nil
        if replayPhoto3.image == nil { photo3Cancel.isHidden = true }
        if replayPhoto4.image == nil { photo4Cancel.isHidden = true }
        replayPhotoDataArray?.remove(at: 2)
    }
    @objc private func tappedCancelPhoto4() {
        replayPhotoDataArray?.remove(at: 3)
        photo4Cancel.isHidden = true
        replayPhoto4.image = nil
    }
    

}




extension ReplayViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if let model = repeatParentPost {
            replayToNameLabel.text = "to: \(model.postName)"
            let cell = tableView.dequeueReusableCell(withIdentifier: "BullutinBoard2TableViewCell", for: indexPath) as! BullutinBoard2TableViewCell
            cell.selectionStyle = .none
            cell.configure(model: model)
            cell.repeatTableView.isHidden = true
            cell.repeatTableViewButton.isHidden = true
            return cell
        }
        if let model = replayParentPost {
            replayToNameLabel.text = "to: \(model.postName)"
            let cell = tableView.dequeueReusableCell(withIdentifier: "BullutinBoard2TableViewCell", for: indexPath) as! BullutinBoard2TableViewCell
            cell.selectionStyle = .none
            cell.configure(model: model)
            cell.repeatTableView.isHidden = true
            cell.repeatTableViewButton.isHidden = true
            return cell
        }
        
        fatalError("Error: ReplayViewController(no paretPost)")
    }
    
    

}

extension ReplayViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {


    func replayPresentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = false
        present(vc, animated: true)
    }

    func replayPresentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = false
        present(vc, animated: true)
    }


    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        
        let cropViewController = CropViewController(image: selectedImage)
        cropViewController.delegate = self
        picker.dismiss(animated: false, completion: nil)
        present(cropViewController, animated: false, completion: nil)
        
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    

}


extension ReplayViewController: CropViewControllerDelegate {

    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        //加工した画像が取得できる
        
        cropViewController.dismiss(animated: false, completion: nil)
        
        // ※画像のデータサイズをKBで表示。
        let imageData:Int = NSData(data: image.pngData()!).count
        let dataToKB = Double(imageData) / 1000.0
        
        //バリデーションを実装
        var data: Data?
        if dataToKB <= 300.0 {
            data = image.pngData()
        }
        else {
            var resizedImage: UIImage?
            if (dataToKB >= 300.0) && (600.0 > dataToKB) {
                resizedImage = image.resized(withPercentage: 0.9)
            }
            else if (dataToKB >= 600.0) && (1200.0 > dataToKB) {
                resizedImage = image.resized(withPercentage: 0.8)
            }
            else if (dataToKB >= 1200.0) && (2400.0 > dataToKB) {
                resizedImage = image.resized(withPercentage: 0.7)
            }
            else if (dataToKB >= 2400.0) && (4800.0 > dataToKB) {
                resizedImage = image.resized(withPercentage: 0.6)
            }
            else if (dataToKB >= 4800.0) && (10000.0 > dataToKB) {
                resizedImage = image.resized(withPercentage: 0.5)
            }
            else if (dataToKB >= 10000.0) && (20000.0 > dataToKB) {
                resizedImage = image.resized(withPercentage: 0.4)
            }
            else if (dataToKB >= 20000.0) && (40000.0 > dataToKB) {
                resizedImage = image.resized(withPercentage: 0.35)
            }
            else if (dataToKB >= 40000.0) && (80000.0 > dataToKB) {
                resizedImage = image.resized(withPercentage: 0.3)
            }
            else {
                resizedImage = image.resized(withPercentage: 0.2)
            }
            
            var resizeData: Int = NSData(data: (resizedImage?.pngData())!).count / 1000
            
//            print("original size: \(dataToKB)")
//            print(resizeData)
            
            if resizeData > 250 { // 300KB以下にしたい
                data = resizedImage?.jpegData(compressionQuality: 0.8)
                if NSData(data: data!).count/1000 > 300 {
                    while NSData(data: data!).count/1000 > 300 {
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
        
        replayImageContainer.isHidden = false
        textContainerForRepeatHeight.constant = 300

        if replayPhoto1.image == nil {
            replayPhoto1.image = image
            photo1Cancel.isHidden = false
            if let rowdata = data {
                replayPhotoDataArray = [rowdata]
            }
        } else if replayPhoto2.image == nil {
            replayPhoto2.image = image
            photo2Cancel.isHidden = false
            if let rowdata = data {
                replayPhotoDataArray?.append(rowdata)
            }
        } else if replayPhoto3.image == nil {
            replayPhoto3.image = image
            photo3Cancel.isHidden = false
            if let rowdata = data {
                replayPhotoDataArray?.append(rowdata)
            }
        } else if replayPhoto4.image == nil {
            replayPhoto4.image = image
            photo4Cancel.isHidden = false
            if let rowdata = data {
                replayPhotoDataArray?.append(rowdata)
            }
        }
        
        
    }

    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        // キャンセル時
        cropViewController.dismiss(animated: true, completion: nil)
    }
}
