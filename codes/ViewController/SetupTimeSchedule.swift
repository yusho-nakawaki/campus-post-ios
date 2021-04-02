//
//  SetupTimeSchedule.swift
//  match
//
//  on 2021/03/02.
//

/*
 
　　[1年前期:
    56:
    [TimeScheduleStruct]]
 → 1年前期の5限まで，月火水木金土のTimeScheduleStruct
 
 */

import UIKit
import UserNotifications


class SetupTimeSchedule: UIViewController, UITextFieldDelegate {
    
    
    private var pickerView: UIPickerView = UIPickerView()
    private var active_textfield : UITextField!
    private var current_arr : [String] = []
    private let schoolYearList = ["","1年", "2年", "3年", "4年"]
    private let classCountList = ["4限目まで", "5限目まで", "6限目まで", "7限目まで"]
    private let classDayList = ["月火水木金", "月火水木金土", "月火水木金土日"]
    
    private var myTimeSchedule: TimeScheduleContainer
    
    private let topContainer: UIView = {
        let view = UIView()
        return view
    }()

    private let whichTimeSchedule: UIView = {
        let view = UIView()
        return view
    }()
    private let whichLable: UILabel = {
        let label = UILabel()
        label.text = "時間割名"
        label.font = .systemFont(ofSize: 18)
        return label
    }()
    private let whichSchoolTextFeild: CustomTextField = {
        let textField = CustomTextField()
        textField.layer.cornerRadius = 5
        textField.backgroundColor = .secondarySystemBackground
        textField.text = "1年"
        return textField
    }()
    private let whichTextFeild: UITextField = {
        let textField = UITextField()
        textField.layer.cornerRadius = 5
        textField.backgroundColor = .secondarySystemBackground
        textField.text = "前期"
        return textField
    }()
    
    private let classCountTimeSchedule: UIView = {
        let view = UIView()
        return view
    }()
    private let classCountLable: UILabel = {
        let label = UILabel()
        label.text = "授業数"
        label.font = .systemFont(ofSize: 18)
        return label
    }()
    private let classCountTextFeild: CustomTextField = {
        let textField = CustomTextField()
        textField.layer.cornerRadius = 5
        textField.backgroundColor = .secondarySystemBackground
        return textField
    }()
    
    private let classDayTimeSchedule: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        return view
    }()
    private let classDayLable: UILabel = {
        let label = UILabel()
        label.text = "授業日"
        label.font = .systemFont(ofSize: 18)
        return label
    }()
    private let classDayTextField: CustomTextField = {
        let textField = CustomTextField()
        textField.layer.cornerRadius = 5
        textField.backgroundColor = .secondarySystemBackground
        return textField
    }()
    private let setupClassTime: UIView = {
        let view = UIView()
        return view
    }()
    private let classTimeLable: UILabel = {
        let label = UILabel()
        label.text = "授業時間の設定"
        label.font = .systemFont(ofSize: 18)
        return label
    }()
    public  let classTimeOnLable: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = true
        label.layer.cornerRadius = 5
        label.backgroundColor = .secondarySystemBackground
        label.text = "off >"
        label.font = .systemFont(ofSize: 18)
        return label
    }()
    
    private let removeTSButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .secondarySystemBackground
        button.setTitle("この時間割を消す", for: .normal)
        button.setTitleColor(.red, for: .normal)
        return button
    }()
    
   
    
    
    init(original: TimeScheduleContainer) {
        self.myTimeSchedule = original

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: " ← ",
                                                           style: .done,
                                                           target: self,
                                                           action: #selector(dismissSelf))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "保存",
                                                           style: .done,
                                                           target: self,
                                                           action: #selector(saveButton))
        navigationController?.navigationBar.tintColor = UIColor(named: "gentle")
        navigationController?.navigationBar.barTintColor = UIColor(named: "appBackground")
        
        removeTSButton.addTarget(self, action: #selector(tapRemove), for: .touchUpInside)
        let setupClassTap = UITapGestureRecognizer(target: self, action: #selector(tapClassTime))
        classTimeOnLable.addGestureRecognizer(setupClassTap)
        let tap = UITapGestureRecognizer(target: self, action: #selector(done))
        view.addGestureRecognizer(tap)
        
        whichTextFeild.delegate = self
        classCountTextFeild.delegate = self
        classDayTextField.delegate = self
        whichSchoolTextFeild.delegate = self
        
        pickerView.delegate = self
        pickerView.dataSource = self

        
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 45))
        let spacelItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        toolbar.setItems([spacelItem, doneItem], animated: true)
        
        classCountTextFeild.inputView = pickerView
        classDayTextField.inputView = pickerView
        whichSchoolTextFeild.inputView = pickerView
        classCountTextFeild.inputAccessoryView = toolbar
        classDayTextField.inputAccessoryView = toolbar
        whichSchoolTextFeild.inputAccessoryView = toolbar
        
        //現在のtime schedule
        if myTimeSchedule.classCount == 4 { classCountTextFeild.text = "4限目まで" }
        if myTimeSchedule.classCount == 5 { classCountTextFeild.text = "5限目まで" }
        if myTimeSchedule.classCount == 6 { classCountTextFeild.text = "6限目まで" }
        if myTimeSchedule.classCount == 7 { classCountTextFeild.text = "7限目まで" }
        if myTimeSchedule.classDay == 5 { classDayTextField.text = "月火水木金" }
        if myTimeSchedule.classDay == 6 { classDayTextField.text = "月火水木金土" }
        if myTimeSchedule.classDay == 7 { classDayTextField.text = "月火水木金土日" }
        
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(dismissSelf))
        rightSwipe.direction = .right
        view.addGestureRecognizer(rightSwipe)
        
        
        view.addSubview(topContainer)
        topContainer.addSubview(whichTimeSchedule)
        topContainer.addSubview(classCountTimeSchedule)
        topContainer.addSubview(classDayTimeSchedule)
        topContainer.addSubview(setupClassTime)
        whichTimeSchedule.addSubview(whichLable)
        whichTimeSchedule.addSubview(whichTextFeild)
        whichTimeSchedule.addSubview(whichSchoolTextFeild)
        classCountTimeSchedule.addSubview(classCountLable)
        classCountTimeSchedule.addSubview(classCountTextFeild)
        classDayTimeSchedule.addSubview(classDayLable)
        classDayTimeSchedule.addSubview(classDayTextField)
        setupClassTime.addSubview(classTimeLable)
        setupClassTime.addSubview(classTimeOnLable)
        view.addSubview(removeTSButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let isOn = UserDefaults.standard.value(forKey: "onClassTime") as? Bool {
            if isOn == true { classTimeOnLable.text = "on >" }
            else { classTimeOnLable.text = "off >" }
        }
        else {
            // default = false
            classTimeOnLable.text = "off >"
        }
        
        let safeY = view.safeAreaInsets.top
        topContainer.frame = CGRect(x: 0,
                                    y: safeY + 30,
                                    width: view.width,
                                    height: 190)
        whichTimeSchedule.frame = CGRect(x: 0,
                                         y: 15,
                                         width: view.width,
                                         height: 40)
        whichLable.frame = CGRect(x: 20, y: 5, width: 150, height: 30)
        whichSchoolTextFeild.frame = CGRect(x: view.width - 140, y: 5, width: 30, height: 30)
        whichTextFeild.frame = CGRect(x: view.width - 105, y: 5, width: 85, height: 30)
        classCountTimeSchedule.frame = CGRect(x: 0,
                                              y: whichTimeSchedule.bottom + 1,
                                              width: view.width,
                                              height: 40)
        classCountLable.frame = CGRect(x: 20, y: 5, width: 150, height: 30)
        classCountTextFeild.frame = CGRect(x: view.width - 140, y: 5, width: 120, height: 30)
        classDayTimeSchedule.frame = CGRect(x: 0,
                                            y: classCountTimeSchedule.bottom + 1,
                                            width: view.width,
                                            height: 40)
        classDayLable.frame = CGRect(x: 20, y: 5, width: 150, height: 30)
        classDayTextField.frame = CGRect(x: view.width - 140, y: 5, width: 120, height: 30)
        setupClassTime.frame = CGRect(x: 0,
                                      y: classDayTimeSchedule.bottom + 1,
                                      width: view.width,
                                      height: 40)
        classTimeLable.frame = CGRect(x: 20, y: 5, width: 200, height: 30)
        classTimeOnLable.frame = CGRect(x: view.width - 140, y: 5, width: 120, height: 30)
        
        let border1 = CALayer()
        border1.frame = CGRect(x: 20, y: 40, width: view.width - 40, height: 1.0)
        border1.backgroundColor = UIColor.systemGray5.cgColor
        whichTimeSchedule.layer.addSublayer(border1)
        let border2 = CALayer()
        border2.frame = CGRect(x: 20, y: 40, width: view.width - 40, height: 1.0)
        border2.backgroundColor = UIColor.systemGray5.cgColor
        classCountTimeSchedule.layer.addSublayer(border2)
        let border3 = CALayer()
        border3.frame = CGRect(x: 20, y: 40, width: view.width - 40, height: 1.0)
        border3.backgroundColor = UIColor.systemGray5.cgColor
        classDayTimeSchedule.layer.addSublayer(border3)
        
        
        removeTSButton.frame = CGRect(x: 20,
                                      y: topContainer.bottom + 40,
                                      width: view.width - 40,
                                      height: 40)
        removeTSButton.layer.cornerRadius = 5
        
        
    }

    
    
    
    @objc private func dismissSelf() {
        let nav = self.navigationController
        let timeVC = nav?.viewControllers[(nav?.viewControllers.count)!-2] as! TimeSchedule
        timeVC.setupClassTime()
        navigationController?.popViewController(animated: true)
    }
    
    
    // 決定ボタン押下
    @objc private func done() {
        view.endEditing(true)
        
        if active_textfield == classCountTextFeild {
            classCountTextFeild.endEditing(true)
            classCountTextFeild.text = classCountList[pickerView.selectedRow(inComponent: 0)]
        }
        if active_textfield == classDayTextField {
            classDayTextField.endEditing(true)
            classDayTextField.text = classDayList[pickerView.selectedRow(inComponent: 0)]
        }
        if active_textfield == whichSchoolTextFeild {
            whichSchoolTextFeild.endEditing(true)
            whichSchoolTextFeild.text = schoolYearList[pickerView.selectedRow(inComponent: 0)]
        }
    }
    
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        active_textfield = textField

        switch textField {
        case classCountTextFeild:
            current_arr = classCountList
        case classDayTextField:
            current_arr = classDayList
        case whichSchoolTextFeild:
            current_arr = schoolYearList
        default:
            print("default")
        }
        pickerView.reloadAllComponents()
        
        return true
    }
    
    
    
    @objc private func saveButton() {
        
        guard let schoolText = whichSchoolTextFeild.text,
              let nameText = whichTextFeild.text,
              let classCountText = classCountTextFeild.text,
              let classDayText = classDayTextField.text else {
            alertUserError(alertMessage: "時間割名が空欄です")
            return
        }
        
        var changeClassCount = 0
        if "4限目まで" == classCountText { changeClassCount = 4 }
        if "5限目まで" == classCountText { changeClassCount = 5 }
        if "6限目まで" == classCountText { changeClassCount = 6 }
        if "7限目まで" == classCountText { changeClassCount = 7 }
        
        var changeClassDay = 0
        if "月火水木金" == classDayText { changeClassDay = 5 }
        if "月火水木金土" == classDayText { changeClassDay = 6 }
        if "月火水木金土日" == classDayText { changeClassDay = 7 }
        
        
        let gapDay = changeClassDay - myTimeSchedule.classDay
        if gapDay > 0 {
            // increase
            let repeatCount = myTimeSchedule.timeTable.count + gapDay*myTimeSchedule.classCount - 1
            var i = 0
            var j = 1
            while i < repeatCount {
                if j >= myTimeSchedule.classDay {
                    while j < changeClassDay {
                        myTimeSchedule.timeTable[i].number = i
                        myTimeSchedule.timeTable.insert(TimeScheduleStruct(number: i + 1, color: "green", subject: "", teacher: ""), at: i + 1)
                        i += 1
                        j += 1
                    }
                    j = 0
                }
                else {
                    myTimeSchedule.timeTable[i].number = i
                }
                i += 1
                j += 1
            }
            
        }
        if gapDay < 0 {
            let repeatCount = myTimeSchedule.timeTable.count + gapDay*myTimeSchedule.classCount
            var i = 0
            var j = 1
            while i < repeatCount {
                if j >= myTimeSchedule.classDay + gapDay {
                    print(myTimeSchedule.timeTable[i])
                    while j < myTimeSchedule.classDay {
                        myTimeSchedule.timeTable.remove(at: i+1)
                        myTimeSchedule.timeTable[i].number = i
                        j += 1
                    }
                    j = 0
                }
                else {
                    myTimeSchedule.timeTable[i].number = i
                }
                j += 1
                i += 1
            }
            
        }
        
        
        let gapCount = changeClassCount - myTimeSchedule.classCount
        let timeScheduleCount = myTimeSchedule.timeTable.count
        if gapCount > 0 {
            // increase
            let repeatCount = gapCount*changeClassDay
            print("\(gapCount) : \(changeClassCount)")
            print(repeatCount)
            var i = 0
            while i < repeatCount {
                myTimeSchedule.timeTable.append(TimeScheduleStruct(number: timeScheduleCount + i, color: "green", subject: "", teacher: ""))
                i += 1
            }
        }
        if gapCount < 0 {
            // decrease
            let repeatCount = abs(gapCount)*changeClassDay
            var i = 0
            while i < repeatCount {
                i += 1
                myTimeSchedule.timeTable.remove(at: timeScheduleCount - i)
            }
            
        }
        
        
        // 値を渡す
        let timeScheduleName = schoolText + nameText
        myTimeSchedule.name = timeScheduleName
        myTimeSchedule.classCount = changeClassCount
        myTimeSchedule.classDay = changeClassDay
        DatabaseManager.shared.insertTimeSchedule(myTimeSchedule: myTimeSchedule) { [weak self ](success) in
            guard let strongSelf = self else {
                return
            }
            let nav = strongSelf.navigationController
            // 一つ前のViewControllerを取得する
            let timeSheduleVC = nav?.viewControllers[(nav?.viewControllers.count)!-2] as! TimeSchedule
            timeSheduleVC.myTimeSchedule = strongSelf.myTimeSchedule
            timeSheduleVC.setupCollection(classCount: changeClassCount, classDay: changeClassDay)
            timeSheduleVC.collectionView.reloadData()
            timeSheduleVC.setupClassTime()
            strongSelf.navigationController?.popViewController(animated: true)
        }
        
    }
    
    
    @objc private func tapClassTime() {
        let storyboard: UIStoryboard = UIStoryboard(name: "SetupClassTime", bundle: nil)
        let SetupClassTimeViewController = storyboard.instantiateViewController(withIdentifier: "SetupClassTimeViewController") as! SetupClassTimeViewController
        navigationController?.pushViewController(SetupClassTimeViewController, animated: true)
    
    }
    
    @objc private func tapRemove() {
        let alert: UIAlertController = UIAlertController(title: "",
                                                         message: "本当に消しますか",
                                                         preferredStyle: .alert)
        
        let defaultAction: UIAlertAction = UIAlertAction(title: "消去", style: .default, handler:{ [weak self]_ in
            UserDefaults.standard.removeObject(forKey: "myTimeSchedule")
            guard let strongSelf = self else {
                return
            }
            let nav = strongSelf.navigationController
            // 一つ前のViewControllerを取得する
            let timeSheduleVC = nav?.viewControllers[(nav?.viewControllers.count)!-2] as! TimeSchedule
            timeSheduleVC.setupTimeSchedule()
            strongSelf.navigationController?.popViewController(animated: true)
        })
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "しません",
                                                        style: .cancel,
                                                        handler:{ _ in
        })
        
        alert.addAction(cancelAction)
        alert.addAction(defaultAction)
        present(alert, animated: true, completion: nil)
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
    
    
}





// 授業時間を選択
extension SetupTimeSchedule: UIPickerViewDelegate, UIPickerViewDataSource {
    
    
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
