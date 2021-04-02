//
//  PhotoViewController.swift
//  Study_Match
//
//  on 2020/11/13.
//  Copyright © 2020 yusho. All rights reserved.
//

import UIKit
import SDWebImage
import JGProgressHUD

final class PhotoViewController: UIViewController, UIScrollViewDelegate {
    
    public var pictureData: Data?
    public var pictureUrl: URL?
    private let spinner = JGProgressHUD()
    
    
    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        return view
    }()
    private let imageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        return image
    }()
    public let downloadButton: UIButton = {
        let button = UIButton()
        let largeConfiguration = UIImage.SymbolConfiguration(scale: .medium)
        button.setImage(UIImage(systemName: "tray.and.arrow.down", withConfiguration: largeConfiguration), for: .normal)
        button.tintColor = .systemGray4
        button.contentMode = .scaleAspectFit
        button.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        button.layer.cornerRadius = 25
        return button
    }()

    
    init(data: Data?, url: URL?) {
        self.pictureData = data
        self.pictureUrl = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

//        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.barTintColor = .black
        view.backgroundColor = .black
//        tabBarItem.isEnabled = false
        
        view.addSubview(scrollView)
        view.addSubview(downloadButton)
        scrollView.addSubview(imageView)
        
        if let data = pictureData {
            imageView.image = UIImage(data: data)
        }
        else if let url = pictureUrl {
            imageView.sd_setImage(with: url) { [weak self](_, _, _, _) in
                self?.setupImage()
            }
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "multiply"), style: .done, target: self, action: #selector(dismissSelf))
        downloadButton.addTarget(self, action: #selector(tapDownload), for: .touchUpInside)
        navigationItem.leftBarButtonItem?.tintColor = .lightGray
        
        scrollView.maximumZoomScale = 2.5
        scrollView.minimumZoomScale = 1
        scrollView.isScrollEnabled = true
        scrollView.zoomScale = 1
        scrollView.contentSize = view.bounds.size
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        
        
        // navigationbarを透明に
//        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
//        navigationController?.navigationBar.shadowImage = UIImage()
//        navigationController?.navigationBar.tintColor = .label
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        imageView.frame = scrollView.bounds
        downloadButton.frame = CGRect(x: 40, y: view.height - 94, width: 54, height: 54)
        
        if pictureData != nil {
            setupImage()
        }
    }
    
    private func setupImage() {
        if let image = imageView.image {
            let w_scale = scrollView.frame.width / image.size.width
            let h_scale = scrollView.frame.height / image.size.height

            // Fit longer edge to screen
            // let scale = min(w_scale, h_scale)

            // Fit shorter edge to screen
            let scale = max(w_scale, h_scale)

            // Not zoom, only scroll
            // scrollView.minimumZoomScale = scale
            // scrollView.maximumZoomScale = scale

            scrollView.zoomScale = scale
            scrollView.contentSize = imageView.frame.size

            // In case that the image is larger than screen, calculate offset to show the center of image at initial launch
            let offset = CGPoint(x: (imageView.frame.width - scrollView.frame.width) / 2.0,
                                 y: (imageView.frame.height - scrollView.frame.height) / 2.0)
            scrollView.setContentOffset(offset, animated: false)
        }
    }
    
    // 保存する
    @objc private func tapDownload() {
        spinner.show(in: view)
        guard let image = imageView.image else {
            return
        }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(showResultOfSaveImage(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    // 保存結果をアラートで表示
    @objc func showResultOfSaveImage(_ image: UIImage, didFinishSavingWithError error: NSError!, contextInfo: UnsafeMutableRawPointer) {
        
        var title = "保存完了"
        var message = "カメラロールに保存しました"
        spinner.dismiss()
        
        if error != nil {
            title = "エラー"
            message = "保存に失敗しました"
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // OKボタンを追加
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // UIAlertController を表示
        self.present(alert, animated: true, completion: nil)
    }
    
    
    // 拡大縮小
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    // ズーム変更
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Keep the image at center of the screen in case that the image is smaller than the screen
        scrollView.contentInset = UIEdgeInsets(
            top: max((scrollView.frame.height - imageView.frame.height) / 2.0, 0.0),
            left: max((scrollView.frame.width - imageView.frame.width) / 2.0, 0.0),
            bottom: 0,
            right: 0
        );
    }

    
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    
    
}
