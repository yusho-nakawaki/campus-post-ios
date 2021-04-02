//
//  WebViewController.swift
//  Match
//
//  on 2021/01/26.
//

import UIKit
import WebKit


class WebViewController: UIViewController, WKNavigationDelegate {
    
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBOutlet weak var reloadButton: UIBarButtonItem!
    @IBOutlet weak var goSafariButton: UIBarButtonItem!
    @IBOutlet weak var webView: WKWebView!
    
    public var urlString = ""
    private var progressView = UIProgressView(progressViewStyle: .bar)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "閉じる",
                                                           style: .done,
                                                           target: self,
                                                           action: #selector(dismissSelf))
        navigationController?.navigationBar.tintColor = .label
        
        setUrl(urlString: urlString)
        setupProgressView()
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
 
    
//    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
//
//    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // ロード中にユーザーがリンクを押したりするエラーは、エラーとして認識させたくない
        //.codeはエラーコードを取得できる。それがURLError.cancelledなら処理を止める
        if (error as! URLError).code == URLError.cancelled {
            return
        }
        urlAlert("network error")
        webView.stopLoading()
    }
    
    //urlを表示するために、ページが表示されたら以下の関数を実行
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        //戻るボタン・すすむボタンの有効無効
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
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
    
    @IBAction func tapBackButton(_ sender: Any) {
        webView.goBack()
    }
    
    @IBAction func tapForwardButton(_ sender: Any) {
        webView.goForward()
    }
    
    @IBAction func tapReloadButton(_ sender: Any) {
        webView.reload()
    }
    
    @IBAction func goSafari(_ sender: Any) {
        let url = URL(string: urlString)!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    
    
}

