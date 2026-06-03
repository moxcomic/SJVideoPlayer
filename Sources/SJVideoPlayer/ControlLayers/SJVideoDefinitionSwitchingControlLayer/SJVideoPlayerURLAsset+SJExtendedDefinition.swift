//
//  SJVideoPlayerURLAsset+SJExtendedDefinition.swift
//  Pods
//
//  Created by 畅三江 on 2019/7/12.
//

import Foundation
import ObjectiveC
import SJBaseVideoPlayer

extension SJVideoPlayerURLAsset {
    
    private enum AssociatedKeys {
        // 静态稳定 key, 不使用 _cmd
        nonisolated(unsafe) static var fullName: UInt8 = 0
        nonisolated(unsafe) static var lastName: UInt8 = 0
    }
    
    /// e.g. 高清 720P
    @objc public var definition_fullName: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.fullName) as? String
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.fullName, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    /// e.g. 720P
    @objc public var definition_lastName: String? {
        get {
            if let name = objc_getAssociatedObject(self, &AssociatedKeys.lastName) as? String {
                return name
            }
            return definition_fullName
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.lastName, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
}
