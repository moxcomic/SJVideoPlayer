//
//  UIView+SJAnimationAdded.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2018/10/23.
//  Copyright © 2018 畅三江. All rights reserved.
//

import UIKit
import ObjectiveC.runtime

/// 视图消失动画方向
@objc(SJViewDisappearAnimation)
public enum SJViewDisappearAnimation: UInt {
    case none
    case top
    case left
    case bottom
    case right
    case horizontalScaling // 水平缩放
    case verticalScaling   // 垂直缩放
}

// MARK: - 关联对象 key (静态稳定 key)

private nonisolated(unsafe) var kSjvDisappeared: UInt8 = 0
private nonisolated(unsafe) var kSjvDisappearDirection: UInt8 = 0

// MARK: - UIView (SJAnimationAdded)

@MainActor
extension UIView {
    /// 消失方向
    @objc public var sjv_disappearDirection: SJViewDisappearAnimation {
        get {
            let raw = (objc_getAssociatedObject(self, &kSjvDisappearDirection) as? NSNumber)?.uintValue ?? 0
            return SJViewDisappearAnimation(rawValue: raw) ?? .none
        }
        set {
            objc_setAssociatedObject(self, &kSjvDisappearDirection, NSNumber(value: newValue.rawValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 是否已消失
    @objc public var sjv_disappeared: Bool {
        get {
            (objc_getAssociatedObject(self, &kSjvDisappeared) as? NSNumber)?.boolValue ?? false
        }
        set {
            objc_setAssociatedObject(self, &kSjvDisappeared, NSNumber(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Animatable. 可动画的
    @objc public func sjv_disapear() {
        var transform = CGAffineTransform.identity
        switch sjv_disappearDirection {
        case .none:
            break
        case .top:
            transform = CGAffineTransform(translationX: 0, y: -bounds.size.height)
        case .left:
            transform = CGAffineTransform(translationX: -bounds.size.width, y: 0)
        case .bottom:
            transform = CGAffineTransform(translationX: 0, y: bounds.size.height)
        case .right:
            transform = CGAffineTransform(translationX: bounds.size.width, y: 0)
        case .horizontalScaling:
            transform = CGAffineTransform(scaleX: 0.001, y: 1)
        case .verticalScaling:
            transform = CGAffineTransform(scaleX: 1, y: 0.001)
        }
        self.transform = transform
        self.alpha = 0.001
        self.sjv_disappeared = true
    }

    /// Animatable. 可动画的
    @objc public func sjv_appear() {
        self.transform = .identity
        self.alpha = 1
        self.sjv_disappeared = false
    }
}

// MARK: - C 函数族 (overloadable 展开为 Swift 重载 / 默认参数)

@MainActor
public func sj_view_isDisappeared(_ view: UIView?) -> Bool {
    guard let view = view else { return false }
    return view.sjv_disappeared
}

@MainActor
public func sj_view_initializes(_ view: UIView) {
    view.alpha = 0.001
}

@MainActor
public func sj_view_initializes(_ views: [UIView]) {
    for view in views {
        sj_view_initializes(view)
    }
}

// MARK: appear

@MainActor
public func sj_view_makeAppear(_ view: UIView?, _ animated: Bool, _ completionHandler: (@MainActor () -> Void)? = nil) {
    guard let view = view else { return }
    sj_view_makeAppear([view], animated, completionHandler)
}

@MainActor
public func sj_view_makeAppear(_ views: [UIView], _ animated: Bool, _ completionHandler: (@MainActor () -> Void)? = nil) {
    if views.isEmpty { return }
    for view in views {
        view.sjv_disappeared = false
        UIView.animate(withDuration: 0, animations: {}, completion: { _ in
            if animated {
                UIView.animate(withDuration: SJVideoPlayerConfigurations.shared.animationDuration, animations: {
                    view.sjv_appear()
                }, completion: { _ in
                    if view == views.last { completionHandler?() }
                })
            } else {
                view.sjv_appear()
                if view == views.last { completionHandler?() }
            }
        })
    }
}

// MARK: disappear

@MainActor
public func sj_view_makeDisappear(_ view: UIView?, _ animated: Bool, _ completionHandler: (@MainActor () -> Void)? = nil) {
    guard let view = view else { return }
    sj_view_makeDisappear([view], animated, completionHandler)
}

@MainActor
public func sj_view_makeDisappear(_ views: [UIView], _ animated: Bool, _ completionHandler: (@MainActor () -> Void)? = nil) {
    if views.isEmpty { return }
    for view in views {
        view.sjv_disappeared = true
        UIView.animate(withDuration: 0, animations: {}, completion: { _ in
            if animated {
                UIView.animate(withDuration: SJVideoPlayerConfigurations.shared.animationDuration, animations: {
                    view.sjv_disapear()
                }, completion: { _ in
                    if view == views.last { completionHandler?() }
                })
            } else {
                view.sjv_disapear()
                if view == views.last { completionHandler?() }
            }
        })
    }
}
