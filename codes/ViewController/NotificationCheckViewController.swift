//
//  NotificationCheckViewController.swift
//  match
//
//  on 2021/03/29.
//

import UIKit
import UserNotifications

class NotificationCheckViewController: UIViewController {
    
    private var isTapNotification = false
    
    private var backImage: UIImageView = {
        let imageview = UIImageView()
        return imageview
    }()
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "完了", style: .done, target: self, action: #selector(tapRightBarButton))
        navigationController?.navigationBar.tintColor = .label
        
        
        backImage = UIImageView(frame: CGRect(x: 0, y: 0, width: view.width, height: view.height))
        backImage.image = UIImage(named: "notification")
        backImage.contentMode = .scaleAspectFill
        backImage.isUserInteractionEnabled = true
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapImage))
        backImage.addGestureRecognizer(tap)
        
        view.addSubview(backImage)
        view.sendSubviewToBack(backImage)
    }
    


    
    @objc private func tapRightBarButton() {
        guard isTapNotification == true else {
            alertUserError(alertMessage: "画面をタップしてください")
            return
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    
    @objc private func tapImage() {
        isTapNotification = true
        // 通知許可ダイアログを表示
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
        }
    }
    
    func alertUserError(alertMessage: String) {
        let alert = UIAlertController(title: "",
                                      message: alertMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true)
    }
    
}
