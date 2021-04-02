//
//  BlogViewController.swift
//  match
//
//  on 2021/03/29.
//

import UIKit
import WebKit


class BlogViewController: UIViewController, WKNavigationDelegate {

    
    @IBOutlet weak var webView: WKWebView!
    
    public var urlString = "https://campus-post.net"
    private var progressView = UIProgressView(progressViewStyle: .bar)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        navigationController?.navigationBar.tintColor = .label
        
        setUrl(urlString: urlString)
        setupProgressView()
        setupNavigationbar()
    }
    
    
    private func setupNavigationbar() {
        
        view.backgroundColor = UIColor(named: "appBackground")
        navigationController?.navigationBar.tintColor = UIColor(named: "gentle")
        navigationController?.navigationBar.barTintColor = UIColor(named: "appBackground")

        
        let button1: UIBarButtonItem = UIBarButtonItem.init(title: "←", style: .plain, target: self, action: #selector(tapBackButton))
        let button2: UIBarButtonItem = UIBarButtonItem.init(title: "→", style: .plain, target: self, action: #selector(tapForwardButton))
        button1.tintColor = .label
        button2.tintColor = .label
        navigationItem.leftBarButtonItems = [button1, button2]
        
        let button3: UIBarButtonItem = UIBarButtonItem.init(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(tapReloadButton))
        let button4: UIBarButtonItem = UIBarButtonItem.init(image: UIImage(systemName: "safari"), style: .plain, target: self, action: #selector(goSafari))
        button3.tintColor = .label
        button4.tintColor = .label
        navigationItem.rightBarButtonItems = [button4, button3]
        
    }
    
    
    private func setupProgressView() {
        guard let navigationBarH = self.navigationController?.navigationBar.frame.size.height else {
            assertionFailure()
            return
        }
        progressView = UIProgressView(frame: CGRect(x: 0.0, y: navigationBarH, width: view.frame.size.width, height: 0.0))
        navigationController?.navigationBar.addSubview(progressView)
        //変更を検知
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else {
            assertionFailure()
            return
        }

        switch keyPath {
        case #keyPath(WKWebView.isLoading):
            if webView.isLoading {
                progressView.alpha = 1.0
                progressView.setProgress(0.1, animated: true)
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    self.progressView.alpha = 0.0
                }, completion: { _ in
                    self.progressView.setProgress(0.0, animated: false)
                })
            }
        case #keyPath(WKWebView.estimatedProgress):
            self.progressView.setProgress(Float(webView.estimatedProgress), animated: true)
        default:
            //do nothing
            break
        }
    }
    
    
    
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func tapRelaodButton() {
        webView.reload()
    }
 
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // ロード中にユーザーがリンクを押したりするエラーは、エラーとして認識させたくない
        //.codeはエラーコードを取得できる。それがURLError.cancelledなら処理を止める
        if (error as! URLError).code == URLError.cancelled {
            return
        }
        urlAlert("network error")
        webView.stopLoading()
    }
    
    
    func getValidatedUrl(urlMoji: String) -> URL? {
        // url前後の空白を取り除いてtimmedに代入
        let trimmed = urlMoji.trimmingCharacters(in: NSCharacterSet.whitespaces)
        
        if URL(string: trimmed) == nil {
            urlAlert("no URL")
            return nil
        }
        return URL(string: appendScheme(trimmed))
    }
    
    func setUrl(urlString: String){
        if let url = getValidatedUrl(urlMoji: urlString) {
            let urlRequest = URLRequest(url: url)
            webView.load(urlRequest)
        }
    }
    
    func urlAlert (_ message: String){
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let defaultAlert = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAlert)
        self.present(alertController, animated: true, completion: nil)
    }
    
    //httpをつける
    func appendScheme(_ urlString: String) -> String {
        if URL(string: urlString)?.scheme == nil {
            return "https://" + urlString
        }
        
        if urlString.contains("https") {
            return urlString
        }
        else if urlString.contains("http") {
            let notHttps = urlString.suffix(urlString.count - 4)
            return "https" + notHttps
        }
        fatalError("error in url")
    }
    
    @objc func tapBackButton(_ sender: Any) {
        webView.goBack()
    }
    
    @objc func tapForwardButton(_ sender: Any) {
        webView.goForward()
    }
    
    @objc func tapReloadButton(_ sender: Any) {
        webView.reload()
    }
    
    @objc func goSafari(_ sender: Any) {
        let url = URL(string: urlString)!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    
    
}
