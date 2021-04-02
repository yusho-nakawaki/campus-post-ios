//
//  TodoInputAccessary.swift
//  match
//
//  on 2021/03/05.
//

import UIKit


//自作delegate
protocol TodoInputAccessoryViewDelegate: class{ //循環参照というメモリリークが起きないようにclass
    // tableViewで勝手に2つの関数が入るのと同じ処理
    func tapSaveButton(name: String, limit: String, notification: String, timeShedule: String)
}



class TodoInputAccessary: UIView, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    // 自作delegateでChatRoomTebleViewCellにtableViewのメッセージを送る
    weak var delegate: TodoInputAccessoryViewDelegate?
    
    @IBOutlet weak var todoTextView: UITextView!
    @IBOutlet weak var todoTextViewheight: NSLayoutConstraint!
    @IBOutlet weak var todoLimitTextView: UITextField!
    @IBOutlet weak var timeSheduleTextView: UITextField!
    @IBOutlet weak var notificationTextView: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    
    var datePicker = UIDatePicker()
    var pickerView = UIPickerView()
    private var whichPickerTextView = 0 // 0が時間割, 1が通知
    private var current_arr : [String] = []
    
    // 選択肢
    let list: [String] = ["指定なし", "10分前", "30分前", "1時間前", "3時間前", "6時間前", "12時間前", "1日前", "2日前", "3日前"]
    let timeSheduleList: [String] = ["","月曜日 1限", "月曜日 2限", "月曜日 3限", "月曜日 4限", "月曜日 5限", "月曜日 6限", "火曜日 1限", "火曜日 2限", "火曜日 3限", "火曜日 4限", "火曜日 5限", "火曜日 6限", "水曜日 1限", "水曜日 2限", "水曜日 3限", "水曜日 4限", "水曜日 5限", "水曜日 6限", "木曜日 1限", "木曜日 2限", "木曜日 3限", "木曜日 4限", "木曜日 5限", "木曜日 6限", "金曜日 1限", "金曜日 2限", "金曜日 3限", "金曜日 4限", "金曜日 5限", "金曜日 6限", "土曜日 1限", "土曜日 2限", "土曜日 3限", "土曜日 4限", "土曜日 5限", "土曜日 6限", "日曜日 1限", "日曜日 2限", "日曜日 3限", "日曜日 4限", "日曜日 5限", "日曜日 6限"]
    
    private var viewWidth: CGFloat = 410
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        viewWidth = frame.width
        
        nibInit()
        setupViews()
        
        createDatePicker()
        createSelectPicker()
        // 文字の量に合わせて、textViewの大きさを変える
        autoresizingMask = .flexibleHeight
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // xibのファイルがここのviewの上に貼り付けができている状態にする
    private func nibInit() {
        let nib = UINib(nibName: "TodoInputAccessary", bundle: nil)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            return
        }
    
        // フレームの大きさを決める
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.addSubview(view)
    }
    
    
    private func setupViews() {
        todoTextView.layer.cornerRadius = 5
        todoTextView.layer.borderColor = UIColor.systemGray5.cgColor
        todoTextView.layer.borderWidth = 1
        todoTextView.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        saveButton.layer.cornerRadius = 5
        
        todoTextView.backgroundColor = .secondarySystemBackground
        todoLimitTextView.backgroundColor = .secondarySystemBackground
        timeSheduleTextView.backgroundColor = .secondarySystemBackground
        notificationTextView.backgroundColor = .secondarySystemBackground
        
        // 入力したという情報を監視する delegate
        todoTextView.delegate = self
        todoLimitTextView.delegate = self
        timeSheduleTextView.delegate = self
        notificationTextView.delegate = self
    }
    
    
    // 文字の量に合わせて、textViewの大きさを変える
    override var intrinsicContentSize: CGSize {
        return CGSize(width: viewWidth-40, height: 20)
    }
    
    //このメソッドはChangeTimeScheduleで呼び出す
    func removeText() {
        todoTextView.text = ""
        todoLimitTextView.text = ""
        notificationTextView.text = ""
        saveButton.setTitle("閉じる", for: .normal)
    }
    
    
    // MARK: - BUTTON TAP
    
    @IBAction func tapSaveButton(_ sender: Any) {
        if todoTextView.text == "" {
            delegate?.tapSaveButton(name: "", limit: "", notification: "", timeShedule: "")
        }
        else {
            delegate?.tapSaveButton(name: todoTextView.text, limit: todoLimitTextView.text ?? "", notification: notificationTextView.text ?? "", timeShedule: timeSheduleTextView.text ?? "none")
        }
    }
    
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {

        switch textField {
        case timeSheduleTextView:
            whichPickerTextView = 0
            current_arr = timeSheduleList
        case notificationTextView:
            whichPickerTextView = 1
            current_arr = list
        default:
            print("default")
        }
        pickerView.reloadAllComponents()
        
        return true
    }
    
    
    
    // ドラムツール
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return current_arr.count
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if whichPickerTextView == 0 {
            timeSheduleTextView.text = current_arr[row]
        }
        else {
            notificationTextView.text = current_arr[row]
        }
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return current_arr[row]
    }
    
    
    // デートピッカーの作成
    func createDatePicker() {
        datePicker.date = Date()
        datePicker.datePickerMode = .dateAndTime
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        } else {
            // Fallback on earlier versions
        }
        datePicker.locale = Locale(identifier: "ja")
        
        datePicker.addTarget(self, action: #selector(changeDatePicker), for: .valueChanged)
        
        // textFieldに表示するようにする
        todoLimitTextView.inputView = datePicker
    }
    
    @objc private func changeDatePicker() {
        // 日付のフォーマット
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 H:mm"

        todoLimitTextView.text = "\(formatter.string(from: datePicker.date))"
    }
    
    
    // 通知時間の選択肢の作成
    func createSelectPicker() {
        pickerView.delegate = self
        pickerView.dataSource = self
        
        // textFieldに表示するようにする
        notificationTextView.inputView = pickerView
        timeSheduleTextView.inputView = pickerView
    }
    
    
    
    public func dismissKeyboard() {
        todoTextView.resignFirstResponder()
        todoLimitTextView.resignFirstResponder()
        timeSheduleTextView.resignFirstResponder()
        notificationTextView.resignFirstResponder()
    }
    
}


extension TodoInputAccessary: UITextViewDelegate {
    // textViewが変わったかを監視するメソッド
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.isEmpty {
            saveButton.setTitle("閉じる", for: .normal)
        } else {
            saveButton.setTitle("追加", for: .normal)
        }
    }
    
}
