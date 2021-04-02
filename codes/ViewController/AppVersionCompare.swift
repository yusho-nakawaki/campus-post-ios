//
//  AppVersionCompare.swift
//  Match
//
//  on 2021/02/06.
//

import Foundation

enum AppVersionCompareType {
    case latest
    case old
    case error
}

class AppVersionCompare {
    static func toAppStoreVersion(appId: String, completion: @escaping (AppVersionCompareType) -> Void) {
        guard let url = URL(string: "https://itunes.apple.com/jp/lookup?id=\(appId)") else {
            completion(.error)

            return
        }

        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let data = data else {
                completion(.error)

                return
            }

            do {
                let jsonData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let storeVersion = ((jsonData?["results"] as? [Any])?.first as? [String : Any])?["version"] as? String
                    , let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
                        completion(.error)

                        return
                }

                switch storeVersion.compare(appVersion, options: .numeric) {
                case .orderedDescending:
                    //appVersion < storeVersion
                    completion(.old)
                case .orderedSame, .orderedAscending:
                    //storeVersion <= appVersion
                    completion(.latest)
                }
            }catch {
                completion(.error)
            }
        })

        task.resume()
    }
}
