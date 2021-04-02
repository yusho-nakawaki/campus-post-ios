//
//  Extension.swift
//  Study_Match
//
//  on 2020/10/16.
//  Copyright © 2020 yusho. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    public var width: CGFloat {
        return frame.size.width
    }
    public var height: CGFloat {
        return frame.size.height
    }
    public var top: CGFloat {
        return frame.origin.y
    }
    public var bottom: CGFloat {
        return frame.size.height + frame.origin.y
    }
    public var left: CGFloat {
        return frame.origin.x
    }
    public var right: CGFloat {
        return frame.size.width + frame.origin.x
    }
    
}

// 異なるViewController間で通知を行う
extension Notification.Name {
    /// we use it when login
    static let didLoginNotification = Notification.Name("didLoginNotification")
   
    ///we use it when reload data
//    static let reloadData = Notification.Name("tableViewReloadData")
}
