//
//  StorageManager.swift
//  Study_Match
//
//  on 2020/11/01.
//  Copyright © 2020 yusho. All rights reserved.
//

import Foundation
import FirebaseStorage

class StorageManager {
    
    static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    
    private init() {}
    
    // fileName = "/profile_picture/\(safeEmail-profile.png)"
    public typealias uploadPictureCompletion = (Result<String, Error>) -> Void
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping uploadPictureCompletion) {
        storage.child("profile_picture/\(fileName)").putData(data, metadata: nil, completion: { [weak self]metaData, error in
            guard error == nil else {
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self?.storage.child("profile_picture/\(fileName)").downloadURL(completion: { (url, err) in
                guard let url = url else {
                    completion(.failure(StorageError.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                completion(.success(urlString))
            })
        })
    }
    
    public func uploadMessagePhoto(with data: Data, fileName: String, partnerSafeEmail: String, completion: @escaping uploadPictureCompletion) {
        storage.child("message_pictures/\(partnerSafeEmail)_isReceived/\(fileName)").putData(data, metadata: nil, completion: { [weak self]metaData, error in
            guard error == nil else {
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self?.storage.child("message_pictures/\(partnerSafeEmail)_isReceived/\(fileName)").downloadURL(completion: { (url, err) in
                guard let url = url else {
                    completion(.failure(StorageError.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("download url: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    public func uploadCommunityPicture(with data: Data, fileName: String, completion: @escaping uploadPictureCompletion) {
        storage.child("community-picture/\(fileName)").putData(data, metadata: nil, completion: { [weak self]metaData, error in
            guard error == nil else {
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self?.storage.child("community-picture/\(fileName)").downloadURL(completion: { (url, err) in
                guard let url = url else {
                    completion(.failure(StorageError.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                completion(.success(urlString))
            })
        })
    }
    
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    /// Upload video that will be sent in a conversation message
    public func uploadMessageVideo1(with fileUrl: URL, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                // failed
                print("failed to upload video file to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("message_videos/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }

    
    
    
//    public func uploadMessageVideo(with fileUrl: URL, fileName: String, partnerSafeEmail: String, completion: @escaping uploadPictureCompletion) {
//        storage.child("message_videos/\(partnerSafeEmail)_isReceived/\(fileName)").putFile(from: fileUrl, metadata: nil, completion: { [weak self]metaData, error in
//            guard error == nil else {
//                completion(.failure(StorageError.failedToUpload))
//                return
//            }
//
//            self?.storage.child("message_videos/\(partnerSafeEmail)_isReceived/\(fileName)").downloadURL(completion: { (url, err) in
//                guard let url = url else {
//                    completion(.failure(StorageError.failedToGetDownloadUrl))
//                    return
//                }
//                let urlString = url.absoluteString
//                print("download url: \(urlString)")
//                completion(.success(urlString))
//            })
//        })
//    }
    
    // 投稿記事の写真
    public func insertPostPicture(email: String, date: String, photoArray: [Data], completion: @escaping (Result<[String], Error>) -> Void) {
        
        var resultPhoto = [String]()
        var i = 0
        var count = 0
        
        for photo in photoArray {
            i += 1
            let path = "posts/\(email)/\(date)_\(i)"
            storage.child(path).putData(photo, metadata: nil, completion: { [weak self]metaData, error in
                guard error == nil else {
                    completion(.failure(StorageError.failedToUpload))
                    return
                }


                self?.storage.child(path).downloadURL(completion: { (url, err) in
                    guard let url = url else {
                        completion(.failure(StorageError.failedToGetDownloadUrl))
                        return
                    }
                    let urlString = url.absoluteString
                    resultPhoto.append(urlString)
                    count += 1
                    if count == photoArray.count {
                        completion(.success(resultPhoto))
                        return
                    }
                })
            })
        }
    }
    
    public enum StorageError: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
    public func getDownloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        storage.child(path).downloadURL { (url, err) in
            guard let url = url,
                err == nil else {
                    completion(.failure(StorageError.failedToGetDownloadUrl))
                    return
            }
            
            completion(.success(url))
        }
    }
    
    
    public func deleteAllFile(email: String) {
        storage.child("profile_picture/\(email)-profile.png").delete(completion: nil)
    }
}
