//
//  ShareTodoViewController.swift
//  match
//
//  on 2021/03/06.
//

import UIKit

class ShareTodoViewController: UIViewController {
    
    public var task = Task(taskId: "", taskName: "", notifyTime: "", timeSchedule: "", taskLimit: "", createDate: Date(), isFinish: false, shareTask: ShareTask(documentPath: "", memberCount: 0, makedEmail: "", doneMember: [""], gettingMember: [""], wantToTalkMember: [""]))
    private var myAllTasks = [Task]()
    private var myTaskIndex: Int?
    private var delateAfter = false //timeScheduleで左スワイプで消した場合
    
    public var fromTimeScheduleVC = false
    private var haveThisTask = true
    private var whichTable = 0 // 0がfinish, 1がwantToTalk, 2がgetting
    private var preTable = 0
    private var safeMyEmail = ""
    private var isFirstFlow = true
    
    let underlineLayer = CALayer()
    var segmentItemWidth: CGFloat = 0
    
    
    @IBOutlet weak var allContainer: UIView!
    @IBOutlet weak var todoContainer: UIView!
    @IBOutlet weak var todoNameTextView: UITextView!
    @IBOutlet weak var todoNameTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var todoLimitLabel: UILabel!
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var wantToTalkButton: UIButton!
    @IBOutlet weak var gettingButton: UIButton!
    
    @IBOutlet weak var memberSegmentedControll: UISegmentedControl!
    @IBOutlet weak var finishMemeberCountLabel: UILabel!
    
    
    
    private let finishTableView: UITableView = {
        let table = UITableView()
        table.register(GoodListTableViewCell.self, forCellReuseIdentifier: "shareTodoCell")
        return table
    }()
    
    private let shareTaskButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "paperplane.circle"), for: .normal)
        button.tintColor = UIColor(named: "gentle")
        button.imageView?.contentMode = .scaleAspectFit
        button.backgroundColor = UIColor(red: 204/255, green: 255/255, blue: 179/255, alpha: 1)
        return button
    }()
    
    private let joinTaskButton: UIButton = {
        let button = UIButton()
        button.setTitle("参加する", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.isHidden = true
        button.backgroundColor = UIColor(red: 204/255, green: 255/255, blue: 179/255, alpha: 1)
        return button
    }()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        finishTableView.delegate = self
        finishTableView.dataSource = self
        
        allContainer.addSubview(finishTableView)
        allContainer.addSubview(shareTaskButton)
        todoContainer.addSubview(joinTaskButton)
        
        if let myEmail = UserDefaults.standard.value(forKey: "email") as? String {
            let email = DatabaseManager.safeEmail(emailAddress: myEmail)
            safeMyEmail = email
        }
        
        DatabaseManager.shared.fetchTargetTask(task: task) { [weak self](result) -> (Void) in
            switch result {
            case .success(let resultArray):
                self?.task.shareTask = resultArray.shareTask
                self?.task.taskLimit = resultArray.taskLimit
                self?.changeOtherMember()
            case .failure(let error):
                print("failed to fetch task: \(error)")
            }
        }
        
        shareTaskButton.addTarget(self, action: #selector(tapSahreTaskButton), for: .touchUpInside)
        joinTaskButton.addTarget(self, action: #selector(tapJoinTaskButton), for: .touchUpInside)
        
        if haveThisTask == true {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(tapEllipsis))
        }
        
        memberSegmentedControll.selectedSegmentIndex = 0
        memberSegmentedControll.frame.size.width = view.width
        memberSegmentedControll.frame.size.height = 30
        memberSegmentedControll.tintColor = .label
        
        segmentItemWidth = view.width*0.333
        underlineLayer.backgroundColor = UIColor(red: 204/255, green: 255/255, blue: 179/255, alpha: 1).cgColor
        underlineLayer.frame = CGRect(x: 10, y: 25, width: view.width*0.333 - 20, height: 2)
        memberSegmentedControll.layer.addSublayer(underlineLayer)
        memberSegmentedControll.iOS12Style()
        
        navigationController?.navigationBar.tintColor = UIColor(named: "gentle")
        navigationController?.navigationBar.barTintColor = UIColor(named: "appBackground")
        
        if fromTimeScheduleVC == false {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "multiply"), style: .done, target: self, action: #selector(dismissSelf))
        }
        else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: " ← ",
                                                               style: .done,
                                                               target: self,
                                                               action: #selector(popToVC))
        }
        
        
        myAllTasks = fetchTasksFromUserdefaults()
        var i = 0
        for cell in  myAllTasks {
            if cell.taskId == task.taskId {
                // 登録済みのタスク
                myTaskIndex = i
                task.isFinish = cell.isFinish
                // ここにリターンがあるよ
                return
            }
            i += 1
        }
        haveThisTask = false
        // returnされているよ
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        
        guard isFirstFlow == true else {
            return
        }
        isFirstFlow = false
        
        let tableViewTop = finishMemeberCountLabel.bottom
        finishTableView.frame = CGRect(x: 0,
                                       y: tableViewTop + 5,
                                       width: view.width,
                                       height: allContainer.height - tableViewTop - 15)
        shareTaskButton.frame = CGRect(x: allContainer.width - 75,
                                       y: allContainer.height - 75,
                                       width: 50,
                                       height: 50)
        shareTaskButton.layer.cornerRadius = 25
        
        todoNameTextView.text = task.taskName
        todoLimitLabel.text = task.taskLimit
        finishButton.layer.cornerRadius = 5
        wantToTalkButton.layer.cornerRadius = 5
        gettingButton.layer.cornerRadius = 5
        
        if task.isFinish == true {
            finishButton.setTitleColor(.black, for: .normal)
            finishButton.backgroundColor = UIColor(red: 204/255, green: 255/255, blue: 179/255, alpha: 1)
            gettingButton.setTitleColor(.lightGray, for: .normal)
            gettingButton.backgroundColor = .clear
        }
        else {
            finishButton.setTitleColor(.lightGray, for: .normal)
            finishButton.backgroundColor = .clear
            gettingButton.setTitleColor(.black, for: .normal)
            gettingButton.backgroundColor = UIColor(red: 204/255, green: 255/255, blue: 179/255, alpha: 1)
        }
        
        if haveThisTask == false {
            finishButton.isHidden = true
            wantToTalkButton.isHidden = true
            gettingButton.isHidden = true
            joinTaskButton.isHidden = false
            
            joinTaskButton.frame = CGRect(x: 8,
                                          y: todoLimitLabel.bottom + 10,
                                          width: 90,
                                          height: 30)
            joinTaskButton.layer.cornerRadius = 5
        }
        
    }
    

    
    
    private func changeOtherMember() {
        for cell in task.shareTask.wantToTalkMember {
            if cell == safeMyEmail {
                wantToTalkButton.setTitleColor(.black, for: .normal)
                wantToTalkButton.backgroundColor = UIColor(red: 204/255, green: 255/255, blue: 179/255, alpha: 1)
                break
            }
        }
        finishMemeberCountLabel.text = "\(task.shareTask.doneMember.count)/\(task.shareTask.memberCount)人"
        finishTableView.reloadData()
        if haveThisTask == false {
            for cell in task.shareTask.doneMember {
                if cell == safeMyEmail {
                    finishButton.isHidden = false
                    wantToTalkButton.isHidden = false
                    gettingButton.isHidden = false
                    joinTaskButton.isHidden = true
                    haveThisTask = true
                    delateAfter = true
                    
                    finishButton.setTitleColor(.black, for: .normal)
                    gettingButton.backgroundColor = .clear
                    finishButton.backgroundColor = UIColor(red: 204/255, green: 255/255, blue: 179/255, alpha: 1)
                    gettingButton.setTitleColor(.lightGray, for: .normal)
                    return //ここにリターンがあるよ
                }
            }
            for cell in task.shareTask.gettingMember {
                if cell == safeMyEmail {
                    finishButton.isHidden = false
                    wantToTalkButton.isHidden = false
                    gettingButton.isHidden = false
                    joinTaskButton.isHidden = true
                    haveThisTask = true
                    delateAfter = true
                    return //ここにリターンがあるよ
                }
            }
        }
        
    }
    
    
    @objc private func popToVC() {
        navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func tapSegmentedControll(_ sender: Any) {
        
        let x = CGFloat(memberSegmentedControll.selectedSegmentIndex) * segmentItemWidth
        underlineLayer.frame.origin.x = x + 10
        
        if memberSegmentedControll.selectedSegmentIndex == 0 {
            whichTable = 0
            finishMemeberCountLabel.text = "\(task.shareTask.doneMember.count)/\(task.shareTask.memberCount)人"
            finishTableView.reloadData()
        }
        else if memberSegmentedControll.selectedSegmentIndex == 1 {
            whichTable = 1
            finishMemeberCountLabel.text = "\(task.shareTask.wantToTalkMember.count)/\(task.shareTask.memberCount)人"
            finishTableView.reloadData()
        }
        else {
            whichTable = 2
            finishMemeberCountLabel.text = "\(task.shareTask.gettingMember.count)/\(task.shareTask.memberCount)人"
            finishTableView.reloadData()
        }
        
    }
    
    
    @IBAction func tapFinishButton(_ sender: Any) {
        
        guard delateAfter == false else {
            userMessage(alertMessage: "右上のアイコンをタップしてください")
            return
        }
        guard task.isFinish == false else { return }
        
        finishButton.setTitleColor(.black, for: .normal)
        gettingButton.backgroundColor = .clear
        myAllTasks[myTaskIndex!].isFinish = true
        changeTaskToUserdefaults(tasks: myAllTasks)
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.1, initialSpringVelocity: 0.0, options: .curveEaseOut, animations: {
            [weak self] in
            self?.finishButton.transform = CGAffineTransform(scaleX: 1.07, y: 1.07)
        }, completion: { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.finishButton.transform = .identity
            strongSelf.finishButton.backgroundColor = UIColor(red: 204/255, green: 255/255, blue: 179/255, alpha: 1)
            strongSelf.gettingButton.setTitleColor(.lightGray, for: .normal)
            strongSelf.task.isFinish = true
            strongSelf.task.shareTask.doneMember.append(strongSelf.safeMyEmail)
            
            var i = 0
            for cell in strongSelf.task.shareTask.gettingMember {
                if strongSelf.safeMyEmail == cell {
                    strongSelf.task.shareTask.gettingMember.remove(at: i)
                }
                i += 1
            }
            DatabaseManager.shared.insertFinishTask(email: strongSelf.safeMyEmail, task: strongSelf.task)
            if strongSelf.whichTable == 0 {
                strongSelf.finishMemeberCountLabel.text = "\(strongSelf.task.shareTask.doneMember.count)/\(strongSelf.task.shareTask.memberCount)人"
            }
            strongSelf.finishTableView.reloadData()
        })
        
    }
    
    
    @IBAction func tapWantToTalkButton(_ sender: Any) {
        
        guard delateAfter == false else {
            userMessage(alertMessage: "右上のアイコンをタップしてください")
            return
        }
        
        var i = 0
        for email in task.shareTask.wantToTalkMember {
            if email == safeMyEmail {
                wantToTalkButton.setTitleColor(.lightGray, for: .normal)
                wantToTalkButton.backgroundColor = .clear
                task.shareTask.wantToTalkMember.remove(at: i)
                finishTableView.reloadData()
                DatabaseManager.shared.removeWantToTalk(email: safeMyEmail, task: task)
                return
            }
            i += 1
        }
        
        wantToTalkButton.setTitleColor(.black, for: .normal)
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.1, initialSpringVelocity: 0.0, options: .curveLinear, animations: {
            [weak self] in
            self?.wantToTalkButton.transform = CGAffineTransform(scaleX: 1.07, y: 1.07)
        }, completion: { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.wantToTalkButton.transform = .identity
            strongSelf.wantToTalkButton.backgroundColor = UIColor(red: 204/255, green: 255/255, blue: 179/255, alpha: 1)
            strongSelf.task.shareTask.wantToTalkMember.append(strongSelf.safeMyEmail)
            strongSelf.finishTableView.reloadData()
            DatabaseManager.shared.insertWantToTalk(email: strongSelf.safeMyEmail, task: strongSelf.task)
        })
    }
    
    @IBAction func tapGettingButton(_ sender: Any) {
        
        guard delateAfter == false else {
            userMessage(alertMessage: "右上のアイコンをタップしてください")
            return
        }
        guard task.isFinish == true else { return }
        
        myAllTasks[myTaskIndex!].isFinish = false
        changeTaskToUserdefaults(tasks: myAllTasks)
        gettingButton.backgroundColor = UIColor(red: 204/255, green: 255/255, blue: 179/255, alpha: 1)
        gettingButton.setTitleColor(.black, for: .normal)
        finishButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        finishButton.setTitleColor(.lightGray, for: .normal)
        finishTableView.reloadData()
        
        DatabaseManager.shared.insertGettingTask(email: safeMyEmail, task: task)
    }
    
    
    
    @objc private func tapSahreTaskButton() {
        
        let storyboard: UIStoryboard = UIStoryboard(name: "PostView", bundle: nil)
        let post = storyboard.instantiateViewController(withIdentifier: "seguePost") as! PostViewController
        post.isShareTask = true
        post.shareTask = BullutinTask(taskId: task.taskId, taskName: task.taskName, taskLimit: task.taskLimit, timeSchedule: task.timeSchedule, documentPath: task.shareTask.documentPath, memberCount: task.shareTask.memberCount, makedEmail: task.shareTask.makedEmail, doneMember: task.shareTask.doneMember, gettingMember: task.shareTask.gettingMember, wantToTalkMember: task.shareTask.wantToTalkMember)
        
        post.completionPost = { [weak self] (success) in
            if success == true {
                self?.userMessage(alertMessage: "todoを共有しました")
            }
        }
        let nav = UINavigationController(rootViewController: post)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
        
    }
    
    
    // MARK: - タスクに参加
    @objc private func tapJoinTaskButton() {
        
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.05, initialSpringVelocity: 0.0, options: .curveEaseOut, animations: {
            [weak self] in
            self?.joinTaskButton.transform = CGAffineTransform(scaleX: 1.07, y: 1.07)
        }, completion: { [weak self] _ in
            guard let strongSelf = self else { return }
            
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 0.0, options: .curveEaseOut, animations: {
                [weak self] in
                self?.joinTaskButton.center.y -= 230.0
                self?.joinTaskButton.alpha = 0.3
            }, completion: { _ in
                strongSelf.finishButton.isHidden = false
                strongSelf.wantToTalkButton.isHidden = false
                strongSelf.gettingButton.isHidden = false
                strongSelf.joinTaskButton.isHidden = true
                strongSelf.haveThisTask = true
                
                DatabaseManager.shared.joinTargetTask(email: strongSelf.safeMyEmail, task: strongSelf.task)
                strongSelf.task.shareTask.memberCount += 1
                strongSelf.task.shareTask.gettingMember.append(strongSelf.safeMyEmail)
                strongSelf.insertTaskToUserdefaults(model: strongSelf.task)
                strongSelf.myTaskIndex = strongSelf.myAllTasks.count
                strongSelf.myAllTasks.append(strongSelf.task)
                if strongSelf.whichTable == 0 {
                    strongSelf.finishMemeberCountLabel.text = "\(strongSelf.task.shareTask.doneMember.count)/\(strongSelf.task.shareTask.memberCount)人"
                }
                else if strongSelf.whichTable == 1 {
                    strongSelf.finishMemeberCountLabel.text = "\(strongSelf.task.shareTask.wantToTalkMember.count)/\(strongSelf.task.shareTask.memberCount)人"
                }
                else {
                    strongSelf.finishMemeberCountLabel.text = "\(strongSelf.task.shareTask.gettingMember.count)/\(strongSelf.task.shareTask.memberCount)人"
                }
                strongSelf.finishTableView.reloadData()
            })
            
        })
        
    }
    
    
    @objc private func tapEllipsis() {
        
        let actionSheet = UIAlertController(title: "",
                                            message: "",
                                            preferredStyle: .actionSheet)
        if delateAfter == true {
            actionSheet.addAction(UIAlertAction(title: "このタスクに再参加", style: .default, handler: { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.insertTaskToUserdefaults(model: strongSelf.task)
                strongSelf.myTaskIndex = strongSelf.myAllTasks.count
                strongSelf.myAllTasks.append(strongSelf.task)
                strongSelf.delateAfter = false
                strongSelf.userMessage(alertMessage: "参加しました")
            }))
        }
        actionSheet.addAction(UIAlertAction(title: "このタスクを抜ける", style: .default, handler: { [weak self] _ in
            guard let strongSelf = self else { return }
            DatabaseManager.shared.removeTask(email: strongSelf.safeMyEmail, task: strongSelf.task)
            var myTasks = strongSelf.fetchTasksFromUserdefaults()
            var i = 0
            for cell in myTasks {
                if cell.taskId == strongSelf.task.taskId {
                    myTasks.remove(at: i)
                    strongSelf.changeTaskToUserdefaults(tasks: myTasks)
                    break
                }
                i += 1
            }
            if strongSelf.fromTimeScheduleVC == true {
                let nav = self?.navigationController
                let timeScheduleVC = nav?.viewControllers[(nav?.viewControllers.count)!-2] as! TimeSchedule
                timeScheduleVC.setTodo()
                strongSelf.popToVC()
            }
            else {
                strongSelf.dismiss(animated: true, completion: nil)
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "キャンセル",
                                            style: .cancel,
                                            handler: nil))
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            actionSheet.popoverPresentationController?.sourceView = self.view
            let screenSize = UIScreen.main.bounds
            actionSheet.popoverPresentationController?.sourceRect = CGRect(x: screenSize.size.width/2, y: screenSize.size.height, width: 0, height: 0)
        }
        present(actionSheet, animated: true)
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    private func userMessage(alertMessage: String) {
        let alert = UIAlertController(title: "",
                                      message: alertMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true)
    }
    
    
    
    // MARK: - USERDEFAULTSの取得や保存
    
    private func insertTaskToUserdefaults(model: Task) {
        
        var fetchData = myAllTasks
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




extension ShareTodoViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if whichTable == 0 {
            return task.shareTask.doneMember.count
        }
        else if whichTable == 1 {
            return task.shareTask.wantToTalkMember.count
        }
        else {
            return task.shareTask.gettingMember.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if whichTable == 0 {
            let cell = finishTableView.dequeueReusableCell(withIdentifier: "shareTodoCell", for: indexPath) as! GoodListTableViewCell
            cell.selectionStyle = .none
            let model = task.shareTask.doneMember[indexPath.row]
            cell.configure(email: model)
            return cell
        }
        else if whichTable == 1 {
            let cell = finishTableView.dequeueReusableCell(withIdentifier: "shareTodoCell", for: indexPath) as! GoodListTableViewCell
            cell.selectionStyle = .none
            let model = task.shareTask.wantToTalkMember[indexPath.row]
            cell.configure(email: model)
            return cell
        }
        else {
            let cell = finishTableView.dequeueReusableCell(withIdentifier: "shareTodoCell", for: indexPath) as! GoodListTableViewCell
            cell.selectionStyle = .none
            let model = task.shareTask.gettingMember[indexPath.row]
            cell.configure(email: model)
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var friendEmail = ""
        if whichTable == 0 {
            friendEmail = task.shareTask.doneMember[indexPath.row]
        }
        else if whichTable == 1 {
            friendEmail = task.shareTask.wantToTalkMember[indexPath.row]
        }
        else {
            friendEmail = task.shareTask.gettingMember[indexPath.row]
        }
        
        let friendVC = FriendProfileViewController(partnerEmail: friendEmail)
        let nav = UINavigationController(rootViewController: friendVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}
