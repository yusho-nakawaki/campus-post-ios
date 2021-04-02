//
//  SetupClassTimeViewController.swift
//  match
//
//  on 2021/03/21.
//

import UIKit

class SetupClassTimeViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var SwitchContainer: UIView!
    @IBOutlet weak var inOnSwich: UISwitch!
    @IBOutlet weak var classTimeContainer: UIView!
    @IBOutlet weak var classTimeContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var classTimeStackView: UIStackView!
    @IBOutlet weak var timeContainer1: UIView!
    @IBOutlet weak var timeContainer2: UIView!
    @IBOutlet weak var timeContainer3: UIView!
    @IBOutlet weak var timeContainer4: UIView!
    @IBOutlet weak var timeContainer5: UIView!
    @IBOutlet weak var timeContainer6: UIView!
    @IBOutlet weak var timeContainer7: UIView!
    @IBOutlet weak var firstTime1: UITextField!
    @IBOutlet weak var endTime1: UITextField!
    @IBOutlet weak var firstTime2: UITextField!
    @IBOutlet weak var endTime2: UITextField!
    @IBOutlet weak var firstTime3: UITextField!
    @IBOutlet weak var endTime3: UITextField!
    @IBOutlet weak var firstTime4: UITextField!
    @IBOutlet weak var endTime4: UITextField!
    @IBOutlet weak var firstTime5: UITextField!
    @IBOutlet weak var endTime5: UITextField!
    @IBOutlet weak var firstTime6: UITextField!
    @IBOutlet weak var endtime6: UITextField!
    @IBOutlet weak var firstTime7: UITextField!
    @IBOutlet weak var endTime7: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
//        SwitchContainer.backgroundColor = .secondarySystemBackground
//        classTimeContainer.backgroundColor = .secondarySystemBackground
        
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: " ← ",
                                                           style: .done,
                                                           target: self,
                                                           action: #selector(dismissSelf))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "保存",
                                                           style: .done,
                                                           target: self,
                                                           action: #selector(saveButton))
        
        
        if let isOn = UserDefaults.standard.value(forKey: "onClassTime") as? Bool {
            if isOn == true { inOnSwich.isOn = true }
            else { inOnSwich.isOn = false }
        }
        else {
            // default = false
            firstTime1.text = "09:00"
            inOnSwich.isOn = false
        }
        
        firstTime1.delegate = self
        firstTime2.delegate = self
        firstTime3.delegate = self
        firstTime4.delegate = self
        firstTime5.delegate = self
        firstTime6.delegate = self
        firstTime7.delegate = self
        endTime1.delegate = self
        endTime2.delegate = self
        endTime3.delegate = self
        endTime4.delegate = self
        endTime5.delegate = self
        endtime6.delegate = self
        endTime7.delegate = self
        
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
            endtime6.text = timeArray["end6"]
            firstTime7.text = timeArray["first7"]
            endTime7.text = timeArray["end7"]
        }
        
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        SwitchContainer.layer.cornerRadius = 5
        classTimeContainer.layer.cornerRadius = 5

    }
    
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        switch textField {
        case firstTime1:
            let string = firstTime1.text ?? "0"
            if string.count == 3 {
                if String(string.suffix(1)) == ":" { return }
                firstTime1.text = setFigureTextField(str: string)
            }
            if string.count >= 6 {
                firstTime1.text = String(firstTime1.text?.prefix(5) ?? "")
            }
        case firstTime2:
            let string = firstTime2.text ?? "0"
            if string.count == 3 {
                if String(string.suffix(1)) == ":" { return }
                firstTime2.text = setFigureTextField(str: string)
            }
            if string.count >= 6 {
                firstTime2.text = String(firstTime2.text?.prefix(5) ?? "")
            }
        case firstTime3:
            let string = firstTime3.text ?? "0"
            if string.count == 3 {
                if String(string.suffix(1)) == ":" { return }
                firstTime3.text = setFigureTextField(str: string)
            }
            if string.count >= 6 {
                firstTime3.text = String(firstTime3.text?.prefix(5) ?? "")
            }
        case firstTime4:
            let string = firstTime4.text ?? "0"
            if string.count == 3 {
                if String(string.suffix(1)) == ":" { return }
                firstTime4.text = setFigureTextField(str: string)
            }
            if string.count >= 6 {
                firstTime4.text = String(firstTime4.text?.prefix(5) ?? "")
            }
        case firstTime5:
            let string = firstTime5.text ?? "0"
            if string.count == 3 {
                if String(string.suffix(1)) == ":" { return }
                firstTime5.text = setFigureTextField(str: string)
            }
            if string.count >= 6 {
                firstTime5.text = String(firstTime5.text?.prefix(5) ?? "")
            }
        case firstTime6:
            let string = firstTime6.text ?? "0"
            if string.count == 3 {
                if String(string.suffix(1)) == ":" { return }
                firstTime6.text = setFigureTextField(str: string)
            }
            if string.count >= 6 {
                firstTime6.text = String(firstTime6.text?.prefix(5) ?? "")
            }
        case firstTime7:
            let string = firstTime7.text ?? "0"
            if string.count == 3 {
                if String(string.suffix(1)) == ":" { return }
                firstTime7.text = setFigureTextField(str: string)
            }
            if string.count >= 6 {
                firstTime7.text = String(firstTime7.text?.prefix(5) ?? "")
            }
        case endTime1:
            let string = endTime1.text ?? "0"
            if string.count == 3 {
                if String(string.suffix(1)) == ":" { return }
                endTime1.text = setFigureTextField(str: string)
            }
            if string.count >= 6 {
                endTime1.text = String(endTime1.text?.prefix(5) ?? "")
            }
        case endTime2:
            let string = endTime2.text ?? "0"
            if string.count == 3 {
                if String(string.suffix(1)) == ":" { return }
                endTime2.text = setFigureTextField(str: string)
            }
            if string.count >= 6 {
                if String(string.suffix(1)) == ":" { return }
                endTime2.text = String(endTime2.text?.prefix(5) ?? "")
            }
        case endTime3:
            let string = endTime3.text ?? "0"
            if string.count == 3 {
                if String(string.suffix(1)) == ":" { return }
                endTime3.text = setFigureTextField(str: string)
            }
            if string.count >= 6 {
                endTime3.text = String(endTime3.text?.prefix(5) ?? "")
            }
        case endTime4:
            let string = endTime4.text ?? "0"
            if string.count == 3 {
                if String(string.suffix(1)) == ":" { return }
                endTime4.text = setFigureTextField(str: string)
            }
            if string.count >= 6 {
                endTime4.text = String(endTime4.text?.prefix(5) ?? "")
            }
        case endTime5:
            let string = endTime5.text ?? "0"
            if string.count == 3 {
                if String(string.suffix(1)) == ":" { return }
                endTime5.text = setFigureTextField(str: string)
            }
            if string.count >= 6 {
                endTime5.text = String(endTime5.text?.prefix(5) ?? "")
            }
        case endtime6:
            let string = endtime6.text ?? "0"
            if string.count == 3 {
                if String(string.suffix(1)) == ":" { return }
                endtime6.text = setFigureTextField(str: string)
            }
            if string.count >= 6 {
                endtime6.text = String(endtime6.text?.prefix(5) ?? "")
            }
        case endTime7:
            let string = endTime7.text ?? "0"
            if string.count == 3 {
                if String(string.suffix(1)) == ":" { return }
                endTime7.text = setFigureTextField(str: string)
            }
            if string.count >= 6 {
                endTime7.text = String(endTime7.text?.prefix(5) ?? "")
            }
        default:
            return
        }
    }
    
    func setFigureTextField(str: String) -> String {
        var string = str
        let insertIdx = str.index(str.startIndex, offsetBy: 2)
        string.insert(contentsOf: ":", at: insertIdx)
        return string
    }
    
    
    @IBAction func changeAppearTime(_ sender: Any) {
        let nav = self.navigationController
        let setupVC = nav?.viewControllers[(nav?.viewControllers.count)!-2] as! SetupTimeSchedule
        // 値を渡す
        if inOnSwich.isOn == true { setupVC.classTimeOnLable.text = "on >" }
        else { setupVC.classTimeOnLable.text = "off >" }
        UserDefaults.standard.setValue(inOnSwich.isOn, forKey: "onClassTime")
    }
    
    
    @objc private func saveButton() {
        let timeArray: [String: String] = [
            "first1": firstTime1.text ?? "",
            "end1": endTime1.text ?? "",
            "first2": firstTime2.text ?? "",
            "end2": endTime2.text ?? "",
            "first3": firstTime3.text ?? "",
            "end3": endTime3.text ?? "",
            "first4": firstTime4.text ?? "",
            "end4": endTime4.text ?? "",
            "first5": firstTime5.text ?? "",
            "end5": endTime5.text ?? "",
            "first6": firstTime6.text ?? "",
            "end6": endtime6.text ?? "",
            "first7": firstTime7.text ?? "",
            "end7": endTime7.text ?? "",
        ]
        UserDefaults.standard.setValue(timeArray, forKey: "classTime")
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func dismissSelf() {
        navigationController?.popViewController(animated: true)
    }
    
    
    
}
