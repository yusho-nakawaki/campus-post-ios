//
//  RegisterNameAgeVC.swift
//  match
//
//  on 2021/03/22.
//

import UIKit

class RegisterNameAgeVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "", style: .done, target: self, action: #selector(cancelButton))
        
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.barTintColor = UIColor(red: 0.969, green: 0.969, blue: 0.969, alpha: 1.0)
        navigationController?.navigationBar.shadowImage = nil
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @objc private func cancelButton() {
    }
    
    
    @IBAction func tap2021Button(_ sender: Any) {
        UserDefaults.standard.setValue("2021", forKey: "year")
        let registerNameAgeVC = SelectUniveristyViewController()
        navigationController?.pushViewController(registerNameAgeVC, animated: true)
    }
    
    @IBAction func tap2020Button(_ sender: Any) {
        UserDefaults.standard.setValue("2020", forKey: "year")
        let registerNameAgeVC = SelectUniveristyViewController()
        navigationController?.pushViewController(registerNameAgeVC, animated: true)
    }
    
    
    @IBAction func tap2019Button(_ sender: Any) {
        UserDefaults.standard.setValue("2019", forKey: "year")
        let registerNameAgeVC = SelectUniveristyViewController()
        navigationController?.pushViewController(registerNameAgeVC, animated: true)
    }
    
    @IBAction func tap2018Button(_ sender: Any) {
        UserDefaults.standard.setValue("2018", forKey: "year")
        let registerNameAgeVC = SelectUniveristyViewController()
        navigationController?.pushViewController(registerNameAgeVC, animated: true)
    }
    
    

}



