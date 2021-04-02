//
//  Post2ViewController.swift
//  BulletinBoard
//
//  on 2020/11/27.
//


import UIKit
import JGProgressHUD
import CropViewController

class PostViewController: UIViewController, UITextViewDelegate {
    
    public var whichCell = 0 //1だと新しく作るcommunityのfirst message
    public var fromGroup = "fac"
    public var isShareTask = false
    public var shareTask = BullutinTask(taskId: "", taskName: "", taskLimit: "", timeSchedule: "", documentPath: "", memberCount: 0, makedEmail: "", doneMember: [], gettingMember: [], wantToTalkMember: [])
    
    public var completionPost: ((Bool) -> (Void))?
    private let spinner = JGProgressHUD()
    private var photoDataArray: [Data]?
    private var tapPost = false
    

    @IBOutlet weak var postMessageTextView: UITextView!
    @IBOutlet weak var photoContainer: UIStackView!
    @IBOutlet weak var photo1: UIImageView!
    @IBOutlet weak var photo1Cancel: UIButton!
    @IBOutlet weak var photo2: UIImageView!
    @IBOutlet weak var photo2Cancel: UIButton!
    @IBOutlet weak var photo3: UIImageView!
    @IBOutlet weak var photo3Cancel: UIButton!
    @IBOutlet weak var photo4: UIImageView!
    @IBOutlet weak var photo4Cancel: UIButton!
    @IBOutlet weak var isAllButton: UISwitch!
//    @IBOutlet weak var isUniButton: UISwitch!
    @IBOutlet weak var isFacButton: UISwitch!
    @IBOutlet weak var selectAllFacContainer: UIStackView!
    @IBOutlet weak var tableViewContainer: UIView!
    
    
    
    public let taskTableView: UITableView = {
        let table = UITableView()
        table.register(UINib(nibName: "BullutinCellTableViewCell", bundle: nil), forCellReuseIdentifier: "ReplayForCellTableViewCell")
        return table
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .done, target: self, action: #selector(dismissSelf))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "投稿する",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(tappedRightBarButton))
        navigationItem.leftBarButtonItem?.tintColor = UIColor(named: "gentle")
        navigationItem.rightBarButtonItem?.tintColor = UIColor(red: 0.12, green: 0.71, blue: 0.12, alpha: 1)
        navigationController?.navigationBar.barTintColor = UIColor(named: "appBackground")
        
        
        postMessageTextView.delegate = self
        postMessageTextView.becomeFirstResponder()
        postMessageTextView.textContainerInset = UIEdgeInsets(top: 10, left: 20, bottom: 0, right: 20)
        
        
        photo1Cancel.addTarget(self, action: #selector(tappedCancelPhoto1), for: .touchUpInside)
        photo2Cancel.addTarget(self, action: #selector(tappedCancelPhoto2), for: .touchUpInside)
        photo3Cancel.addTarget(self, action: #selector(tappedCancelPhoto3), for: .touchUpInside)
        photo4Cancel.addTarget(self, action: #selector(tappedCancelPhoto4), for: .touchUpInside)
        photo1Cancel.isHidden = true
        photo2Cancel.isHidden = true
        photo3Cancel.isHidden = true
        photo4Cancel.isHidden = true
        
        if fromGroup == "all" {
            isAllButton.isOn = true
            isFacButton.isOn = false
        }
        if fromGroup == "fac" {
            isAllButton.isOn = false
            isFacButton.isOn = true
        }
        
        if isShareTask == true {
            taskTableView.delegate = self
            taskTableView.dataSource = self
            
            tableViewContainer.addSubview(taskTableView)
            selectAllFacContainer.isHidden = true
            taskTableView.layer.cornerRadius = 5
            taskTableView.layer.borderWidth = 1
            taskTableView.layer.borderColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.3).cgColor
            
            // containerは150
            taskTableView.frame = CGRect(x: 60, y: 10, width: view.width - 120, height: 130)
            taskTableView.separatorStyle = .none
            guard let myName = UserDefaults.standard.value(forKey: "name") as? String else { return }
            postMessageTextView.text = "\(myName)さんが「\(shareTask.taskName)」の共有をしました。\nタップして参加してみよう"
            
        }
        else {
            tableViewContainer.isHidden = true
        }
        
        if let _ = UserDefaults.standard.value(forKey: "name") as? String { }
        else { alertBeforeSetup() }
        
        tapPost = false
    }
    
    private func alertBeforeSetup() {
        let alert = UIAlertController(title: "ゲストのままです",
                                      message: "左上にあるアイコンをタップして、自分のプロフィールを完成させましょう。",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .cancel,
                                      handler: { [weak self]_ in
                                        self?.dismiss(animated: true, completion: nil)
                                      }))
        present(alert, animated: true)
    }
    
    
    
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
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
        if photo4.image == nil {
            presentPhotoPicker()
        }
        else {
            alertUserError(alertMessage: "写真は４枚までです")
        }
    }
    
    @objc private func barCameraButton() {
        if photo4.image == nil {
            presentCamera()
        }
        else {
            alertUserError(alertMessage: "写真は４枚までです")
        }
    }
    
    
    @objc private func tappedRightBarButton() {
        
        guard tapPost == false else { return }
        tapPost = true
        
        spinner.show(in: view)
        
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let myName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        
        guard var postText = postMessageTextView.text,
                  postText.count < 151 else {
            spinner.dismiss()
            tapPost = false
            alertUserError(alertMessage: "150文字以下にしてください")
            return
        }
        
        if postText.count == 0 {
            tapPost = false
            alertUserError(alertMessage: "メッセージを入力してください")
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
            spinner.dismiss()
            alertUserError(alertMessage: "改行は5つまでです")
            return
        }
        
        
        let date = Date()
//        let date = Calendar.current.date(byAdding: .month, value: -1, to: date1)!
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        format.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        let dateString = format.string(from: date)
        
        let dayformat = DateFormatter()
        dayformat.dateFormat = "yyMM"
        dayformat.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        let collectionString = dayformat.string(from: date)
        
        let ramdomID = randomString(length: 15)
        
        var whichTable = 0 //全体のみ
        if isFacButton.isOn == true { whichTable = 1 } // 学部のみ
        if isAllButton.isOn == true && isFacButton.isOn == true { whichTable = 4 }
        
        let pictureFormat = DateFormatter()
        pictureFormat.dateFormat = "yyMMddHHmmss"
        pictureFormat.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let datePictureString = pictureFormat.string(from: date)
        
        // ex) 140258_yusho-gmail-com_2210203
        let makePostId = "\(ramdomID)_\(whichTable)\(collectionString)"
        
        
        if let photoDataArray1 = photoDataArray {
            // 写真ありバージョン
            let datePhoto = pictureFormat.string(from: date)
            StorageManager.shared.insertPostPicture(email: safeMyEmail, date: datePhoto, photoArray: photoDataArray1) { [weak self] (result) in
                switch result {
                case .success(let urlStringArray):
                    guard let strongSelf = self else {
                        return
                    }
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
                    
                    var bullutinTask: BullutinTask?
                    if strongSelf.isShareTask == true {
                        bullutinTask = BullutinTask(taskId: strongSelf.shareTask.taskId, taskName: strongSelf.shareTask.taskName, taskLimit: strongSelf.shareTask.taskLimit, timeSchedule: strongSelf.shareTask.timeSchedule, documentPath: strongSelf.shareTask.documentPath, memberCount: strongSelf.shareTask.memberCount, makedEmail: strongSelf.shareTask.makedEmail, doneMember: strongSelf.shareTask.doneMember, gettingMember: strongSelf.shareTask.gettingMember, wantToTalkMember: strongSelf.shareTask.wantToTalkMember)
                    }
                    
                    
                    let post = Post(postId: makePostId,
                                    postMessage: postText,
                                    postEmail: safeMyEmail,
                                    postName: myName,
                                    postTime: dateString,
                                    good: 0, goodList: ["0_nil"], remessage: 0,
                                    remessagePostArray: ["0_nil"], isRemessage: nil,
                                    comment: 0, photoUrl: resultArray,
                                    shareTask: bullutinTask)
                    
                    if strongSelf.isShareTask == false {
                        // postの投稿
                        DatabaseManager.shared.insertPostInfo(post: post, dateForCollection: collectionString, whichTable: whichTable, isAll: strongSelf.isAllButton.isOn, isUni: false, isFac: strongSelf.isFacButton.isOn) { (success) -> (Void) in
                            if success == true {
                                self?.spinner.dismiss()
                                self?.dismiss(animated: true) {[weak self] in
                                    self?.completionPost?(true)
                                }
                            }
                            else {
                                self?.spinner.dismiss()
                                self?.tapPost = false
                                print("fail to insert post to database (PostViewController image)")
                            }
                        }
                    }
                    else {
                        // taskの投稿
                        DatabaseManager.shared.insertShareTask(post: post, dateForCollection: collectionString) { (success) -> (Void) in
                            if success == true {
                                self?.spinner.dismiss()
                                self?.dismiss(animated: true) {[weak self] in
                                    self?.completionPost?(true)
                                }
                            }
                            else {
                                self?.tapPost = false
                                self?.spinner.dismiss()
                                print("fail to insert post to database (PostViewController image)")
                            }
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
            // 通常の投稿
            
            var bullutinTask: BullutinTask?
            if isShareTask == true {
                bullutinTask = BullutinTask(taskId: shareTask.taskId, taskName: shareTask.taskName, taskLimit: shareTask.taskLimit, timeSchedule: shareTask.timeSchedule, documentPath: shareTask.documentPath, memberCount: shareTask.memberCount, makedEmail: shareTask.makedEmail, doneMember: shareTask.doneMember, gettingMember: shareTask.gettingMember, wantToTalkMember: shareTask.wantToTalkMember)
            }
            
            let post = Post(postId: makePostId,
                            postMessage: postText,
                            postEmail: safeMyEmail,
                            postName: myName,
                            postTime: dateString,
                            good: 0, goodList: ["0_nil"], remessage: 0, remessagePostArray: ["0_nil"], isRemessage: nil, comment: 0,
                            photoUrl: nil, shareTask: bullutinTask)
            
            if isShareTask == false {
                // postの投稿
                DatabaseManager.shared.insertPostInfo(post: post, dateForCollection: collectionString, whichTable: whichTable, isAll: isAllButton.isOn, isUni: false, isFac: isFacButton.isOn) { [weak self](success) -> (Void) in
                    if success == true {
                        self?.spinner.dismiss()
                        self?.dismiss(animated: true) {[weak self] in
                            self?.completionPost?(true)
                        }
                    }
                    else {
                        self?.tapPost = false
                        self?.spinner.dismiss()
                        print("fail to insert post to database (PostViewController no image)")
                    }
                }
            }
            else {
                // taskの投稿
                DatabaseManager.shared.insertShareTask(post: post, dateForCollection: collectionString) { [weak self] (success) -> (Void) in
                    if success == true {
                        self?.spinner.dismiss()
                        self?.dismiss(animated: true) {[weak self] in
                            self?.completionPost?(true)
                        }
                    }
                    else {
                        self?.tapPost = false
                        self?.spinner.dismiss()
                        print("fail to insert post to database (PostViewController image)")
                    }
                }
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
    

    private func alertUserError(alertMessage: String) {
        let alert = UIAlertController(title: "エラー",
                                      message: alertMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true)
    }
    
    
    @objc private func tappedCancelPhoto1() {
        photo1.image = photo2.image
        photo2.image = photo3.image
        photo3.image = photo4.image
        photo4.image = nil
        if photo1.image == nil { photo1Cancel.isHidden = true }
        if photo2.image == nil { photo2Cancel.isHidden = true }
        if photo3.image == nil { photo3Cancel.isHidden = true }
        if photo4.image == nil { photo4Cancel.isHidden = true }
        photoDataArray?.remove(at: 0)
    }
    @objc private func tappedCancelPhoto2() {
        photo2.image = photo3.image
        photo3.image = photo4.image
        photo4.image = nil
        if photo2.image == nil { photo2Cancel.isHidden = true }
        if photo3.image == nil { photo3Cancel.isHidden = true }
        if photo4.image == nil { photo4Cancel.isHidden = true }
        photoDataArray?.remove(at: 1)
    }
    @objc private func tappedCancelPhoto3() {
        photo3.image = photo4.image
        photo4.image = nil
        if photo3.image == nil { photo3Cancel.isHidden = true }
        if photo4.image == nil { photo4Cancel.isHidden = true }
        photoDataArray?.remove(at: 2)
    }
    @objc private func tappedCancelPhoto4() {
        photoDataArray?.remove(at: 3)
        photo4Cancel.isHidden = true
        photo4.image = nil
    }

}



extension PostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {


    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = false
        present(vc, animated: true)
    }

    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = false
        present(vc, animated: true)
    }


    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        let cropViewController = CropViewController(image: selectedImage)
        cropViewController.delegate = self
        
        picker.dismiss(animated: false, completion: nil)
        present(cropViewController, animated: false, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }


}


extension PostViewController: CropViewControllerDelegate {

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
        photoContainer.isHidden = false
        
        if photo1.image == nil {
            photo1.image = image
            if let rowdata = data {
                photoDataArray = [rowdata]
            }
            photo1Cancel.isHidden = false
            photo1Cancel.layer.cornerRadius = 13
            photo1Cancel.backgroundColor = .gray
            photo1Cancel.tintColor = .label
        } else if photo2.image == nil {
            photo2.image = image
            if let rowdata = data {
                photoDataArray?.append(rowdata)
            }
            photo2Cancel.isHidden = false
            photo2Cancel.layer.cornerRadius = 13
            photo2Cancel.backgroundColor = .gray
            photo2Cancel.tintColor = .label
        } else if photo3.image == nil {
            photo3.image = image
            if let rowdata = data {
                photoDataArray?.append(rowdata)
            }
            photo3Cancel.isHidden = false
            photo3Cancel.layer.cornerRadius = 13
            photo3Cancel.backgroundColor = .gray
            photo3Cancel.tintColor = .label
        } else if photo4.image == nil {
            photo4.image = image
            if let rowdata = data {
                photoDataArray?.append(rowdata)
            }
            photo4Cancel.isHidden = false
            photo4Cancel.layer.cornerRadius = 13
            photo4Cancel.backgroundColor = .gray
            photo4Cancel.tintColor = .label
        }
        
    }

    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        // キャンセル時
        cropViewController.dismiss(animated: true, completion: nil)
    }
}



extension PostViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReplayForCellTableViewCell", for: indexPath) as! ReplayForCellTableViewCell
        cell.selectionStyle = .none
        
        cell.taskConfigure(model: shareTask)
        return cell
    }
    
    
}




extension UIImage {
    //データサイズを変更する
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvas = CGSize(width: size.width * percentage, height: size.height * percentage)
        return UIGraphicsImageRenderer(size: canvas, format: imageRendererFormat).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
}
