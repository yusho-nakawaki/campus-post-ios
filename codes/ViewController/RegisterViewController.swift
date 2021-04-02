//
//  RegisterViewController.swift
//  Study_Match
//
//  on 2020/10/16.
//  Copyright © 2020 yusho. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import JGProgressHUD
import WebKit

final class RegisterViewController: UIViewController {
    
    public var completionEmail: ((Bool) -> (Void))?
    private let spinner = JGProgressHUD(style: .dark)
    
    private var backImage: UIImageView = {
        let imageview = UIImageView()
        return imageview
    }()
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let registerView: UIButton = {
        let view = UIButton()
        view.backgroundColor = UIColor.systemBackground
        view.isUserInteractionEnabled = true
        view.layer.cornerRadius = 20
        view.isHidden = true
        return view
    }()
    private let loginView: UIButton = {
        let view = UIButton()
        view.backgroundColor = UIColor.systemBackground
        view.isUserInteractionEnabled = true
        view.layer.cornerRadius = 20
        view.isHidden = true
        return view
    }()
    
    private let emailField: UITextField = {
        let emailField = UITextField()
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no
        emailField.returnKeyType = .continue
        emailField.backgroundColor = .secondarySystemBackground
        emailField.layer.cornerRadius = 10
        emailField.layer.borderWidth = 1
        emailField.layer.borderColor = UIColor.lightGray.cgColor
        emailField.placeholder = "IDを作る"
        emailField.keyboardType = .asciiCapable
        emailField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        emailField.leftViewMode = .always
        return emailField
    }()
    private let loginEmailField: UITextField = {
        let emailField = UITextField()
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no
        emailField.returnKeyType = .continue
        emailField.backgroundColor = .secondarySystemBackground
        emailField.layer.cornerRadius = 10
        emailField.layer.borderWidth = 1
        emailField.layer.borderColor = UIColor.lightGray.cgColor
        emailField.placeholder = "IDを入力してください"
        emailField.keyboardType = .asciiCapable
        emailField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        emailField.leftViewMode = .always
        return emailField
    }()
    
    
    private let passwordField: UITextField = {
        let passwordField = UITextField()
        passwordField.autocapitalizationType = .none
        passwordField.autocorrectionType = .no
        passwordField.returnKeyType = .done
        passwordField.backgroundColor = .secondarySystemBackground
        passwordField.layer.cornerRadius = 10
        passwordField.layer.borderWidth = 1
        passwordField.layer.borderColor = UIColor.lightGray.cgColor
        passwordField.placeholder = "パスワード"
        passwordField.isSecureTextEntry = true
        passwordField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        passwordField.leftViewMode = .always
        return passwordField
    }()
    private let loginPasswordField: UITextField = {
        let passwordField = UITextField()
        passwordField.autocapitalizationType = .none
        passwordField.autocorrectionType = .no
        passwordField.returnKeyType = .done
        passwordField.backgroundColor = .secondarySystemBackground
        passwordField.layer.cornerRadius = 10
        passwordField.layer.borderWidth = 1
        passwordField.layer.borderColor = UIColor.lightGray.cgColor
        passwordField.placeholder = "パスワード"
        passwordField.isSecureTextEntry = true
        passwordField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        passwordField.leftViewMode = .always
        return passwordField
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton()
        button.setTitle("登録", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        button.backgroundColor = .green
        button.setTitleColor(.secondarySystemBackground, for: .normal)
        button.layer.cornerRadius = 15
        button.layer.masksToBounds = true
        return button
    }()
    private let registerUpButton: UIButton = {
        let button = UIButton()
        button.setTitle("新規登録", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        return button
    }()
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("ログイン", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        button.backgroundColor = .green
        button.setTitleColor(.secondarySystemBackground, for: .normal)
        button.layer.cornerRadius = 15
        button.layer.masksToBounds = true
        return button
    }()
    
    
    private let loginUpButton: UIButton = {
        let button = UIButton()
        let AttributedString = NSAttributedString(string: "アカウントをお持ちの方はこちら", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue, NSAttributedString.Key.foregroundColor : UIColor.black])
        button.setAttributedTitle(AttributedString, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        return button
    }()
    private let imageViewForUserdefualts: UIImageView = {
        let imageview = UIImageView()
        return imageview
    }()
    
    
    // 利用規約ボックス
    private let termsContainer: UIButton = {
        let view = UIButton()
        return view
    }()
    private let checkBox:  UIButton = {
        let view = UIButton()
        return view
    }()
    private let checkBoxSmall: UIButton = {
        let view = UIButton()
        view.backgroundColor = .white
        view.layer.borderColor = UIColor(named: "gentle")?.cgColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 3
        return view
    }()
    private let checkButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        button.setImage(UIImage(systemName: "checkmark"), for: .normal)
        button.tintColor = UIColor(named: "gentle")
        return button
    }()
    private let termsTapLabel: UILabel = {
        let label = UILabel()
        label.text = "利用規約"
        label.font = .systemFont(ofSize: 14)
        label.isUserInteractionEnabled = true
        return label
    }()
    private let termsLabel: UILabel = {
        let label = UILabel()
        label.text = "に同意する"
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor(named: "gentle")
        return label
    }()
    
    
    
    // 連続タップなどを防ぐ
    private var goAnimate = true
    private var tapTerms = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        view.backgroundColor = .secondarySystemBackground
        
        
        backImage = UIImageView(frame: CGRect(x: 0, y: 0, width: view.width, height: view.height))
        backImage.image = UIImage(named: "launch-image")
        backImage.contentMode = .scaleAspectFill
        view.addSubview(backImage)
        view.sendSubviewToBack(backImage)
        
        view.addSubview(scrollView)
        scrollView.addSubview(registerUpButton)
        scrollView.addSubview(loginUpButton)
        scrollView.addSubview(loginView)
        registerView.addSubview(emailField)
        registerView.addSubview(passwordField)
        registerView.addSubview(registerButton)
        scrollView.addSubview(registerView)
        loginView.addSubview(loginEmailField)
        loginView.addSubview(loginPasswordField)
        loginView.addSubview(loginButton)
        // 利用規約
        registerView.addSubview(termsContainer)
        termsContainer.addSubview(checkBox)
        checkBox.addSubview(checkBoxSmall)
        checkBoxSmall.addSubview(checkButton)
        termsContainer.addSubview(termsTapLabel)
        termsContainer.addSubview(termsLabel)

        
        //textFieldがポップアップ
        registerUpButton.addTarget(self,
                                   action: #selector(tappedRegisterUpButton),
                                   for: .touchUpInside)
        loginUpButton.addTarget(self,
                              action: #selector(tappedLoginUpButton),
                              for: .touchUpInside)
        
        //登録ボタン　→ main.storyboardへ
        registerButton.addTarget(self,
                                 action: #selector(tappedRegisterButton),
                                 for: .touchUpInside)
        loginButton.addTarget(self,
                              action: #selector(tappedLoginButton),
                              for: .touchUpInside)
        
        // scrollViewをタップして新規登録をキャンセル
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        scrollView.addGestureRecognizer(tap)
        
        //タップして利用規約
        checkBox.addTarget(self, action: #selector(tapCheckBox), for: .touchUpInside)
        checkBoxSmall.addTarget(self, action: #selector(tapCheckBox), for: .touchUpInside)
        let tapTermsLabel = UITapGestureRecognizer(target: self, action: #selector(gotoTerms))
        termsTapLabel.addGestureRecognizer(tapTermsLabel)
        
    }
    

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        
        if view.width > 600 {
            scrollView.frame = CGRect(x: (view.width-700)/2,
                                      y: 150,
                                      width: 700,
                                      height: view.height - 180)
        }
        else {
            scrollView.frame = view.bounds
        }
        
        registerView.frame = CGRect(x: 30,
                                    y: 90,
                                    width: scrollView.width-60,
                                    height: 265)
        loginView.frame = CGRect(x: 30,
                                 y: 140,
                                 width: scrollView.width-60,
                                 height: 220)
        emailField.frame = CGRect(x: 30,
                                 y: 40,
                                 width: registerView.width-60,
                                 height: 35)
        passwordField.frame = CGRect(x: 30,
                                  y: emailField.bottom+15,
                                  width: registerView.width-60,
                                  height: 35)
        termsContainer.frame = CGRect(x: 25,
                                      y: passwordField.bottom+12,
                                      width: registerView.width-40,
                                      height: 30)
        checkBox.frame = CGRect(x: 0,
                                y: 0,
                                width: 35,
                                height: 35)
        checkBoxSmall.frame = CGRect(x: 8,
                                     y: 5,
                                     width: 20,
                                     height: 20)
        checkButton.frame = CGRect(x: 2,
                                   y: 2,
                                   width: 16,
                                   height: 16)
        termsTapLabel.frame = CGRect(x: checkBox.right,
                                     y: 7,
                                     width: 100,
                                     height: 35)
        termsTapLabel.sizeToFit()
        termsLabel.frame = CGRect(x: termsTapLabel.right,
                                  y: 7,
                                  width: termsTapLabel.width + 20,
                                  height: 35)
        termsLabel.sizeToFit()
        registerButton.frame = CGRect(x: 60,
                                      y: termsContainer.bottom+25,
                                      width: registerView.width-120,
                                      height: 32)
        loginUpButton.frame = CGRect(x: 75,
                                     y: scrollView.height - 100,
                                     width: scrollView.width - 150,
                                     height: 30)
        loginEmailField.frame = CGRect(x: 30,
                                       y: 50,
                                       width: loginView.width-60,
                                       height: 32)
        loginPasswordField.frame = CGRect(x: 30,
                                          y: loginEmailField.bottom+10,
                                          width: loginView.width-60,
                                          height: 32)
        loginButton.frame = CGRect(x: 60,
                                           y: loginPasswordField.bottom+20,
                                           width: loginView.width-120,
                                           height: 32)
        registerUpButton.frame = CGRect(x: 75,
                                        y: loginUpButton.top - 50,
                                        width: scrollView.width - 150,
                                        height: 40)
        loginUpButton.frame = CGRect(x: 75,
                                     y: scrollView.height - 100,
                                     width: scrollView.width - 150,
                                     height: 30)
        
        
    }
    

    @objc private func tappedRegisterUpButton() {
        if goAnimate {
            loginView.isHidden = true
            loginView.frame.origin.y = 140
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .transitionCurlDown, animations: { [weak self] in
                self?.registerView.center.y += 50.0
                self?.registerView.isHidden = false
            }, completion: { [weak self] _ in
                self?.emailField.becomeFirstResponder()
            })
        }
        goAnimate = false
    }
    @objc private func tappedLoginUpButton() {
        if goAnimate {
            registerView.isHidden = true
            registerView.frame.origin.y = 90
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .transitionCurlDown, animations: { [weak self] in
                self?.loginView.center.y += 50.0
                self?.loginView.isHidden = false
            }, completion: { [weak self] _ in
                self?.loginEmailField.becomeFirstResponder()
            })
        }
        goAnimate = false
    }
    
    
    
    @objc private func tappedRegisterButton() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        goAnimate = true
        
        guard tapTerms == true else {
            alertUserError(alertMessage: "利用規約に同意してください")
            return
        }

        guard let email = emailField.text?.lowercased(),
              let password = passwordField.text,
              email.count > 3,
              !password.isEmpty,
              password.count >= 6 else {
                alertUserError(alertMessage: "IDは4文字以上、パスワードは６文字以上です。")
                return
        }
        
        let registerEmail = email + "@gmail.com"
        
        
        // Firebase register
        DatabaseManager.shared.userExists(with: registerEmail) { [weak self]exists in

            guard let strongSelf = self else {
                return
            }
            guard !exists else {
                // user already created account
                strongSelf.alertUserError(alertMessage: "このIDはすでに使われています。")
                return
            }
            
            self?.afterTerms(email: registerEmail)

        }
    }
    
    @objc private func afterTerms(email: String) {

        guard let password = passwordField.text else {
            alertUserError(alertMessage: "エラーが発生しました。申し訳ありませんがもう一度試してください")
                return
        }
        
        spinner.show(in: view)
        
        UserDefaults.standard.setValue(email, forKey: "email")
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        //数人フォローする
        let myFriends = [String]()
        UserDefaults.standard.setValue(myFriends, forKey: "myFriends")
        
        
        FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { [weak self](result, err) in
            guard result != nil, err == nil else {
                self?.spinner.dismiss()
                self?.alertUserError(alertMessage: "IDまたはパスワードに利用できない文字があります")
                return
            }
            
            DatabaseManager.shared.insertUID(myEmail: safeEmail) { (success) in
                if success == true {
                    self?.completionEmail?(true)
                    let storyboard: UIStoryboard = UIStoryboard(name: "RegisterNameAge", bundle: nil)
                    let registerNameAgeVC = storyboard.instantiateViewController(withIdentifier: "RegisterNameAgeVC") as! RegisterNameAgeVC
                    self?.navigationController?.pushViewController(registerNameAgeVC, animated: true)
                }
                else {
                    self?.spinner.dismiss()
                    self?.alertUserError(alertMessage: "通信エラーがありました")
                }
            }
        }
        
    }
    
    
    @objc private func tapCheckBox() {
        if tapTerms == true {
            tapTerms = false
            checkButton.isHidden = true
        }
        else {
            tapTerms = true
            checkButton.isHidden = false
        }
    }
    
    @objc private func gotoTerms() {
        let storyboard = UIStoryboard(name: "Web", bundle: nil)
        let post = storyboard.instantiateViewController(withIdentifier: "segueWeb") as! WebViewController
        post.urlString = "https://campus-post.net/terms-of-service.html"

        let nav = UINavigationController(rootViewController: post)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    
    
    @objc private func tappedLoginButton() {
        
        loginEmailField.resignFirstResponder()
        loginPasswordField.resignFirstResponder()
        goAnimate = true

        guard let email = loginEmailField.text,
              let password = loginPasswordField.text,
              password.count >= 6,
              !email.isEmpty else {
                alertUserError(alertMessage: "入力欄を記入してください。パスワードは６文字以上です。")
                return
        }
        
        
        spinner.show(in: view)
        let registerEmail = email + "@gmail.com"
        
        // Firebase register
        FirebaseAuth.Auth.auth().signIn(withEmail: registerEmail, password: password) { [weak self](result, err) in
            guard let strongSelf = self else {
                return
            }
            
            guard err == nil else {
                strongSelf.spinner.dismiss()
                strongSelf.alertUserError(alertMessage: "メールアドレスまたはパスワードが間違っています。")
                return
            }
            

            UserDefaults.standard.setValue(registerEmail, forKey: "email")
            //database.child(\(safeEmail)) observesingleEventからname, profile情報を取得する
            let safeEmail = DatabaseManager.safeEmail(emailAddress: registerEmail)
            
            
            Database.database().reference().child("users/\(safeEmail)/info").observeSingleEvent(of: .value) { (snapshot) in
                guard let value = snapshot.value as? [String: Any],
                      let myName = value["name"] as? String,
                      let urlPicture = value["picture"] as? String,
                      let age = value["age"] as? String,
                      let faculty = value["faculty"] as? String,
                      let university = value["university"] as? String else {
                    self?.spinner.dismiss()
                    self?.alertUserError(alertMessage: "このアカウントにはエラーがありました。新規登録してください")
                    return
                }
                
                // userdefalutsの設定
                UserDefaults.standard.setValue(myName, forKey: "name")
                UserDefaults.standard.setValue(urlPicture, forKey: "profile_picutre_url")
                if age == "" { UserDefaults.standard.setValue("none", forKey: "year") }
                if age != "" { UserDefaults.standard.setValue(age, forKey: "year") }
                if university == "" { UserDefaults.standard.setValue("none", forKey: "uni") }
                if university != "" { UserDefaults.standard.setValue(university, forKey: "uni") }
                
                if faculty == "" { UserDefaults.standard.setValue("none", forKey: "fac") }
                if faculty != "" { UserDefaults.standard.setValue(faculty, forKey: "fac") }
                
                
                Database.database().reference().child("users/\(safeEmail)/フォロー").observeSingleEvent(of: .value) { (snapshot) in
                    if let value = snapshot.value as? [String] {
                        UserDefaults.standard.setValue(value, forKey: "myFriends")
                    }
                    else {
                        UserDefaults.standard.setValue([], forKey: "myFriends")
                    }
                    
                    let path = "profile_picture/\(safeEmail)-profile.png"
                    StorageManager.shared.getDownloadURL(for: path, completion: { [weak self]result in
                        switch result {
                        case .success(let url):
                            DispatchQueue.main.async {
                                strongSelf.imageViewForUserdefualts.sd_setImage(with: url) { (_, _, _, _) in
                                    guard let image = self?.imageViewForUserdefualts.image,
                                        let data = image.pngData() else {
                                            return
                                    }
                                    strongSelf.spinner.dismiss()
                                    UserDefaults.standard.set(data, forKey: "my_picture")
                                    strongSelf.completionEmail?(true)
                                    // 通知をConversationVCに発火
                                    NotificationCenter.default.post(name: .didLoginNotification, object: nil)
                                    if faculty == "" {
                                        let storyboard: UIStoryboard = UIStoryboard(name: "RegisterNameAge", bundle: nil)
                                        let registerNameAgeVC = storyboard.instantiateViewController(withIdentifier: "RegisterNameAgeVC") as! RegisterNameAgeVC
                                        self?.navigationController?.pushViewController(registerNameAgeVC, animated: true)
                                    }
                                    else {
                                        strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                                    }
                                }
                            }
                        case .failure(_):
                            strongSelf.imageViewForUserdefualts.image = UIImage(systemName: "person.circle")
                            guard let image = self?.imageViewForUserdefualts.image,
                                let data = image.pngData() else {
                                    return
                            }
                            strongSelf.spinner.dismiss()
                            UserDefaults.standard.set(data, forKey: "my_picture")
                            // 通知をConversationVCに発火
                            NotificationCenter.default.post(name: .didLoginNotification, object: nil)
                            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                        }
                    })
                }
            }
            
        }
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

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        goAnimate = true
        registerView.isHidden = true
        registerView.frame.origin.y = 90
        loginView.isHidden = true
        loginView.frame.origin.y = 140
        view.endEditing(true)
    }
    
}


