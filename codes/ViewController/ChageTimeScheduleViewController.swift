//
//  ChageTimeScheduleViewController.swift
//  Match
//
//  on 2021/01/10.
//


import UIKit
import UserNotifications


struct Task {
    let taskId: String
    let taskName: String
    let notifyTime: String
    let timeSchedule: String
    var taskLimit: String
    let createDate: Date // イギリス時間
    var isFinish: Bool
    var shareTask: ShareTask
}


struct ShareTask {
    let documentPath: String //"\(uni)\(year)\(fac)"
    var memberCount: Int
    let makedEmail: String
    var doneMember: [String]
    var gettingMember: [String]
    var wantToTalkMember: [String]
}



class ChageTimeScheduleViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    
    let cellNumber: Int
    var original: TimeScheduleContainer
    var color: String
    public var completionChange: ((TimeScheduleStruct) -> (Void))?
    
//    private var tasks = [Task]()
    private var safeMyEmail = ""
    private var taskTimeSchedule = ""
    
//    private let accessoryHeight: CGFloat = 150
//    private var isToTextView = false
    
    
    
    private let allContainerScroll: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    private let subjectText: UITextField = {
        let text = UITextField()
        text.autocapitalizationType = .none
        text.autocorrectionType = .no
        text.returnKeyType = .continue
        text.backgroundColor = .secondarySystemBackground
        text.layer.cornerRadius = 10
        text.layer.borderWidth = 1
        text.layer.borderColor = UIColor.lightGray.cgColor
        text.placeholder = "科目"
        text.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        text.leftViewMode = .always
        return text
    }()
    
    private let placeText: UITextField = {
        let text = UITextField()
        text.autocapitalizationType = .none
        text.autocorrectionType = .no
        text.returnKeyType = .continue
        text.backgroundColor = .secondarySystemBackground
        text.layer.cornerRadius = 10
        text.layer.borderWidth = 1
        text.layer.borderColor = UIColor.lightGray.cgColor
        text.placeholder = "教室"
        text.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        text.leftViewMode = .always
        return text
    }()
    
    private let teacherText: UITextField = {
        let text = UITextField()
        text.autocapitalizationType = .none
        text.autocorrectionType = .no
        text.returnKeyType = .continue
        text.backgroundColor = .secondarySystemBackground
        text.layer.cornerRadius = 10
        text.layer.borderWidth = 1
        text.layer.borderColor = UIColor.lightGray.cgColor
        text.placeholder = "教員"
        text.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        text.leftViewMode = .always
        return text
    }()
    
    private let colorLabel: UILabel = {
        let label = UILabel()
        label.text = "color: "
        label.font = .systemFont(ofSize: 18)
        return label
    }()
    
    private let pinkButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(red: 255/255, green: 189/255, blue: 227/255, alpha: 1)
        return button
    }()
    
    private let greenButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(red: 204/255, green: 255/255, blue: 179/255, alpha: 1)
        return button
    }()
    
    private let blueButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(red: 179/255, green: 217/255, blue: 255/255, alpha: 1)
        return button
    }()
    private let checkOnPink: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(systemName: "checkmark")
        image.tintColor = .black
        image.isHidden = true
        return image
    }()
    private let checkOnGreen: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(systemName: "checkmark")
        image.tintColor = .black
        return image
    }()
    private let checkOnBlue: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(systemName: "checkmark")
        image.tintColor = .black
        image.isHidden = true
        return image
    }()
    
    /*
    private let tableView: UITableView = {
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
    private let todoLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    
    private lazy var todoInputAccessoryView: TodoInputAccessary = {
        let view = TodoInputAccessary()
        view.frame = CGRect(x: 0, y: 0, width: view.width, height: accessoryHeight)
        
        // TodoInputAccessoryのメッセージをdelegateを使って受け取る
        // その後extensionで処理を書く
        view.delegate = self //privateではselfを呼び出せないので lazyをつける
        
        return view
    }()
 */
 
    private var safeAreaTop: CGFloat {
        view.safeAreaInsets.top
    }
    
    private var safeAreaBottom: CGFloat {
        // get {} の省略型
        view.safeAreaInsets.bottom
    }
    
    
    
    init(info: TimeScheduleStruct, array: TimeScheduleContainer) {
        self.cellNumber = info.number
        self.subjectText.text = info.subject
        self.teacherText.text = info.teacher
        self.placeText.text = info.place ?? ""
        self.color = info.color
        self.original = array
        
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        navigationItem.leftBarButtonItem =
            UIBarButtonItem(image: UIImage(systemName: "xmark"),
                            style: .done,
                            target: self,
                            action: #selector(dismissSelf))
        navigationItem.rightBarButtonItem =
            UIBarButtonItem(title: "保存",
                            style: .done,
                            target: self,
                            action: #selector(tappedRightBarButton))
        
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.tintColor = .label
        
        setupChangeTimeSchedule()
//        setupTodo()
        
        // todoを追加する
//        setUpNotification()
        
        let tapScroll = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        allContainerScroll.addGestureRecognizer(tapScroll)
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        
        view.addSubview(allContainerScroll)
        allContainerScroll.addSubview(subjectText)
        allContainerScroll.addSubview(placeText)
        allContainerScroll.addSubview(teacherText)
        allContainerScroll.addSubview(colorLabel)
        allContainerScroll.addSubview(pinkButton)
        allContainerScroll.addSubview(greenButton)
        allContainerScroll.addSubview(blueButton)
        pinkButton.addSubview(checkOnPink)
        greenButton.addSubview(checkOnGreen)
        blueButton.addSubview(checkOnBlue)
//        allContainerScroll.addSubview(todoLabel)
//        allContainerScroll.addSubview(addTodoButton)
//        allContainerScroll.addSubview(tableView)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        allContainerScroll.frame = CGRect(x: 0, y: 0, width: view.width, height: view.height)
        
        subjectText.frame = CGRect(x: 30, y: 40, width: view.width - 70, height: 45)
        placeText.frame = CGRect(x: 30, y: subjectText.bottom + 15, width: view.width - 70, height: 45)
        teacherText.frame = CGRect(x: 30, y: placeText.bottom + 15, width: view.width - 70, height: 45)
        colorLabel.frame = CGRect(x: view.width - 220, y: teacherText.bottom + 15, width: 55, height: 30)
        pinkButton.frame = CGRect(x: colorLabel.right + 10, y: teacherText.bottom + 15, width: 30, height: 30)
        greenButton.frame = CGRect(x: pinkButton.right + 10, y: teacherText.bottom + 15, width: 30, height: 30)
        blueButton.frame = CGRect(x: greenButton.right + 10, y: teacherText.bottom + 15, width: 30, height: 30)
        pinkButton.layer.cornerRadius = 15
        greenButton.layer.cornerRadius = 15
        blueButton.layer.cornerRadius = 15
        checkOnPink.frame = CGRect(x: 5, y: 5, width: 20, height: 20)
        checkOnGreen.frame = CGRect(x: 5, y: 5, width: 20, height: 20)
        checkOnBlue.frame = CGRect(x: 5, y: 5, width: 20, height: 20)
        
//        todoLabel.frame = CGRect(x: 30, y: colorLabel.bottom + 30, width: 170, height: 20)
//        todoLabel.text = "todoリスト"
//        todoLabel.font = .systemFont(ofSize: 16, weight: .semibold)
//        todoLabel.sizeToFit()
//        addTodoButton.frame = CGRect(x: todoLabel.right, y: colorLabel.bottom + 25, width: 30, height: 30)
//        addTodoButton.layer.cornerRadius = 15
//        tableView.frame = CGRect(x: 20, y: todoLabel.bottom + 10, width: view.width - 50, height: view.height - todoLabel.bottom - safeAreaBottom - 80)
        
    }
    
  
    

    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
  
    
    @objc private func dismissKeyboard() {
//        if isToTextView == true {
//            todoInputAccessoryView.dismissKeyboard()
//            UIView.animate(withDuration: 0.2, delay: 0.0, options: .transitionCurlDown, animations: { [weak self] in
//                self?.allContainerScroll.contentOffset = CGPoint(x: 0, y: -(self?.safeAreaTop ?? 60))
//            })
//        }
//        else {
            view.endEditing(true)
//        }
    }
    
    @objc private func tappedRightBarButton() {
        
        let changeCell = TimeScheduleStruct(number: cellNumber, color: color, subject: subjectText.text ?? "", teacher: teacherText.text ?? "", place: placeText.text ?? "")
        original.timeTable[cellNumber] = changeCell
        DatabaseManager.shared.insertTimeSchedule(myTimeSchedule: original) { (success) in
            if success == true {
                print("success to insert time schedule")
            }
            else {
                print("failed to insert time schedule")
            }
        }
        dismiss(animated: true) { [weak self] in
            self?.completionChange?(changeCell)
        }
    }
    
    
//    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
//
//        switch textField {
//        case teacherText:
//            isToTextView = false
//            todoInputAccessoryView.isHidden = true
//        case subjectText:
//            isToTextView = false
//            todoInputAccessoryView.isHidden = true
//        case placeText:
//            isToTextView = false
//            todoInputAccessoryView.isHidden = true
//        default:
//            isToTextView = true
//            todoInputAccessoryView.isHidden = false
//        }
//
//        return true
//    }
    
    
    
    // MARK: - SET UP TIMESCHEDULE
    
    private func setupChangeTimeSchedule() {
        
        pinkButton.addTarget(self, action: #selector(tapPinkButton), for: .touchUpInside)
        greenButton.addTarget(self, action: #selector(tapGreenButton), for: .touchUpInside)
        blueButton.addTarget(self, action: #selector(tapBlueButton), for: .touchUpInside)
//        addTodoButton.addTarget(self, action: #selector(addTodo), for: .touchUpInside)
        
        subjectText.delegate = self
        teacherText.delegate = self
        placeText.delegate = self
        
        let week = cellNumber % original.classDay
        let time = Int(cellNumber / original.classDay)
        var weekString = ""
        var timeString = ""
        if original.classDay == 5 {
            if week == 0 { weekString = "月曜日" }
            else if week == 1 { weekString = "火曜日" }
            else if week == 2 { weekString = "水曜日" }
            else if week == 3 { weekString = "木曜日" }
            else if week == 4 { weekString = "金曜日" }
        }
        if original.classDay == 6 {
            if week == 0 { weekString = "月曜日" }
            else if week == 1 { weekString = "火曜日" }
            else if week == 2 { weekString = "水曜日" }
            else if week == 3 { weekString = "木曜日" }
            else if week == 4 { weekString = "金曜日" }
            else if week == 5 { weekString = "土曜日" }
        }
        if original.classDay == 7 {
            if week == 0 { weekString = "月曜日" }
            else if week == 1 { weekString = "火曜日" }
            else if week == 2 { weekString = "水曜日" }
            else if week == 3 { weekString = "木曜日" }
            else if week == 4 { weekString = "金曜日" }
            else if week == 5 { weekString = "土曜日" }
            else if week == 6 { weekString = "日曜日" }
        }
        
        if original.classCount == 4{
            if time == 0 { timeString = "1限" }
            else if time == 1 { timeString = "2限" }
            else if time == 2 { timeString = "3限" }
            else if time == 3 { timeString = "4限" }
        }
        if original.classCount == 5{
            if time == 0 { timeString = "1限" }
            else if time == 1 { timeString = "2限" }
            else if time == 2 { timeString = "3限" }
            else if time == 3 { timeString = "4限" }
            else if time == 4 { timeString = "5限" }
        }
        if original.classCount == 6{
            if time == 0 { timeString = "1限" }
            else if time == 1 { timeString = "2限" }
            else if time == 2 { timeString = "3限" }
            else if time == 3 { timeString = "4限" }
            else if time == 4 { timeString = "5限" }
            else if time == 5 { timeString = "6限" }
        }
        if original.classCount == 7{
            if time == 0 { timeString = "1限" }
            else if time == 1 { timeString = "2限" }
            else if time == 2 { timeString = "3限" }
            else if time == 3 { timeString = "4限" }
            else if time == 4 { timeString = "5限" }
            else if time == 5 { timeString = "6限" }
            else if time == 6 { timeString = "7限" }
        }
        if color == "pink" {
            checkOnPink.isHidden = false
            checkOnGreen.isHidden = true
            checkOnBlue.isHidden = true
        }
        if color == "green" {
            checkOnPink.isHidden = true
            checkOnGreen.isHidden = false
            checkOnBlue.isHidden = true
        }
        if color == "blue" {
            checkOnPink.isHidden = true
            checkOnGreen.isHidden = true
            checkOnBlue.isHidden = false
        }
        
        title = "\(weekString) \(timeString)"
        taskTimeSchedule = "\(weekString) \(timeString)"
        
    }
    
    /*
    // MARK: - SET UP TODO
    
    private func setupTodo() {
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        // タスクに今までのタスクを追加
        let allTasks = fetchTasksFromUserdefaults()
        for task in allTasks {
            guard let titleString = title else { return }
            if task.timeSchedule == titleString {
                tasks.append(task)
            }
        }
        tableView.reloadData()
    }
    */
    
    
    @objc private func tapPinkButton() {
        color = "pink"
        checkOnPink.isHidden = false
        checkOnGreen.isHidden = true
        checkOnBlue.isHidden = true
    }
    @objc private func tapGreenButton() {
        color = "green"
        checkOnPink.isHidden = true
        checkOnGreen.isHidden = false
        checkOnBlue.isHidden = true
    }
    @objc private func tapBlueButton() {
        color = "blue"
        checkOnPink.isHidden = true
        checkOnGreen.isHidden = true
        checkOnBlue.isHidden = false
    }
    
    
    /*
    
    // MARK: - ADD TODO
    
    @objc private func addTodo() {

        isToTextView = true
        todoInputAccessoryView.isHidden = false

        addTodoButton.becomeFirstResponder()
        todoInputAccessoryView.todoTextView.becomeFirstResponder()
        todoInputAccessoryView.timeSheduleTextView.text = title

    }
   
    
    // MARK: - キーボードが上がるとメッセージも上に上がる処理
    private func setUpNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {

        guard isToTextView == true else { return }

        //自動的にtodoを上にあげる
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .transitionCurlDown, animations: { [weak self] in
            self?.allContainerScroll.contentOffset = CGPoint(x: 0, y: 160)
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
    
    
    func createNotification(task : Task) {
        
        let content = UNMutableNotificationContent()
        content.title = "todoの設定時刻です"
        content.subtitle = ""
        content.body = task.taskName
        content.sound = UNNotificationSound.default
        content.badge = 1
        
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
    
    
    
    // MARK: - USERDEFAULTSの取得や保存
    
    public func insertTaskToUserdefaults(model: Task) {
        
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
                "createDate": dictionary.createDate,
                "isFinish": dictionary.isFinish,
                "shareTask": shareTask
            ]
            data.append(cell)
        }
        
        UserDefaults.standard.setValue(data, forKey: "myTasks")
        
    }
    
    public func fetchTasksFromUserdefaults() -> [Task] {
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
                   let documentPath = dictionary["documentPath"] as? String,
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
                    return []
                }
            }
            results.sort { (a, b) -> Bool in
                a.createDate < b.createDate
            }
            return results
        }
        else{
            return []
        }
    }
    
 */

}



/*

// MARK: - todoのtableView
extension ChageTimeScheduleViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoTableViewCell", for: indexPath) as! TodoTableViewCell
        cell.selectionStyle = .none
        
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
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "削除"
    }
    
    
    // セルをタップする際にはRealmの情報を編集画面に渡す
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        performSegue(withIdentifier: "edit", sender: self)
//        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}





// MARK: - TodoInputAccessoryViewからメッセージを受け取る
extension ChageTimeScheduleViewController: TodoInputAccessoryViewDelegate {
    
    
    func tapSaveButton(name: String, limit: String, notification: String, timeShedule: String) {
        
        isToTextView = false
        
        if name == "" {
            todoInputAccessoryView.dismissKeyboard()
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .transitionCurlDown, animations: { [weak self] in
                self?.allContainerScroll.contentOffset = CGPoint(x: 0, y: -(self?.safeAreaTop ?? 60))
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
                
                
                let task = Task(taskId: taskId, taskName: name, notifyTime: notifyTime, timeSchedule: timeScheduleString, taskLimit: limit, createDate: date, isFinish: false, shareTask: ShareTask(documentPath: "\(uni)\(year)\(fac)", memberCount: 0, makedEmail: safeMyEmail, doneMember: [], gettingMember: [safeMyEmail], wantToTalkMember: []))
                
                todoInputAccessoryView.dismissKeyboard()
                todoInputAccessoryView.todoTextView.text = ""
                todoInputAccessoryView.todoLimitTextView.text = ""
                todoInputAccessoryView.notificationTextView.text = ""
                UIView.animate(withDuration: 0.2, delay: 0.0, options: .transitionCurlDown, animations: { [weak self] in
                    self?.allContainerScroll.contentOffset = CGPoint(x: 0, y: -(self?.safeAreaTop ?? 60))
                })
                
                insertTaskToUserdefaults(model: task)
                tasks.append(task)
                tableView.reloadData()
                
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
                
                
                let task = Task(taskId: taskId, taskName: name, notifyTime: notifyTime, timeSchedule: timeScheduleString, taskLimit: limit, createDate: date, isFinish: false, shareTask: ShareTask(documentPath: "\(uni)\(year)\(fac)", memberCount: 0, makedEmail: safeMyEmail, doneMember: [], gettingMember: [safeMyEmail], wantToTalkMember: []))
                
                todoInputAccessoryView.dismissKeyboard()
                todoInputAccessoryView.todoTextView.text = ""
                todoInputAccessoryView.todoLimitTextView.text = ""
                todoInputAccessoryView.notificationTextView.text = ""
                UIView.animate(withDuration: 0.2, delay: 0.0, options: .transitionCurlDown, animations: { [weak self] in
                    self?.allContainerScroll.contentOffset = CGPoint(x: 0, y: -(self?.safeAreaTop ?? 60))
                })
                
                // 通知の作成
                createNotification(task: task)
                
                insertTaskToUserdefaults(model: task)
                tasks.append(task)
                tableView.reloadData()
            }
        }
        
        
    }
    
}

*/
