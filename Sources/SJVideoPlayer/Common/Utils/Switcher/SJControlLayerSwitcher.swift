//
//  SJControlLayerSwitcher.swift
//  SJVideoPlayerProject
//
//  Created by 畅三江 on 2018/6/1.
//  Copyright © 2018年 畅三江. All rights reserved.
//

import Foundation
import SJBaseVideoPlayer

/// 未初始化的控制层标识 (= LONG_MAX), 数值契约原样保留。
public let SJControlLayer_Uninitialized: SJControlLayerIdentifier = SJControlLayerIdentifier(Int.max)

// MARK: - 私有通知名 / userInfo key (字符串字面量原样保留)

private let SJPlayerSwitchControlLayerUserInfoKey = "SJPlayerSwitchControlLayerUserInfoKey"
private let SJPlayerWillBeginSwitchControlLayerNotification = Notification.Name("SJPlayerWillBeginSwitchControlLayerNotification")
private let SJPlayerDidEndSwitchControlLayerNotification = Notification.Name("SJPlayerDidEndSwitchControlLayerNotification")

// MARK: - 控制层切换器 switcher 协议

/// - 控制层切换器 switcher -
///
/// - 使用示例请查看 `SJVideoPlayer` 的 `init` 方法.
///
/// 注: 协议与同名类撞名, 协议加 `_Protocol` 后缀, 仍以 `@objc(SJControlLayerSwitcher)` 暴露原 ObjC 名。
@MainActor
@objc(SJControlLayerSwitcher)
public protocol SJControlLayerSwitcher_Protocol: NSObjectProtocol {
    init(player: SJBaseVideoPlayer?)

    /// 切换控制层
    ///
    /// - 将当前的控制层切换为指定标识的控制层
    @objc(switchControlLayerForIdentifier:)
    func switchControlLayer(forIdentifier identifier: SJControlLayerIdentifier)

    @objc(switchToPreviousControlLayer)
    func switchToPreviousControlLayer() -> Bool

    /// 添加或替换原有控制层
    ///
    /// - 控制层将在第一次切换时创建, 该控制层只会被创建一次
    @objc(addControlLayerForIdentifier:lazyLoading:)
    func addControlLayer(forIdentifier identifier: SJControlLayerIdentifier,
                         lazyLoading loading: ((SJControlLayerIdentifier) -> (any SJControlLayer)?)?)

    /// 删除控制层
    @objc(deleteControlLayerForIdentifier:)
    func deleteControlLayer(forIdentifier identifier: SJControlLayerIdentifier)

    /// 是否已存在
    @objc(containsControlLayer:)
    func containsControlLayer(_ identifier: SJControlLayerIdentifier) -> Bool

    /// 获取某个控制层
    ///
    /// - 如果不存在, 将返回 nil
    @objc(controlLayerForIdentifier:)
    func controlLayer(forIdentifier identifier: SJControlLayerIdentifier) -> (any SJControlLayer)?

    /// 获取一个切换器观察者
    ///
    /// - 你需要对它强引用, 否则会被释放
    @objc(getObserver)
    func getObserver() -> any SJControlLayerSwitcherObserver_Protocol

    /// 当 `switchControlLayerForIdentifier:` 无对应的控制层时, 该 block 将会被调用
    @objc var resolveControlLayer: ((SJControlLayerIdentifier) -> (any SJControlLayer)?)? { get set }

    @objc weak var delegate: (any SJControlLayerSwitcherDelegate_Protocol)? { get set }
    @objc var previousIdentifier: SJControlLayerIdentifier { get }
    @objc var currentIdentifier: SJControlLayerIdentifier { get }
}

// MARK: - 切换器代理

/// 切换器代理 (全 @optional)。
@MainActor
@objc(SJControlLayerSwitcherDelegate)
public protocol SJControlLayerSwitcherDelegate_Protocol: NSObjectProtocol {
    @objc(switcher:shouldSwitchToControlLayer:)
    optional func switcher(_ switcher: any SJControlLayerSwitcher_Protocol,
                           shouldSwitchToControlLayer identifier: SJControlLayerIdentifier) -> Bool

    @objc(switcher:controlLayerForIdentifier:)
    optional func switcher(_ switcher: any SJControlLayerSwitcher_Protocol,
                           controlLayerForIdentifier identifier: SJControlLayerIdentifier) -> (any SJControlLayer)?
}

// MARK: - 切换器观察者

/// 切换器观察者: 持有两个 block, 分别在控制层切换开始/结束时回调。
@MainActor
@objc(SJControlLayerSwitcherObserver)
public protocol SJControlLayerSwitcherObserver_Protocol: NSObjectProtocol {
    @objc var playerWillBeginSwitchControlLayer: ((any SJControlLayerSwitcher_Protocol, any SJControlLayer) -> Void)? { get set }
    @objc var playerDidEndSwitchControlLayer: ((any SJControlLayerSwitcher_Protocol, any SJControlLayer) -> Void)? { get set }
}

// MARK: - 观察者实现 (原 .m 内私有类 SJControlLayerSwitcherObserver)

/// 观察者实现: 通过私有通知桥接到具体切换器。原 ObjC 同名私有类, 这里改私有名以避免与协议冲突。
@MainActor
private final class SJControlLayerSwitcherObserverImpl: NSObject, SJControlLayerSwitcherObserver_Protocol {
    var playerWillBeginSwitchControlLayer: ((any SJControlLayerSwitcher_Protocol, any SJControlLayer) -> Void)?
    var playerDidEndSwitchControlLayer: ((any SJControlLayerSwitcher_Protocol, any SJControlLayer) -> Void)?

    init(switcher: any SJControlLayerSwitcher_Protocol) {
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willBeginSwitchControlLayer(_:)),
                                               name: SJPlayerWillBeginSwitchControlLayerNotification,
                                               object: switcher)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEndSwitchControlLayer(_:)),
                                               name: SJPlayerDidEndSwitchControlLayerNotification,
                                               object: switcher)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func willBeginSwitchControlLayer(_ note: Notification) {
        guard let block = playerWillBeginSwitchControlLayer,
              let switcher = note.object as? any SJControlLayerSwitcher_Protocol,
              let controlLayer = note.userInfo?[SJPlayerSwitchControlLayerUserInfoKey] as? any SJControlLayer else { return }
        block(switcher, controlLayer)
    }

    @objc private func didEndSwitchControlLayer(_ note: Notification) {
        guard let block = playerDidEndSwitchControlLayer,
              let switcher = note.object as? any SJControlLayerSwitcher_Protocol,
              let controlLayer = note.userInfo?[SJPlayerSwitchControlLayerUserInfoKey] as? any SJControlLayer else { return }
        block(switcher, controlLayer)
    }
}

// MARK: - 切换器实现

/// 控制层切换器具体实现。门面以具体类形式公开持有。
@MainActor
@objc(SJControlLayerSwitcher)
public final class SJControlLayerSwitcher: NSObject, SJControlLayerSwitcher_Protocol {

    private weak var videoPlayer: SJBaseVideoPlayer?
    /// identifier -> 控制层对象 或 lazyLoading block
    private var map: [SJControlLayerIdentifier: Any] = [:]

    public private(set) var previousIdentifier: SJControlLayerIdentifier = SJControlLayer_Uninitialized
    public private(set) var currentIdentifier: SJControlLayerIdentifier = SJControlLayer_Uninitialized
    public weak var delegate: (any SJControlLayerSwitcherDelegate_Protocol)?
    public var resolveControlLayer: ((SJControlLayerIdentifier) -> (any SJControlLayer)?)?

    public init(player videoPlayer: SJBaseVideoPlayer?) {
        self.videoPlayer = videoPlayer
        super.init()
    }

#if DEBUG
    deinit {
        print("\(#line) \t \(#function)")
    }
#endif

    public func getObserver() -> any SJControlLayerSwitcherObserver_Protocol {
        return SJControlLayerSwitcherObserverImpl(switcher: self)
    }

    public func switchControlLayer(forIdentifier identifier: SJControlLayerIdentifier) {
        if let delegate = delegate,
           delegate.responds(to: #selector(SJControlLayerSwitcherDelegate_Protocol.switcher(_:shouldSwitchToControlLayer:))) {
            if delegate.switcher?(self, shouldSwitchToControlLayer: identifier) == false {
                return
            }
        }

        let oldValue = videoPlayer?.controlLayerDataSource as? any SJControlLayer
        var newValue = controlLayer(forIdentifier: identifier)
        if newValue == nil, let resolve = resolveControlLayer {
            let resolved = resolve(identifier)
            newValue = resolved
            addControlLayer(forIdentifier: identifier, lazyLoading: { _ in
                return resolved
            })
        }
        assert(newValue != nil)
        guard let newValue = newValue else { return }
        if let oldValue = oldValue, oldValue === newValue {
            return
        }

        // - begin -
        NotificationCenter.default.post(name: SJPlayerWillBeginSwitchControlLayerNotification,
                                        object: self,
                                        userInfo: [SJPlayerSwitchControlLayerUserInfoKey: newValue])

        oldValue?.exitControlLayer()
        videoPlayer?.controlLayerDataSource = nil
        videoPlayer?.controlLayerDelegate = nil

        // update identifiers
        previousIdentifier = currentIdentifier
        currentIdentifier = identifier

        videoPlayer?.controlLayerDataSource = newValue
        videoPlayer?.controlLayerDelegate = newValue
        newValue.restartControlLayer()

        // - end -
        NotificationCenter.default.post(name: SJPlayerDidEndSwitchControlLayerNotification,
                                        object: self,
                                        userInfo: [SJPlayerSwitchControlLayerUserInfoKey: newValue])
    }

    public func switchToPreviousControlLayer() -> Bool {
        if previousIdentifier == SJControlLayer_Uninitialized { return false }
        if videoPlayer == nil { return false }
        switchControlLayer(forIdentifier: previousIdentifier)
        return true
    }

    public func addControlLayer(forIdentifier identifier: SJControlLayerIdentifier,
                                lazyLoading loading: ((SJControlLayerIdentifier) -> (any SJControlLayer)?)?) {
#if DEBUG
        assert(loading != nil)
#endif
        guard let loading = loading else { return }
        map[identifier] = loading
        if currentIdentifier == identifier {
            switchControlLayer(forIdentifier: identifier)
        }
    }

    public func deleteControlLayer(forIdentifier identifier: SJControlLayerIdentifier) {
        map.removeValue(forKey: identifier)
    }

    public func controlLayer(forIdentifier identifier: SJControlLayerIdentifier) -> (any SJControlLayer)? {
        if let delegate = delegate,
           delegate.responds(to: #selector(SJControlLayerSwitcherDelegate_Protocol.switcher(_:controlLayerForIdentifier:))) {
            if let controlLayer = delegate.switcher?(self, controlLayerForIdentifier: identifier) {
                return controlLayer
            }
        }

        guard let controlLayerOrBlock = map[identifier] else {
            return nil
        }

        // loaded
        if let controlLayer = controlLayerOrBlock as? any SJControlLayer {
            return controlLayer
        }

        // lazy loading
        if let block = controlLayerOrBlock as? (SJControlLayerIdentifier) -> (any SJControlLayer)? {
            if let controlLayer = block(identifier) {
                map[identifier] = controlLayer
                return controlLayer
            }
        }
        return nil
    }

    public func containsControlLayer(_ identifier: SJControlLayerIdentifier) -> Bool {
        return controlLayer(forIdentifier: identifier) != nil
    }
}
