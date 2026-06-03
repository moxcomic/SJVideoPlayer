//
//  SJEdgeControlButtonItem.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2018/10/19.
//  Copyright © 2018 畅三江. All rights reserved.
//
//  说明: 由 ObjC 文件 SJEdgeControlButtonItem.h / .m / SJEdgeControlButtonItemInternal.h 合并而来。
//

import UIKit
import Foundation

/// item 标识标签 (原 typedef NSInteger SJEdgeControlButtonItemTag)。
/// 这是开放扩展点, 保持为 Int, 不做封闭枚举。
public typealias SJEdgeControlButtonItemTag = Int

/// 前后间距 (原 C struct SJEdgeInsets)。
public struct SJEdgeInsets {
    /// 前间距
    public var front: CGFloat
    /// 后间距
    public var rear: CGFloat

    public init(front: CGFloat = 0, rear: CGFloat = 0) {
        self.front = front
        self.rear = rear
    }
}

/// 原 UIKIT_STATIC_INLINE SJEdgeInsetsMake(front, rear)。
@inline(__always)
public func SJEdgeInsetsMake(_ front: CGFloat, _ rear: CGFloat) -> SJEdgeInsets {
    return SJEdgeInsets(front: front, rear: rear)
}

/// item 执行 action 后发出的通知。
public let SJEdgeControlButtonItemPerformedActionNotification = Notification.Name("SJEdgeControlButtonItemPerformedActionNotification")

/// 占位 item 的类型 (原 NS_ENUM SJButtonItemPlaceholderType)。
@objc(SJButtonItemPlaceholderType)
public enum SJButtonItemPlaceholderType: UInt {
    case unknown
    /// 49 * 49
    case _49x49
    /// 49 * 自适应大小
    case _49xAutoresizing
    /// 49 * 填充父视图剩余空间
    case _49xFill
    /// 49 * 指定尺寸(水平布局时, 49为高度, `指定尺寸`为宽度. 相反的, 垂直布局时, 49为宽度, `指定尺寸`为高度)
    case _49xSpecifiedSize
}

@objc(SJEdgeControlButtonItem)
@MainActor
public class SJEdgeControlButtonItem: NSObject {

    // MARK: - 存储

    private var _actions: [SJEdgeControlButtonItemAction]?
    private var _innerHidden: Bool = false
    private var _hidden: Bool = false

    // 以下为原各 category 的私有存储 (Swift extension 无存储属性, 提升到本体)
    private var _placeholderType: SJButtonItemPlaceholderType = .unknown
    private var _size: CGFloat = 0
    private var _isFrameLayout: Bool = false

    // MARK: - 初始化

    /// 49 * 49
    @objc(initWithImage:target:action:tag:)
    public init(image: UIImage?, target: Any?, action: Selector?, tag: SJEdgeControlButtonItemTag) {
        _tag = tag
        _numberOfLines = 1
        _alpha = 1
        super.init()
        _image = image
        if let target = target, let action = action {
            addAction(SJEdgeControlButtonItemAction(target: target, action: action))
        }
    }

    /// 49 * title.size.width
    @objc(initWithTitle:target:action:tag:)
    public init(title: NSAttributedString?, target: Any?, action: Selector?, tag: SJEdgeControlButtonItemTag) {
        _tag = tag
        _numberOfLines = 1
        _alpha = 1
        super.init()
        _title = title
        if let target = target, let action = action {
            addAction(SJEdgeControlButtonItemAction(target: target, action: action))
        }
    }

    /// 49 * customView.size.width
    @objc(initWithCustomView:tag:)
    public init(customView: UIView?, tag: SJEdgeControlButtonItemTag) {
        _tag = tag
        _numberOfLines = 1
        _alpha = 1
        super.init()
        _customView = customView
    }

    @objc(initWithTag:)
    public init(tag: SJEdgeControlButtonItemTag) {
        _tag = tag
        _numberOfLines = 1
        _alpha = 1
        super.init()
    }

    @available(*, unavailable)
    public override init() {
        fatalError("init() is unavailable")
    }

    // MARK: - 属性

    /// 左右间隔, 默认{0, 0}
    public var insets: SJEdgeInsets = SJEdgeInsets(front: 0, rear: 0)

    private var _tag: SJEdgeControlButtonItemTag
    @objc public var tag: SJEdgeControlButtonItemTag {
        get { _tag }
        set { _tag = newValue }
    }

    private var _customView: UIView?
    @objc public var customView: UIView? {
        get { _customView }
        set { _customView = newValue }
    }

    private var _title: NSAttributedString?
    @objc public var title: NSAttributedString? {
        get { _title }
        set { _title = newValue }
    }

    private var _numberOfLines: Int
    /// default is 1.0
    @objc public var numberOfLines: Int {
        get { _numberOfLines }
        set { _numberOfLines = newValue }
    }

    private var _image: UIImage?
    @objc public var image: UIImage? {
        get { _image }
        set { _image = newValue }
    }

    /// getter=isHidden;
    /// 注意: isHidden 同时受 hidden 与 innerHidden 影响。
    @objc(isHidden) public var hidden: Bool {
        get { _hidden || _innerHidden }
        set { _hidden = newValue }
    }

    private var _alpha: CGFloat
    @objc public var alpha: CGFloat {
        get { _alpha }
        set { _alpha = newValue }
    }

    /// 当想要填充剩余空间时, 可以设置为`Yes`.
    @objc public var fill: Bool = false

    // MARK: - actions

    @objc public var actions: [SJEdgeControlButtonItemAction]? {
        return (_actions?.isEmpty == false) ? _actions : nil
    }

    @objc(addAction:)
    public func addAction(_ action: SJEdgeControlButtonItemAction) {
        if _actions == nil {
            _actions = []
        }
        _actions?.append(action)
    }

    @objc(removeAction:)
    public func removeAction(_ action: SJEdgeControlButtonItemAction) {
        if let idx = _actions?.firstIndex(of: action) {
            _actions?.remove(at: idx)
        }
    }

    @objc public func removeAllActions() {
        _actions?.removeAll()
    }

    @objc public func performActions() {
        if let actions = _actions {
            for action in actions {
                if let handler = action.handler {
                    handler(action)
                } else if let target = action.target as? NSObject,
                          let sel = action.action,
                          target.responds(to: sel) {
                    target.perform(sel, with: self)
                }
            }
        }
        NotificationCenter.default.post(name: SJEdgeControlButtonItemPerformedActionNotification, object: self)
    }

    // MARK: - SJInternal

    /// 是否被 sdk 内部设置隐藏了 (原 category SJInternal, getter=isInnerHidden)。
    @objc(isInnerHidden) public var innerHidden: Bool {
        get { _innerHidden }
        set { _innerHidden = newValue }
    }

    // MARK: - Placeholder

    /// 占位Item
    /// 先占好位置, 后更新属性
    @objc(placeholderWithType:tag:)
    public static func placeholder(type placeholderType: SJButtonItemPlaceholderType, tag: SJEdgeControlButtonItemTag) -> SJEdgeControlButtonItem {
        let item = SJEdgeControlButtonItem(tag: tag)
        item._placeholderType = placeholderType
        if placeholderType == ._49xFill { item.fill = true }
        return item
    }

    /// `placeholderType == SJButtonItemPlaceholderType_49xSpecifiedSize`
    @objc(placeholderWithSize:tag:)
    public static func placeholder(size: CGFloat, tag: SJEdgeControlButtonItemTag) -> SJEdgeControlButtonItem {
        let item = SJEdgeControlButtonItem(tag: tag)
        item._placeholderType = ._49xSpecifiedSize
        item.size = size
        return item
    }

    @objc public var placeholderType: SJButtonItemPlaceholderType {
        return _placeholderType
    }

    @objc public var size: CGFloat {
        get { _size }
        set { _size = newValue }
    }

    // MARK: - FrameLayout

    /// - 此分类只配合帧布局使用(SJAdapterLayoutTypeFrameLayout), 其他布局无效
    /// - 请设置`customView`的`bounds`
    @objc(frameLayoutWithCustomView:tag:)
    public static func frameLayout(customView: UIView, tag: SJEdgeControlButtonItemTag) -> SJEdgeControlButtonItem {
        let item = SJEdgeControlButtonItem(customView: customView, tag: tag)
        item._isFrameLayout = true
        return item
    }

    @objc(isFrameLayout) public var isFrameLayout: Bool {
        return _isFrameLayout
    }

    // MARK: - SJDeprecated

    @available(*, deprecated, message: "use `addAction:`;")
    @objc(addTarget:action:)
    public func addTarget(_ target: Any, action: Selector) {
        removeAllActions()
        addAction(SJEdgeControlButtonItemAction(target: target, action: action))
    }

    @available(*, deprecated, message: "use `performActions`;")
    @objc public func performAction() {
        performActions()
    }
}

// MARK: - action

@objc(SJEdgeControlButtonItemAction)
@MainActor
public class SJEdgeControlButtonItemAction: NSObject {

    @objc(actionWithTarget:action:)
    public static func action(target: Any, action: Selector) -> SJEdgeControlButtonItemAction {
        return SJEdgeControlButtonItemAction(target: target, action: action)
    }

    @objc(actionWithHandler:)
    public static func action(handler: @escaping (SJEdgeControlButtonItemAction) -> Void) -> SJEdgeControlButtonItemAction {
        return SJEdgeControlButtonItemAction(handler: handler)
    }

    @objc(initWithTarget:action:)
    public init(target: Any, action: Selector) {
        _target = target as AnyObject
        _action = action
        _handler = nil
        super.init()
    }

    @objc(initWithHandler:)
    public init(handler: @escaping (SJEdgeControlButtonItemAction) -> Void) {
        _target = nil
        _action = nil
        _handler = handler
        super.init()
    }

    private weak var _target: AnyObject?
    @objc public var target: Any? {
        return _target
    }

    private let _action: Selector?
    @objc public var action: Selector? {
        return _action
    }

    private let _handler: ((SJEdgeControlButtonItemAction) -> Void)?
    @objc public var handler: ((SJEdgeControlButtonItemAction) -> Void)? {
        return _handler
    }
}
