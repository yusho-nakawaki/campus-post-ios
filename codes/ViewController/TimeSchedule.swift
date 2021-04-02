//
//  TimeSchedule.swift
//  Match
//
//  on 2021/01/09.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
import UserNotifications


struct TimeScheduleContainer{
    var name: String
    var classCount: Int
    var classDay: Int
    var timeTable: [TimeScheduleStruct]
}

struct TimeScheduleStruct {
    var number: Int
    var color: String // blue pink green
    var subject: String
    var teacher: String
    var place: String?
}

class TimeSchedule: UIViewController {
    
    
    public var myTimeSchedule = TimeScheduleContainer(name: "", classCount: 0, classDay: 0, timeTable: [])
    private var tasks = [Task]()
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var timeScheduleContainerView: UIView!
    @IBOutlet weak var timeScheduleContainerheight: NSLayoutConstraint!
    @IBOutlet weak var timeScheduleWidth: NSLayoutConstraint!
    @IBOutlet weak var weekLabelContainer: UIStackView!
    @IBOutlet weak var weekLabelLeftMargin:  NSLayoutConstraint! //24 or 39
    @IBOutlet weak var satLabel: UILabel!
    @IBOutlet weak var sunLable: UILabel!
    
    @IBOutlet weak var timeLabelContainer: UIStackView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var timeLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var classCountMarginRight: NSLayoutConstraint!
    @IBOutlet weak var timeLabelWidth: NSLayoutConstraint!
    @IBOutlet weak var firstTime1: UILabel!
    @IBOutlet weak var endTime1: UILabel!
    @IBOutlet weak var firstTime2: UILabel!
    @IBOutlet weak var endTime2: UILabel!
    @IBOutlet weak var firstTime3: UILabel!
    @IBOutlet weak var endTime3: UILabel!
    @IBOutlet weak var firstTime4: UILabel!
    @IBOutlet weak var endTime4: UILabel!
    @IBOutlet weak var timeContainer5: UIView!
    @IBOutlet weak var firstTime5: UILabel!
    @IBOutlet weak var endTime5: UILabel!
    @IBOutlet weak var timeContainer6: UIView!
    @IBOutlet weak var firstTime6: UILabel!
    @IBOutlet weak var endTime6: UILabel!
    @IBOutlet weak var timeContainer7: UIView!
    @IBOutlet weak var fistTime7: UILabel!
    @IBOutlet weak var endTime7: UILabel!
    @IBOutlet weak var time1: UILabel!
    @IBOutlet weak var time2: UILabel!
    @IBOutlet weak var time3: UILabel!
    @IBOutlet weak var time4: UILabel!
    @IBOutlet weak var time5: UILabel!
    @IBOutlet weak var time6: UILabel!
    @IBOutlet weak var time7: UILabel!
    
    
    
    
    private let spinner = JGProgressHUD()
    public var friendEmail = ""
    private var mySafeEmail = ""
    public var fromProfileVC = false
    
    @IBOutlet weak var todoContainer: UIView!
    
    private let todoTableView: UITableView = {
        let table = UITableView()
        table.register(UINib(nibName: "TodoTableViewCell", bundle: nil), forCellReuseIdentifier: "TodoTableViewCell")
        return table
    }()
    private let addTodoButton: RespondingButton = {
        let button = RespondingButton()
        button.setImage(UIImage(systemName: "plus.circle"), for: .normal)
        button.tintColor = .label
        return button
    }()
    
    private lazy var todoInputAccessoryView: TodoInputAccessary = {
        let view = TodoInputAccessary()
        view.frame = CGRect(x: 0, y: 0, width: view.width, height: 100)
        
        // TodoInputAccessoryのメッセージをdelegateを使って受け取る
        // その後extensionで処理を書く
        view.delegate = self //privateではselfを呼び出せないので lazyをつける
        
        return view
    }()
    
    private var safeAreaTop: CGFloat {
        view.safeAreaInsets.top
    }
    
    private var safeAreaBottom: CGFloat {
        // get {} の省略型
        view.safeAreaInsets.bottom
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let myEmail = UserDefaults.standard.value(forKey: "email") as? String {
            mySafeEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        }
        else { gotoRegister() }
        if let _ = UserDefaults.standard.value(forKey: "fac") as? String { }
        else { gotoRegister() }
        
        timeLabelContainer.isUserInteractionEnabled = true
        let tapTimeCount = UITapGestureRecognizer(target: self, action: #selector(tapClassTime))
        timeLabelContainer.addGestureRecognizer(tapTimeCount)
        
        setupNavigationbar()
        addTodoButton.addTarget(self, action: #selector(addTodo), for: .touchUpInside)
        
        
        startConversationsOtherVC()
        startNotificationOtherVC()
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        
        setupClassTime()
        setupTimeSchedule()
        
        
        timeLabelHeight.constant = view.height - safeAreaTop - safeAreaBottom - 107
        timeScheduleContainerheight.constant = view.height - safeAreaTop - safeAreaBottom - 28
        timeScheduleWidth.constant = view.width

        
        if Auth.auth().currentUser == nil {
            gotoRegister()
            return
        }
        let appId = "1551616444"
        AppVersionCompare.toAppStoreVersion(appId: appId) { [weak self](type) in
            switch type {
            case .latest:
                print("ok")
            case .old:
                self?.alertMessage(alertMessage: "最新バージョンがあります。アップデートしてください。")
            case .error:
                print("エラー")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if friendEmail == mySafeEmail || fromProfileVC == false {
            setTodo()
        }
        else {
            todoContainer.isHidden = true
            scrollView.contentSize = CGSize(width: view.width, height: view.height - safeAreaTop)
        }
    }
    
    public func setTodo() {
        if fromProfileVC == false {
            scrollView.contentSize = CGSize(width: view.width, height: view.height + 500 - safeAreaBottom)
        } else {
            scrollView.contentSize = CGSize(width: view.width, height: view.height + 500)
        }
        
        // タスクに今までのタスクを追加
        tasks = fetchTasksFromUserdefaults()
        todoTableView.reloadData()
        setupTodo()
    }
    
    
    
    private func gotoRegister() {
        let registerVC = RegisterViewController()
        registerVC.completionEmail = { [weak self] (success) in
            if success == true {
                if let myEmail = UserDefaults.standard.value(forKey: "email") as? String {
                    self?.mySafeEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
                }
            }
        }
        let nav = UINavigationController(rootViewController: registerVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: false)
        
    }
    
    
    // MARK: - SET UP TIME SCHEDULE
    public func setupTimeSchedule() {
        
        if friendEmail == mySafeEmail || fromProfileVC == false {
            if let value = UserDefaults.standard.value(forKey: "myTimeSchedule") as? [String: Any] {
                
                guard let name = value["name"] as? String,
                      let classCount = value["classCount"] as? Int,
                      let classDay = value["classDay"] as? Int,
                      let array = value["timeData"] as? [[String: String]] else {
                    return
                }
                
                var result = [TimeScheduleStruct]()
                var i = 0
                for cell in array {
                    guard let teacher = cell["teacher"],
                          let subject = cell["subject"],
                          let color = cell["color"] else {
                        return
                    }
                    var place = ""
                    if let rowPlace = cell["place"] { place = rowPlace }
                    let data = TimeScheduleStruct(number: i, color: color, subject: subject, teacher: teacher, place: place)
                    result.append(data)
                    i += 1
                }
                setupNavigationTitle(text: name)
                myTimeSchedule = TimeScheduleContainer(name: name, classCount: classCount, classDay: classDay, timeTable: result)
                setupCollection(classCount: myTimeSchedule.classCount, classDay: myTimeSchedule.classDay)
                collectionView.reloadData()
            }
            else {
                var i = 0
                var timeTable = [TimeScheduleStruct]()
                while i <= 24 {
                    timeTable.append(TimeScheduleStruct(number: i, color: "green", subject: "", teacher: "", place: ""))
                    i += 1
                }
                myTimeSchedule = TimeScheduleContainer(name: "1年前期", classCount: 5, classDay: 5, timeTable: timeTable)
                setupNavigationTitle(text: "時間割")
                satLabel.isHidden = true
                sunLable.isHidden = true
                timeContainer6.isHidden = true
                timeContainer7.isHidden = true
                setupCollection(classCount: 5, classDay: 5)
                collectionView.reloadData()
            }
        }
        else {
            DatabaseManager.shared.fetchTimeSchedule(myEmail: friendEmail) { [weak self](result) in
                switch result {
                case .success(let dataArray):
                    self?.myTimeSchedule = dataArray
                    self?.setupCollection(classCount: dataArray.classCount, classDay: dataArray.classDay)
                    self?.setupNavigationTitle(text: dataArray.name)
                    self?.collectionView.reloadData()
                case .failure(_):
                    var i = 0
                    var timeTable = [TimeScheduleStruct]()
                    while i <= 24 {
                        timeTable.append(TimeScheduleStruct(number: i, color: "green", subject: "", teacher: "", place: ""))
                        i += 1
                    }
                    self?.setupNavigationTitle(text: "時間割")
                    self?.myTimeSchedule = TimeScheduleContainer(name: "1年前期", classCount: 5, classDay: 5, timeTable: timeTable)
                    self?.satLabel.isHidden = true
                    self?.sunLable.isHidden = true
                    self?.timeContainer6.isHidden = true
                    self?.timeContainer7.isHidden = true
                    self?.setupCollection(classCount: 5, classDay: 5)
                    self?.collectionView.reloadData()
                }
            }
        }
    }
    
    
    private func setupNavigationTitle(text: String) {
        // タイトルを表示するラベルを作成
        let label = UILabel()
        label.text = text
        label.textColor = .darkGray
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.sizeToFit()
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapTitle))
        label.addGestureRecognizer(gestureRecognizer)
        label.isUserInteractionEnabled = true
        
        navigationItem.titleView = label
    }
    
    
    private func setupNavigationbar() {
        
        view.backgroundColor = UIColor(named: "appBackground")
        navigationController?.navigationBar.tintColor = UIColor(named: "gentle")
        navigationController?.navigationBar.barTintColor = UIColor(named: "appBackground")
        navigationController?.navigationBar.shadowImage = UIImage()

        
        if fromProfileVC == true {
            navigationItem.leftBarButtonItem =
                UIBarButtonItem(image: UIImage(systemName: "multiply"),
                                style: .done,
                                target: self,
                                action: #selector(dismissSelf))
        }
        
        
        if friendEmail == mySafeEmail || fromProfileVC == false {
            // profile画面へ
            let menuBtn = UIButton(type: .custom)
            menuBtn.frame = CGRect(x: 2, y: 0, width: 28, height: 28)
            menuBtn.setImage(UIImage(systemName: "gearshape"), for: .normal)
            menuBtn.tintColor = UIColor(named: "gentle")
            menuBtn.addTarget(self, action: #selector(changeTimeSchedule), for: .touchUpInside)
            
            let menuBarItem = UIBarButtonItem(customView: menuBtn)
            navigationItem.rightBarButtonItem = menuBarItem
        }
        
    }
    
    
    @objc private func tapClassTime() {
        // change onClassTime
        if friendEmail == mySafeEmail || fromProfileVC == false {
            if let isOn = UserDefaults.standard.value(forKey: "onClassTime") as? Bool {
                if isOn == true {
                    changeClassTime(isOn: true)
                    UserDefaults.standard.setValue(false, forKey: "onClassTime")
                }
                else {
                    changeClassTime(isOn: false)
                    UserDefaults.standard.setValue(true, forKey: "onClassTime")
                }
            }
            else {
                UserDefaults.standard.setValue(false, forKey: "onClassTime")
            }
            setupCollection(classCount: myTimeSchedule.classCount, classDay: myTimeSchedule.classDay)
        }
    }
    
    @objc public func setupClassTime() {
        if friendEmail == mySafeEmail || fromProfileVC == false {
            if let isOn = UserDefaults.standard.value(forKey: "onClassTime") as? Bool {
                if isOn == true { changeClassTime(isOn: false) }
                else { changeClassTime(isOn: true) }
            }
            else {
                // default = false
                changeClassTime(isOn: true)
            }
            return
        }
        if mySafeEmail != friendEmail {
            changeClassTime(isOn: true)
            return
        }
    }
    
    private func changeClassTime(isOn: Bool) {
        firstTime1.isHidden = isOn
        endTime1.isHidden = isOn
        firstTime2.isHidden = isOn
        endTime2.isHidden = isOn
        firstTime3.isHidden = isOn
        endTime3.isHidden = isOn
        firstTime4.isHidden = isOn
        endTime4.isHidden = isOn
        firstTime5.isHidden = isOn
        endTime5.isHidden = isOn
        firstTime6.isHidden = isOn
        endTime6.isHidden = isOn
        fistTime7.isHidden = isOn
        endTime7.isHidden = isOn
        if isOn == false {
            timeLabelWidth.constant = 30
            classCountMarginRight.constant = 0
            weekLabelLeftMargin.constant = 39
            if let timeArray =
                UserDefaults.standard.value(forKey: "classTime") as? [String: String] {
                firstTime1.text = timeArray["first1"]
                endTime1.text = timeArray["end1"]
                firstTime2.text = timeArray["first2"]
                endTime2.text = timeArray["end2"]
                firstTime3.text = timeArray["first3"]
                endTime3.text = timeArray["end3"]
                firstTime4.text = timeArray["first4"]
                endTime4.text = timeArray["end4"]
                firstTime5.text = timeArray["first5"]
                endTime5.text = timeArray["end5"]
                firstTime6.text = timeArray["first6"]
                endTime6.text = timeArray["end6"]
                fistTime7.text = timeArray["first7"]
                endTime7.text = timeArray["end7"]
                time1.transform = CGAffineTransform(translationX: -2, y: 0)
                time2.transform = CGAffineTransform(translationX: -2, y: 0)
                time3.transform = CGAffineTransform(translationX: -2, y: 0)
                time4.transform = CGAffineTransform(translationX: -2, y: 0)
                time5.transform = CGAffineTransform(translationX: -2, y: 0)
                time6.transform = CGAffineTransform(translationX: -2, y: 0)
                time7.transform = CGAffineTransform(translationX: -2, y: 0)
            }
        }
        else {
            timeLabelWidth.constant = 10
            classCountMarginRight.constant = 5
            weekLabelLeftMargin.constant = 24
        }
    }
    
    
    public func setupCollection(classCount: Int, classDay: Int) {
        // スクリーンに応じてサイズ変更
        let flowLayout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        // コレクションビューの大きさ
        let collectionWidth = view.width - (13 + timeLabelWidth.constant + classCountMarginRight.constant)
        let collectionHeight = view.height - 65 - safeAreaTop - safeAreaBottom
        // セルのサイズ
        let cellSizeX: CGFloat = collectionWidth/CGFloat(classDay) - 1
        let cellSizeY: CGFloat = collectionHeight/CGFloat(classCount) - 1
        flowLayout.itemSize = CGSize(width: cellSizeX, height: cellSizeY)
        // 縦・横のスペース
        flowLayout.minimumLineSpacing = 1
        flowLayout.minimumInteritemSpacing = 1
        
        // 上で設定した内容を反映させる
        collectionView.collectionViewLayout = flowLayout
        
        if classCount == 4 {
            timeContainer5.isHidden = true
            timeContainer6.isHidden = true
            timeContainer7.isHidden = true
        }
        if classCount == 5 {
            timeContainer5.isHidden = false
            timeContainer6.isHidden = true
            timeContainer7.isHidden = true
        }
        if classCount == 6 {
            timeContainer5.isHidden = false
            timeContainer6.isHidden = false
            timeContainer7.isHidden = true
        }
        if classCount == 7 {
            timeContainer5.isHidden = false
            timeContainer6.isHidden = false
            timeContainer7.isHidden = false
        }
        
        if classDay == 5 {
            satLabel.isHidden = true
            sunLable.isHidden = true
        }
        if classDay == 6 {
            satLabel.isHidden = false
            sunLable.isHidden = true
        }
        if classDay == 7 {
            satLabel.isHidden = false
            sunLable.isHidden = false
        }
        
        collectionView.isScrollEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    
    
    // MARK: - SET UP TODO
    private func setupTodo() {
        
        
        let todoLabel = UILabel(frame: CGRect(x: 20, y: 10, width: 170, height: 20))
        todoLabel.text = "todoリスト"
        todoLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        todoLabel.sizeToFit()
        addTodoButton.frame = CGRect(x: todoLabel.right,
                                     y: 5,
                                     width: 30,
                                     height: 30)
        addTodoButton.layer.cornerRadius = 15
        
        todoTableView.frame = CGRect(x: 5,
                                     y: todoLabel.bottom + 10,
                                     width: view.width - 10,
                                     height: 460)
        todoTableView.delegate = self
        todoTableView.dataSource = self
        
        todoContainer.addSubview(todoLabel)
        todoContainer.addSubview(addTodoButton)
        todoContainer.addSubview(todoTableView)
    }
    
    @objc private func addTodo() {
        addTodoButton.becomeFirstResponder()
        todoInputAccessoryView.todoTextView.becomeFirstResponder()
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .transitionCurlDown, animations: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.scrollView.contentOffset = CGPoint(x: 0, y: strongSelf.view.height  - strongSelf.safeAreaTop - strongSelf.safeAreaBottom - 20)
        })
    }
    
    // private var todoAccessoryViewで作ったインスタンスをセットする
    override var inputAccessoryView: UIView? {
        get {
            return todoInputAccessoryView
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

    
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    
    @objc private func changeTimeSchedule() {
        let vc = SetupTimeSchedule(original: myTimeSchedule)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func tapTitle() {
        
        return
        
//        let actionSheet = UIAlertController(title: "",
//                                            message: "",
//                                            preferredStyle: .actionSheet)
//
//        actionSheet.addAction(UIAlertAction(title: "通報する",
//                                            style: .default,
//                                            handler: { [weak self] _ in
//
//        }))
//
//        actionSheet.addAction(UIAlertAction(title: "ブロックする",
//                                            style: .default,
//                                            handler: { [weak self] _ in
//
//        }))
//
//        actionSheet.addAction(UIAlertAction(title: "キャンセル",
//                                            style: .cancel,
//                                            handler: nil))
//
//        if UIDevice.current.userInterfaceIdiom == .pad {
//            actionSheet.popoverPresentationController?.sourceView = self.view
//            let screenSize = UIScreen.main.bounds
//            actionSheet.popoverPresentationController?.sourceRect = CGRect(x: screenSize.size.width/2, y: screenSize.size.height, width: 0, height: 0)
//        }
//
//        present(actionSheet, animated: true)
    }
    
    
    func alertMessage(alertMessage: String) {
        let alert = UIAlertController(title: "メッセージ",
                                      message: alertMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true)
    }
    
    
    
    // MARK: - USERDEFAULTSの取得や保存
    
    private func insertTaskToUserdefaults(model: Task) {
        
        var fetchData = fetchTasksFromUserdefaults()
        fetchData.append(model)
        
        var data = [[String: Any]]()
        for dictionary in fetchData {
            
            let shareTask: [String: Any] = [
                "documentPath": dictionary.shareTask.documentPath,
                "memberCount": dictionary.shareTask.memberCount,
                "makedEmail": dictionary.shareTask.makedEmail,
                "doneMember": dictionary.shareTask.doneMember,
                "gettingMember": dictionary.shareTask.gettingMember,
                "wantToTalkMember": dictionary.shareTask.wantToTalkMember
            ]
            
            let cell: [String: Any] = [
                "taskId": dictionary.taskId,
                "taskName": dictionary.taskName,
                "notifyTime": dictionary.notifyTime,
                "timeSchedule": dictionary.timeSchedule,
                "taskLimit": dictionary.taskLimit,
                "isFinish": dictionary.isFinish,
                "createDate": dictionary.createDate,
                "shareTask": shareTask
            ]
            data.append(cell)
        }
        
        UserDefaults.standard.setValue(data, forKey: "myTasks")
        
    }
    
    
    private func changeTaskToUserdefaults(tasks: [Task]) {
        
        var data = [[String: Any]]()
        for dictionary in tasks {
            
            let shareTask: [String: Any] = [
                "documentPath": dictionary.shareTask.documentPath,
                "memberCount": dictionary.shareTask.memberCount,
                "makedEmail": dictionary.shareTask.makedEmail,
                "doneMember": dictionary.shareTask.doneMember,
                "gettingMember": dictionary.shareTask.gettingMember,
                "wantToTalkMember": dictionary.shareTask.wantToTalkMember
            ]
            
            let cell: [String: Any] = [
                "taskId": dictionary.taskId,
                "taskName": dictionary.taskName,
                "notifyTime": dictionary.notifyTime,
                "timeSchedule": dictionary.timeSchedule,
                "taskLimit": dictionary.taskLimit,
                "isFinish": dictionary.isFinish,
                "createDate": dictionary.createDate,
                "shareTask": shareTask
            ]
            data.append(cell)
        }
        
        UserDefaults.standard.setValue(data, forKey: "myTasks")
        
    }
    
    
    private func fetchTasksFromUserdefaults() -> [Task] {
        if let data = UserDefaults.standard.value(forKey: "myTasks") as? [[String: Any]] {
            var results = [Task]()
            for dictionary in data {
                
                if let taskId = dictionary["taskId"] as? String,
                   let taskName = dictionary["taskName"] as? String,
                   let notifyTime = dictionary["notifyTime"] as? String,
                   let taskLimit = dictionary["taskLimit"] as? String,
                   let createDate = dictionary["createDate"] as? Date,
                   let timeSchedule = dictionary["timeSchedule"] as? String,
                   let isFinish = dictionary["isFinish"] as? Bool,
                   let sharetask = dictionary["shareTask"] as? [String: Any],
                   let documentPath = sharetask["documentPath"] as? String,
                   let memberCount = sharetask["memberCount"] as? Int,
                   let makedEmail = sharetask["makedEmail"] as? String,
                   let doneMember = sharetask["doneMember"] as? [String],
                   let gettingMember = sharetask["gettingMember"] as? [String],
                   let wantToTalkMember = sharetask["wantToTalkMember"] as? [String]
                {
                    let shareTask = ShareTask(documentPath: documentPath, memberCount: memberCount, makedEmail: makedEmail, doneMember: doneMember, gettingMember: gettingMember, wantToTalkMember: wantToTalkMember)
                    let cell = Task(taskId: taskId, taskName: taskName, notifyTime: notifyTime, timeSchedule: timeSchedule, taskLimit: taskLimit, createDate: createDate, isFinish: isFinish, shareTask: shareTask)
                    results.append(cell)
                }
                else {
                    return results
                }
            }
            results.sort { (a, b) -> Bool in
                a.taskLimit < b.taskLimit
            }
            return results
        }
        else{
            return []
        }
    }
    
    
    
}



extension TimeSchedule: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return myTimeSchedule.timeTable.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "timeScheduleCell", for: indexPath) as! TimeScheduleCollectionViewCell
        if myTimeSchedule.timeTable[indexPath.row].subject == "" && myTimeSchedule.timeTable[indexPath.row].teacher == "" {
            cell.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        }
        else {
            if myTimeSchedule.timeTable[indexPath.row].color == "pink" {
                cell.backgroundColor = UIColor(red: 255/255, green: 189/255, blue: 227/255, alpha: 1)
            }
            if myTimeSchedule.timeTable[indexPath.row].color == "green" {
                cell.backgroundColor = UIColor(red: 204/255, green: 255/255, blue: 179/255, alpha: 1)
            }
            if myTimeSchedule.timeTable[indexPath.row].color == "blue" {
                cell.backgroundColor = UIColor(red: 179/255, green: 217/255, blue: 255/255, alpha: 1)
            }
            cell.layer.borderWidth = 1
            cell.layer.borderColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5).cgColor
        }
        let model = myTimeSchedule.timeTable[indexPath.row]
        cell.configure(model: model)
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if mySafeEmail != friendEmail && fromProfileVC == true {
            return
        }
        let info = myTimeSchedule.timeTable[indexPath.row]
        let changeVC = ChageTimeScheduleViewController(info: info, array: myTimeSchedule)
        changeVC.completionChange = { [weak self] changeCell in
            self?.myTimeSchedule.timeTable[changeCell.number].color = changeCell.color
            self?.myTimeSchedule.timeTable[changeCell.number].subject = changeCell.subject
            self?.myTimeSchedule.timeTable[changeCell.number].teacher = changeCell.teacher
            self?.myTimeSchedule.timeTable[changeCell.number].place = changeCell.place
            self?.collectionView.reloadData()
        }
        let nav = UINavigationController(rootViewController: changeVC)
        present(nav, animated: true, completion: nil)
          
    }
    
}



// MARK: - todoのTABLEVIEW
extension TimeSchedule: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoTableViewCell", for: indexPath) as! TodoTableViewCell
        cell.selectionStyle = .none
        
        if tasks[indexPath.row].isFinish == true {
            cell.checkButton.isHidden = false
            
            let text = tasks[indexPath.row].taskName
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: text)
            // 全体に共通して付けたいレイアウトを設定
            attributeString.addAttribute(.font,value: UIFont.systemFont(ofSize: 17), range: NSMakeRange(0, attributeString.length))
            
            // 取り消し線部分の設定
            attributeString.addAttributes([
                .foregroundColor : UIColor.darkGray,
                .strikethroughStyle: 1
            ], range: NSMakeRange(0, attributeString.length))
            cell.todoName.attributedText = attributeString
        }
        else {
            cell.checkButton.isHidden = true
            
            let text = tasks[indexPath.row].taskName
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: text)
            // 全体に共通して付けたいレイアウトを設定
            attributeString.addAttribute(.font,value: UIFont.systemFont(ofSize: 17), range: NSMakeRange(0, attributeString.length))
            
            attributeString.addAttributes([
                .foregroundColor : UIColor.darkGray,
                .strikethroughStyle: 1
            ], range: NSMakeRange(0, 0))
            cell.todoName.attributedText = attributeString
        }
        
        cell.bigFinishButton.tag = indexPath.row
        cell.bigFinishButton.addTarget(self, action: #selector(tappedFinishButton), for: .touchUpInside)
        
        
        let task = tasks[indexPath.row]
        cell.configureTodo(task: task)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.estimatedRowHeight
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    // スワイプした時に表示するアクションの定義
      func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard UserDefaults.standard.object(forKey: "name") != nil else {
            alertMessage(alertMessage: "ホームをタップして、プロフィールを完成させよう")
            return nil
        }
            

        // 編集処理
        var shareTitle = "シェアする"
        if tasks[indexPath.row].shareTask.memberCount != 0 {
            shareTitle = "シェア中"
        }
        let editAction = UIContextualAction(style: .normal, title: shareTitle) { [weak self] (action, view, completionHandler) in
          // 編集処理を記述
            guard let strongSelf = self else { return }
            if strongSelf.tasks[indexPath.row].shareTask.memberCount != 0 {
                strongSelf.makeAlert(title: "すでにシェアしています", isAddAction: true)
                return
            }
            strongSelf.tasks[indexPath.row].shareTask.memberCount = 1
            strongSelf.changeTaskToUserdefaults(tasks: strongSelf.tasks)
            strongSelf.todoTableView.reloadData()
            strongSelf.insertNewtodo(indexpath: indexPath.row)
            strongSelf.insertTodoPost(indexpath: indexPath.row)
            
            // 実行結果に関わらず記述
            completionHandler(true)
        }

       // 削除処理
        let deleteAction = UIContextualAction(style: .destructive, title: "delete") { [weak self] (action, view, completionHandler) in
            //削除処理を記述
            guard let strongSelf = self else { return }
            
            strongSelf.tasks.remove(at: indexPath.row)
            strongSelf.changeTaskToUserdefaults(tasks: strongSelf.tasks)
            strongSelf.todoTableView.reloadData()
            
            // 実行結果に関わらず記述
            completionHandler(true)
        }
        
        editAction.backgroundColor = UIColor(red: 204/255, green: 255/255, blue: 179/255, alpha: 1)
        editAction.image = UIImage(systemName: "paperplane.circle")

        // 定義したアクションをセット
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
      }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            tasks.remove(at: indexPath.row)
            changeTaskToUserdefaults(tasks: tasks)
            tableView.deleteRows(at: [indexPath], with: .left)
            tableView.endUpdates()
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tasks[indexPath.row].shareTask.memberCount != 0 else {
            return
        }
        let storyboard: UIStoryboard = UIStoryboard(name: "ShareTodo", bundle: nil)
        let shareTodoViewController = storyboard.instantiateViewController(withIdentifier: "ShareTodoViewController") as! ShareTodoViewController
        shareTodoViewController.task = tasks[indexPath.row]
        shareTodoViewController.fromTimeScheduleVC = true
        navigationController?.pushViewController(shareTodoViewController, animated: true)
        
    }
    
    
    
    @objc private func tappedFinishButton(_ sender: UIButton) {
        let indexpath = sender.tag
        if tasks[indexpath].isFinish == true {
            // やっぱりタスク終わってない
            tasks[indexpath].isFinish = false
            todoTableView.reloadRows(at: [IndexPath(row: indexpath, section: 0)], with: .none)
            changeTaskToUserdefaults(tasks: tasks)
            
            // タスク共有している場合
            if tasks[indexpath].shareTask.memberCount != 0 {
                DatabaseManager.shared.insertGettingTask(email: mySafeEmail, task: tasks[indexpath])
            }
        }
        else {
            // タスク完了
            tasks[indexpath].isFinish = true
            todoTableView.reloadRows(at: [IndexPath(row: indexpath, section: 0)], with: .none)
            changeTaskToUserdefaults(tasks: tasks)
            
            // タスク共有している場合
            if tasks[indexpath].shareTask.memberCount != 0 {
                DatabaseManager.shared.insertFinishTask(email: mySafeEmail, task: tasks[indexpath])
            }
        }
    }
    
    
    
    private func insertNewtodo(indexpath: Int) {
        DatabaseManager.shared.insertNewTodo(task: tasks[indexpath]) { (success) -> (Void) in
            if success == true {
                print("shared task")
            }
            else {
                print("failed to share")
            }
        }
    }
    
    
    private func insertTodoPost(indexpath: Int) {
        
        spinner.show(in: view)
        
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        format.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        let dateString = format.string(from: date)
        
        let dayformat = DateFormatter()
        dayformat.dateFormat = "yyMM"
        dayformat.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        let collectionString = dayformat.string(from: date)
        let ramdomID = randomString(length: 15)
        
        // ex) 140258_yusho-gmail-com_2210203
        let makePostId = "\(ramdomID)_1\(collectionString)"
        
        guard let myName = UserDefaults.standard.value(forKey: "name") as? String else { return }
        
        let bullutinTask = BullutinTask(taskId: tasks[indexpath].taskId, taskName: tasks[indexpath].taskName, taskLimit: tasks[indexpath].taskLimit, timeSchedule: tasks[indexpath].timeSchedule, documentPath: tasks[indexpath].shareTask.documentPath, memberCount: tasks[indexpath].shareTask.memberCount, makedEmail: tasks[indexpath].shareTask.makedEmail, doneMember: tasks[indexpath].shareTask.doneMember, gettingMember: tasks[indexpath].shareTask.gettingMember, wantToTalkMember: tasks[indexpath].shareTask.wantToTalkMember)
        
        let post = Post(postId: makePostId,
                        postMessage: "\(myName)さんが「\(tasks[indexpath].taskName)」の共有をしました。\nタップして参加してみよう",
                        postEmail: mySafeEmail,
                        postName: myName,
                        postTime: dateString,
                        good: 0, goodList: ["0_nil"], remessage: 0, remessagePostArray: ["0_nil"], isRemessage: nil, comment: 0,
                        photoUrl: nil, shareTask: bullutinTask)
       
        // taskの投稿
        DatabaseManager.shared.insertShareTask(post: post, dateForCollection: collectionString) { [weak self](success) -> (Void) in
            if success == true {
                self?.spinner.dismiss()
                self?.makeAlert(title: "タスクを共有しました", isAddAction: true)
            }
            else {
                self?.spinner.dismiss()
                print("fail to insert post to database (PostViewController image)")
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
    
    //ConversationVCの通知・既読
    private func startConversationsOtherVC() {
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        DatabaseManager.shared.getAllConversations(for: safeMyEmail) { [weak self](result) in
            switch result {
            case .success(let conversations1):
                guard !conversations1.isEmpty else {
                    return
                }
                
                var notReadNumber2 = 0
                for cell in conversations1 {
                    if cell.latest_message.isRead == false {
                        notReadNumber2 += 1
                    }
                }
                
                if notReadNumber2 == 0 {
                    // badgeオフ
                    UIApplication.shared.applicationIconBadgeNumber = 0
                }
                
                if notReadNumber2 != 0 {
                    if let tabItem = self?.tabBarController?.tabBar.items?[3] {
                        tabItem.badgeColor = UIColor.orange
                        tabItem.badgeValue = "\(notReadNumber2)"
                    }
                }
            case .failure(let err):
                print("Error (ConversationVC startListeningForConversations): \(err)")
            }
        }
    }
    
    //NotificationVCの通知
    private func startNotificationOtherVC() {
        DatabaseManager.shared.notification { [weak self](result) in
            switch result {
            case .success(let notificationNode):
                if notificationNode[0].isRead == false {
                    if let tabItem = self?.tabBarController?.tabBar.items?[2] {
                        tabItem.badgeValue = ""
                        tabItem.badgeColor = UIColor.orange
                    }
                }
            case .failure(_):
                print("error in notification [viewDidAppear]")
            }
        }
    }
    
}



// MARK: - TodoInputAccessoryViewからメッセージを受け取る
extension TimeSchedule: TodoInputAccessoryViewDelegate {
    
    
    func tapSaveButton(name: String, limit: String, notification: String, timeShedule: String) {
        
        if name == "" {
            todoInputAccessoryView.dismissKeyboard()
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .transitionCurlDown, animations: { [weak self] in
                self?.scrollView.contentOffset = CGPoint(x: 0, y: (self?.view.height ?? 0) - 200)
            })
            
        }
        else {
            let date = Date()
            
            if name == "" {
                makeAlert(title: "タスク名を設定してください", isAddAction: false)
            }
            else if notification == "" {
                let taskId = NSUUID().uuidString
                let notifyTime = notification
                var timeScheduleString = "none"
                if timeShedule != "" {
                    timeScheduleString = timeShedule
                }
                
                var year = "none"
                var uni = "none"
                var fac = "none"
                if let year1 = UserDefaults.standard.value(forKey: "year") as? String { year = year1 }
                if let uni1 = UserDefaults.standard.value(forKey: "uni") as? String { uni = uni1 }
                if let fac1 = UserDefaults.standard.value(forKey: "fac") as? String { fac = fac1 }
                
                
                let task = Task(taskId: taskId, taskName: name, notifyTime: notifyTime, timeSchedule: timeScheduleString, taskLimit: limit, createDate: date, isFinish: false, shareTask: ShareTask(documentPath: "\(uni)\(year)\(fac)", memberCount: 0, makedEmail: mySafeEmail, doneMember: [], gettingMember: [mySafeEmail], wantToTalkMember: []))
                
                todoInputAccessoryView.dismissKeyboard()
                todoInputAccessoryView.todoTextView.text = ""
                todoInputAccessoryView.todoLimitTextView.text = ""
                todoInputAccessoryView.notificationTextView.text = ""
                
                insertTaskToUserdefaults(model: task)
                tasks.append(task)
                tasks.sort { (a, b) -> Bool in
                    a.taskLimit < b.taskLimit
                }
                todoTableView.reloadData()
                
            }
            else {
                
                if limit == "" {
                    makeAlert(title: "期限を設定してください", isAddAction: false)
                    return
                }
                if (date > dateFormat(stringDate: limit)) {
                    makeAlert(title: "期限は現在時刻より遅くしてください", isAddAction: false)
                    return
                }
                
                
                let taskId = NSUUID().uuidString
                let notifyTime = notification
                var timeScheduleString = "none"
                if timeShedule != "" {
                    timeScheduleString = timeShedule
                }
                
                var year = "none"
                var uni = "none"
                var fac = "none"
                if let year1 = UserDefaults.standard.value(forKey: "year") as? String { year = year1 }
                if let uni1 = UserDefaults.standard.value(forKey: "uni") as? String { uni = uni1 }
                if let fac1 = UserDefaults.standard.value(forKey: "fac") as? String { fac = fac1 }
                
                
                let task = Task(taskId: taskId, taskName: name, notifyTime: notifyTime, timeSchedule: timeScheduleString, taskLimit: limit, createDate: date, isFinish: false, shareTask: ShareTask(documentPath: "\(uni)\(year)\(fac)", memberCount: 0, makedEmail: mySafeEmail, doneMember: [], gettingMember: [mySafeEmail], wantToTalkMember: []))
                
                todoInputAccessoryView.dismissKeyboard()
                todoInputAccessoryView.todoTextView.text = ""
                todoInputAccessoryView.todoLimitTextView.text = ""
                todoInputAccessoryView.notificationTextView.text = ""
                
                // 通知の作成
                createNotification(task: task)
                
                insertTaskToUserdefaults(model: task)
                tasks.append(task)
                tasks.sort { (a, b) -> Bool in
                    a.taskLimit < b.taskLimit
                }
                todoTableView.reloadData()
            }
        }
    }
    
    func createNotification(task : Task) {
        
        let content = UNMutableNotificationContent()
        content.title = "todoの設定時刻です"
        content.subtitle = ""
        content.body = task.taskName
        content.sound = UNNotificationSound.default
        
        // 期限の何分前に通知するかを設定する
        let time = createNotifyTime(task: task)
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: time!)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: task.taskId, content: content, trigger: trigger)
        
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    // 通知時間を期限から設定し直す
    func createNotifyTime(task: Task) -> Date! {
        let limitDate = dateFormat(stringDate: task.taskLimit)
        switch task.notifyTime {
        case "指定なし":
            return Calendar.current.date(byAdding: .minute, value: 0, to: limitDate!)
        case "10分前":
            return Calendar.current.date(byAdding: .minute, value: -10, to: limitDate!)
        case "30分前":
            return Calendar.current.date(byAdding: .minute, value: -30, to: limitDate!)
        case "1時間前":
            return Calendar.current.date(byAdding: .hour, value: -1, to: limitDate!)
        case "3時間前":
            return Calendar.current.date(byAdding: .hour, value: -3, to: limitDate!)
        case "6時間前":
            return Calendar.current.date(byAdding: .hour, value: -6, to: limitDate!)
        case "12時間前":
            return Calendar.current.date(byAdding: .hour, value: -12, to: limitDate!)
        case "1日前":
            return Calendar.current.date(byAdding: .day, value: -1, to: limitDate!)
        case "2日前":
            return Calendar.current.date(byAdding: .day, value: -2, to: limitDate!)
        case "3日前":
            return Calendar.current.date(byAdding: .day, value: -3, to: limitDate!)
        default:
            return Calendar.current.date(byAdding: .minute, value: 0, to: limitDate!)
        }
    }
    
    
    // アラートを作成する
    func makeAlert(title: String, isAddAction: Bool) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alert.title = title
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if (isAddAction) {
                self.navigationController?.popViewController(animated: true)
            }
        }))
        present(alert,animated: true)
    }
    
}





// MARK: - Buttonがタップしたらキーボードが上がる

class RespondingButton: UIButton, UIKeyInput {

    override var canBecomeFirstResponder: Bool {
        return true
    }

    var hasText: Bool = true
    func insertText(_ text: String) {}
    func deleteBackward() {}
}
