//
//  SJVideoPlayer.swift
//  SJVideoPlayerProject
//
//  Created by 畅三江 on 2018/5/29.
//  Copyright © 2018年 畅三江. All rights reserved.
//
//  GitHub:     https://github.com/changsanjiang/SJBaseVideoPlayer
//  GitHub:     https://github.com/changsanjiang/SJVideoPlayer
//
//  Email:      changsanjiang@gmail.com
//  QQGroup:    930508201
//
//  Swift 6 迁移说明:
//  - 对外门面单例与便捷 API。注册各控制层到 switcher。
//  - 整类 @MainActor(全程主线程操作 view)。
//  - 门面对 SJEdgeControlLayer 的 category 存储属性(showsMoreItem / isEnabledClips /
//    clipsConfig)仍以关联对象实现, 因 SJEdgeControlLayer 在本块外定义, extension 无存储属性。
//  - 门面自身对 SJVideoPlayerURLAsset 清晰度数组等的 category 存储属性提升为本体 stored property。
//

import Foundation
import UIKit
import ObjectiveC
import SJBaseVideoPlayer
import SJUIKit

// MARK: - 自定义通知名(保留原字符串字面量)

/// 对应 ObjC `#define SJEdgeControlLayerShowsMoreItemNotification`。
let SJEdgeControlLayerShowsMoreItemNotification = Notification.Name("SJEdgeControlLayerShowsMoreItemNotification")
/// 对应 ObjC `#define SJEdgeControlLayerIsEnabledClipsNotification`。
let SJEdgeControlLayerIsEnabledClipsNotification = Notification.Name("SJEdgeControlLayerIsEnabledClipsNotification")

// MARK: - SJEdgeControlLayer (SJVideoPlayerExtended)

/// 物理上属于 SJVideoPlayer.h/.m, 宿主类 SJEdgeControlLayer 定义在 ControlLayers 区。
/// SJEdgeControlLayer 为本块外的类型, Swift extension 无存储属性, 故沿用 ObjC 关联对象方案;
/// 不能用 `_cmd` 作 key, 改用静态稳定 key。
@MainActor
extension SJEdgeControlLayer {

    private enum SJVideoPlayerExtendedAssociatedKeys {
        nonisolated(unsafe) static var showsMoreItem: UInt8 = 0
        nonisolated(unsafe) static var isEnabledClips: UInt8 = 0
        nonisolated(unsafe) static var clipsConfig: UInt8 = 0
    }

    ///
    /// 是否在 Top 栏上显示 `more item`(三个点). default value is YES
    ///
    /// 如果需要关闭, 可以设置: player.defaultEdgeControlLayer.showsMoreItem = NO;
    ///
    @objc public var showsMoreItem: Bool {
        get {
            (objc_getAssociatedObject(self, &SJVideoPlayerExtendedAssociatedKeys.showsMoreItem) as? NSNumber)?.boolValue ?? false
        }
        set {
            if newValue != showsMoreItem {
                objc_setAssociatedObject(self, &SJVideoPlayerExtendedAssociatedKeys.showsMoreItem, NSNumber(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                NotificationCenter.default.post(name: SJEdgeControlLayerShowsMoreItemNotification, object: self)
            }
        }
    }

    ///
    /// 是否开启剪辑功能
    ///         - 默认是 NO
    ///         - 不支持剪辑 m3u8(如果开启, 将会自动隐藏剪辑按钮)
    ///
    @objc(isEnabledClips) public var enabledClips: Bool {
        get {
            (objc_getAssociatedObject(self, &SJVideoPlayerExtendedAssociatedKeys.isEnabledClips) as? NSNumber)?.boolValue ?? false
        }
        set {
            if newValue != enabledClips {
                objc_setAssociatedObject(self, &SJVideoPlayerExtendedAssociatedKeys.isEnabledClips, NSNumber(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                NotificationCenter.default.post(name: SJEdgeControlLayerIsEnabledClipsNotification, object: self)
            }
        }
    }

    ///
    /// 剪辑功能配置(null_resettable, 懒构建)
    ///
    @objc public var clipsConfig: SJVideoPlayerClipsConfig! {
        get {
            if let config = objc_getAssociatedObject(self, &SJVideoPlayerExtendedAssociatedKeys.clipsConfig) as? SJVideoPlayerClipsConfig {
                return config
            }
            let config = SJVideoPlayerClipsConfig()
            objc_setAssociatedObject(self, &SJVideoPlayerExtendedAssociatedKeys.clipsConfig, config, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return config
        }
        set {
            objc_setAssociatedObject(self, &SJVideoPlayerExtendedAssociatedKeys.clipsConfig, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: - SJVideoPlayer 门面

/// 门面同时遵循各控制层的代理协议(原 ObjC 在 class extension 中声明):
/// SJVideoDefinitionSwitchingControlLayerDelegate / SJMoreSettingControlLayerDelegate /
/// SJNotReachableControlLayerDelegate / SJEdgeControlLayerDelegate。
/// 这些代理协议按仓库惯例已加 `_Protocol` 后缀。
@MainActor
@objc(SJVideoPlayer)
open class SJVideoPlayer: SJBaseVideoPlayer,
                          SJVideoDefinitionSwitchingControlLayerDelegate_Protocol,
                          SJMoreSettingControlLayerDelegate_Protocol,
                          SJNotReachableControlLayerDelegate_Protocol,
                          SJEdgeControlLayerDelegate_Protocol {

    // MARK: 私有状态

    private var sj_smallViewFloatingControllerObserver: (any SJSmallViewFloatingControllerObserverProtocol)?
    private var _sj_switchingInfoObserver: SJVideoDefinitionSwitchingInfoObserver?
    private var sj_appearManagerObserver: (any SJControlLayerAppearManagerObserver_Protocol)?
    private var sj_switcherObserver: (any SJControlLayerSwitcherObserver_Protocol)?

    private var moreItem: SJEdgeControlButtonItem?
    private var clipsItem: SJEdgeControlButtonItem?
    private var definitionItem: SJEdgeControlButtonItem?

    /// 用于断网之后(当网络恢复后使播放器自动恢复播放)
    private var sj_reachabilityObserver: (any SJReachabilityObserver_Protocol)?
    private var sj_timeoutTimer: Timer?
    private var sj_isTimeout: Bool = false

    // MARK: 控制层切换器与各默认控制层(懒加载)

    ///
    /// v2.0.8
    ///
    /// 新增: 控制层 切换器, 管理控制层的切换
    ///
    @objc public private(set) var switcher: SJControlLayerSwitcher!

    private var _defaultEdgeControlLayer: SJEdgeControlLayer?
    private var _defaultNotReachableControlLayer: SJNotReachableControlLayer?
    private var _defaultClipsControlLayer: SJClipsControlLayer?
    private var _defaultMoreSettingControlLayer: SJMoreSettingControlLayer?
    private var _defaultLoadFailedControlLayer: SJLoadFailedControlLayer?
    private var _defaultSmallViewControlLayer: SJSmallViewControlLayer?
    private var _defaultVideoDefinitionSwitchingControlLayer: SJVideoDefinitionSwitchingControlLayer?

    ///
    /// 切换清晰度时使用的清晰度资源数组
    ///
    /// 提升为本体 stored property(原 ObjC 为关联对象 category)。
    ///
    @objc public var definitionURLAssets: [SJVideoPlayerURLAsset]? {
        didSet {
            let adapter = defaultEdgeControlLayer.bottomAdapter
            if definitionURLAssets != nil {
                if definitionItem == nil {
                    let item = SJEdgeControlButtonItem.placeholder(type: ._49xAutoresizing, tag: SJEdgeControlLayerBottomItem_Definition)
                    item.addAction(SJEdgeControlButtonItemAction.action(target: self, action: #selector(_definitionItemWasTapped(_:))))
                    definitionItem = item
                    adapter.insertItem(item, rearItem: SJEdgeControlLayerBottomItem_Full)
                }
                _updateContentForDefinitionItemIfNeeded()
            }
            else {
                _defaultVideoDefinitionSwitchingControlLayer = nil
                definitionItem = nil
                adapter.removeItem(forTag: SJEdgeControlLayerBottomItem_Definition)
                switcher.switchControlLayer(forIdentifier: SJControlLayer_SwitchVideoDefinition)
                defaultEdgeControlLayer.bottomAdapter.reload()
            }
        }
    }

    /// 切换清晰度时, 是否关掉切换进度的提示. default value is NO.
    @objc(isDisabledDefinitionSwitchingPrompt) public var disabledDefinitionSwitchingPrompt: Bool = false

    // MARK: 初始化 / 工厂 / 版本

    ///
    /// 使用默认的控制层
    ///
    open override class func player() -> Self {
        return self.init()
    }

    ///
    /// A lightweight player with simple functions.
    ///
    /// 一个具有简单功能的播放器.
    ///
    /// v2.4.0 之后删除了旧的 lightweightPlayer 控制层, 迁移至 defaultEdgeControlLayer
    ///
    @objc(lightweightPlayer) public class func lightweightPlayer() -> SJVideoPlayer {
        let videoPlayer = SJVideoPlayer(performsDefaultControlLayerSwitch: false)
        let controlLayer = videoPlayer.defaultEdgeControlLayer
        controlLayer.hiddenBottomProgressIndicator = false
        controlLayer.topContainerView.sjv_disappearDirection = .none
        controlLayer.leftContainerView.sjv_disappearDirection = .none
        controlLayer.bottomContainerView.sjv_disappearDirection = .none
        controlLayer.rightContainerView.sjv_disappearDirection = .none
        controlLayer.topAdapter.reload()
        videoPlayer.switcher.switchControlLayer(forIdentifier: SJControlLayer_Edge)
        return videoPlayer
    }

    ///
    /// 指定初始化器。
    /// - performsDefaultControlLayerSwitch == true 对应原 ObjC `-init`(切换到 Edge 并显示更多按钮);
    /// - performsDefaultControlLayerSwitch == false 对应原 ObjC `-_init`(仅装配, 不切换控制层),
    ///   供 lightweightPlayer 使用。
    ///
    private init(performsDefaultControlLayerSwitch: Bool) {
        super.init()
        _observeNotifies()
        _initializeSwitcher()
        _initializeSwitcherObserver()
        _initializeSettingsObserver()
        _initializeAppearManagerObserver()
        _initializeReachabilityObserver()
        _configurationsDidUpdate()
        // 原 ObjC 通过覆写 -smallViewFloatingController / -setSmallViewFloatingController: 在每次
        // 取/设时附加观察者; SJBaseVideoPlayer 的该属性现定义在 extension 中, Swift 子类无法覆写,
        // 故在此提前附加观察者(默认 enabled=false, 控制器仅在用户开启小浮窗后才会出现, 观察者
        // onAppearChanged 也仅在出现时回调, 因此提前创建无副作用)。
        _initializeSmallViewFloatingControllerObserverIfNeeded(smallViewFloatingController)

        if performsDefaultControlLayerSwitch {
            switcher.switchControlLayer(forIdentifier: SJControlLayer_Edge) // 切换到添加的控制层
            defaultEdgeControlLayer.showsMoreItem = true                    // 显示更多按钮
        }
    }

    /// 对应原 ObjC `-init`。
    @objc public required convenience init() {
        self.init(performsDefaultControlLayerSwitch: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        #if DEBUG
        print("\(#line) \t \(#function)")
        #endif
    }

    open override class func version() -> String {
        return "v3.4.3"
    }

    // MARK: 各默认控制层(懒加载 getter)

    ///
    /// 默认的边缘控制层
    ///
    @objc public var defaultEdgeControlLayer: SJEdgeControlLayer {
        if let layer = _defaultEdgeControlLayer { return layer }
        let layer = SJEdgeControlLayer()
        layer.delegate = self
        _defaultEdgeControlLayer = layer
        return layer
    }

    ///
    /// 默认的无网状态下显示的控制层
    ///
    @objc public var defaultNotReachableControlLayer: SJNotReachableControlLayer {
        if let layer = _defaultNotReachableControlLayer { return layer }
        let layer = SJNotReachableControlLayer(frame: view.bounds)
        layer.delegate = self
        _defaultNotReachableControlLayer = layer
        return layer
    }

    ///
    /// 默认的剪辑(GIF, Export, Screenshot)控制层
    ///
    @objc public var defaultClipsControlLayer: SJClipsControlLayer {
        if let layer = _defaultClipsControlLayer { return layer }
        let layer = SJClipsControlLayer()
        layer.cancelledOperationExeBlock = { [weak self] _ in
            guard let self = self else { return }
            _ = self.switcher.switchToPreviousControlLayer()
        }
        _defaultClipsControlLayer = layer
        return layer
    }

    ///
    /// 默认的 `more setting` 控制层(调整音量/亮度/速率)
    ///
    @objc public var defaultMoreSettingControlLayer: SJMoreSettingControlLayer {
        if let layer = _defaultMoreSettingControlLayer { return layer }
        let layer = SJMoreSettingControlLayer()
        layer.delegate = self
        _defaultMoreSettingControlLayer = layer
        return layer
    }

    ///
    /// 默认的加载失败或播放出错时显示的控制层
    ///
    @objc public var defaultLoadFailedControlLayer: SJLoadFailedControlLayer {
        if let layer = _defaultLoadFailedControlLayer { return layer }
        let layer = SJLoadFailedControlLayer()
        layer.delegate = self
        _defaultLoadFailedControlLayer = layer
        return layer
    }

    ///
    /// 默认的小浮窗模式下的控制层
    ///
    @objc public var defaultSmallViewControlLayer: SJSmallViewControlLayer {
        if let layer = _defaultSmallViewControlLayer { return layer }
        let layer = SJSmallViewControlLayer(frame: view.bounds)
        _defaultSmallViewControlLayer = layer
        return layer
    }

    ///
    /// 默认的切换清晰度时的控制层
    ///
    @objc public var defaultVideoDefinitionSwitchingControlLayer: SJVideoDefinitionSwitchingControlLayer {
        if let layer = _defaultVideoDefinitionSwitchingControlLayer { return layer }
        let layer = SJVideoDefinitionSwitchingControlLayer(frame: view.bounds)
        layer.delegate = self
        _defaultVideoDefinitionSwitchingControlLayer = layer
        return layer
    }

    private var sj_switchingInfoObserver: SJVideoDefinitionSwitchingInfoObserver {
        if let observer = _sj_switchingInfoObserver { return observer }
        let observer = definitionSwitchingInfo.getObserver()
        observer.statusDidChangeExeBlock = { [weak self] info in
            guard let self = self else { return }
            if self.disabledDefinitionSwitchingPrompt { return }
            switch info.status {
            case .unknown:
                break
            case .switching:
                self.promptingPopupController.show(NSAttributedString.sj_UIKitText { make in
                    let prompt = SJVideoPlayerConfigurations.shared.localizedStrings.definitionSwitchingPrompt ?? ""
                    let name = info.switchingAsset?.definition_fullName ?? ""
                    _ = make.append("\(prompt) \(name)")
                    _ = make.textColor(UIColor.white)
                })
            case .finished:
                self.promptingPopupController.show(NSAttributedString.sj_UIKitText { make in
                    let prompt = SJVideoPlayerConfigurations.shared.localizedStrings.definitionSwitchSuccessfullyPrompt ?? ""
                    let name = info.currentPlayingAsset?.definition_fullName ?? ""
                    _ = make.append("\(prompt) \(name)")
                    _ = make.textColor(UIColor.white)
                })
            case .failed:
                self.promptingPopupController.show(NSAttributedString.sj_UIKitText { make in
                    _ = make.append(SJVideoPlayerConfigurations.shared.localizedStrings.definitionSwitchFailedPrompt ?? "")
                    _ = make.textColor(UIColor.white)
                })
            @unknown default:
                break
            }
            self._updateContentForDefinitionItemIfNeeded()
        }
        _sj_switchingInfoObserver = observer
        return observer
    }

    // MARK: 控制层 delegate 回调

    ///
    /// 点击了控制层右上角的更多按钮(三个点)
    ///
    @objc private func _moreItemWasTapped(_ moreItem: SJEdgeControlButtonItem) {
        switcher.switchControlLayer(forIdentifier: SJControlLayer_More)
    }

    ///
    /// 点击了剪辑按钮
    ///
    @objc private func _clipsItemWasTapped(_ clipsItem: SJEdgeControlButtonItem) {
        defaultClipsControlLayer.config = defaultEdgeControlLayer.clipsConfig
        switcher.switchControlLayer(forIdentifier: SJControlLayer_Clips)
    }

    ///
    /// 点击了切换清晰度按钮
    ///
    @objc private func _definitionItemWasTapped(_ definitionItem: SJEdgeControlButtonItem) {
        defaultVideoDefinitionSwitchingControlLayer.assets = definitionURLAssets
        switcher.switchControlLayer(forIdentifier: SJControlLayer_SwitchVideoDefinition)
    }

    ///
    /// 点击了返回按钮
    ///
    private func _backButtonWasTapped() {
        if isFullscreen && !_whetherToSupportOnlyOneOrientation() {
            rotate()
        }
        else if fitOnScreen {
            fitOnScreen = false
        }
        else {
            let vc = view.lookupResponder(for: UIViewController.self) as? UIViewController
            vc?.view.endEditing(true)
            if let nav = vc?.navigationController, nav.viewControllers.count > 1 {
                nav.popViewController(animated: true)
            }
            else {
                if vc?.presentingViewController != nil {
                    vc?.dismiss(animated: true, completion: nil)
                }
                else {
                    vc?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    // MARK: -

    ///
    /// 选择了一个清晰度
    ///
    @objc(controlLayer:didSelectAsset:)
    public func controlLayer(_ controlLayer: SJVideoDefinitionSwitchingControlLayer, didSelectAsset asset: SJVideoPlayerURLAsset) {
        var selected = urlAsset
        let info = definitionSwitchingInfo
        if info.switchingAsset != nil && info.status != .failed {
            selected = info.switchingAsset
        }

        // 原 ObjC 为指针比较(asset != selected), 这里保留对象身份比较语义。
        if asset !== selected {
            _ = sj_switchingInfoObserver
            switchVideoDefinition(asset)
        }
        _ = switcher.switchToPreviousControlLayer()
    }

    ///
    /// 点击了控制层空白区域
    ///
    @objc(tappedBlankAreaOnTheControlLayer:)
    public func tappedBlankAreaOnTheControlLayer(_ controlLayer: any SJControlLayer) {
        _ = switcher.switchToPreviousControlLayer()
    }

    ///
    /// 点击了控制层上的返回按钮
    ///
    @objc(backItemWasTappedForControlLayer:)
    public func backItemWasTapped(forControlLayer controlLayer: any SJControlLayer) {
        _backButtonWasTapped()
    }

    ///
    /// 点击了控制层上的刷新按钮
    ///
    @objc(reloadItemWasTappedForControlLayer:)
    public func reloadItemWasTapped(forControlLayer controlLayer: any SJControlLayer) {
        refresh()
        switcher.switchControlLayer(forIdentifier: SJControlLayer_Edge)
    }

    // MARK: 初始化各 observer

    private func _observeNotifies() {
        NotificationCenter.default.addObserver(self, selector: #selector(_switchControlLayerIfNeeded), name: SJVideoPlayerPlaybackTimeControlStatusDidChangeNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(_resumeOrStopTimeoutTimer), name: SJVideoPlayerPlaybackTimeControlStatusDidChangeNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(_switchControlLayerIfNeeded), name: SJVideoPlayerAssetStatusDidChangeNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(_switchControlLayerIfNeeded), name: SJVideoPlayerPlaybackDidFinishNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(_configurationsDidUpdate), name: SJVideoPlayerConfigurationsDidUpdateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(_showsMoreItemWithNote(_:)), name: SJEdgeControlLayerShowsMoreItemNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(_isEnabledClipsWithNote(_:)), name: SJEdgeControlLayerIsEnabledClipsNotification, object: nil)
    }

    private func _initializeSwitcher() {
        let switcher = SJControlLayerSwitcher(player: self)
        switcher.resolveControlLayer = { [weak self] identifier -> (any SJControlLayer)? in
            guard let self = self else { return nil }
            if identifier == SJControlLayer_Edge {
                return self.defaultEdgeControlLayer
            }
            else if identifier == SJControlLayer_NotReachableAndPlaybackStalled {
                return self.defaultNotReachableControlLayer
            }
            else if identifier == SJControlLayer_Clips {
                return self.defaultClipsControlLayer
            }
            else if identifier == SJControlLayer_More {
                return self.defaultMoreSettingControlLayer
            }
            else if identifier == SJControlLayer_LoadFailed {
                return self.defaultLoadFailedControlLayer
            }
            else if identifier == SJControlLayer_FloatSmallView {
                return self.defaultSmallViewControlLayer
            }
            else if identifier == SJControlLayer_SwitchVideoDefinition {
                return self.defaultVideoDefinitionSwitchingControlLayer
            }
            return nil
        }
        self.switcher = switcher
    }

    private func _initializeSwitcherObserver() {
        let observer = switcher.getObserver()
        observer.playerWillBeginSwitchControlLayer = { [weak self] switcher, controlLayer in
            guard let self = self else { return }
            if let edge = controlLayer as? SJEdgeControlLayer {
                edge.hiddenBackButtonWhenOrientationIsPortrait = self.defaultEdgeControlLayer.hiddenBackButtonWhenOrientationIsPortrait
            }
        }
        sj_switcherObserver = observer
    }

    private func _initializeSettingsObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(_configurationsDidUpdate), name: SJVideoPlayerConfigurationsDidUpdateNotification, object: nil)
    }

    private func _initializeSmallViewFloatingControllerObserverIfNeeded(_ smallViewFloatingController: (any SJSmallViewFloatingController_Protocol)?) {
        if sj_smallViewFloatingControllerObserver?.controller !== smallViewFloatingController {
            sj_smallViewFloatingControllerObserver = smallViewFloatingController?.getObserver()
            sj_smallViewFloatingControllerObserver?.onAppearChanged = { [weak self] controller in
                guard let self = self else { return }
                if controller.isAppeared {
                    if self.switcher.currentIdentifier != SJControlLayer_FloatSmallView {
                        self.controlLayerDataSource?.controlView().removeFromSuperview()
                        self.switcher.switchControlLayer(forIdentifier: SJControlLayer_FloatSmallView)
                    }
                }
                else {
                    if self.switcher.currentIdentifier == SJControlLayer_FloatSmallView {
                        self.controlLayerDataSource?.controlView().removeFromSuperview()
                        self.switcher.switchControlLayer(forIdentifier: SJControlLayer_Edge)
                    }
                }
            }
        }
    }

    @objc private func _configurationsDidUpdate() {
        if presentView.placeholderImageView.image == nil {
            presentView.placeholderImageView.image = SJVideoPlayerConfigurations.shared.resources.placeholder
        }

        if let moreItem = moreItem {
            moreItem.image = SJVideoPlayerConfigurations.shared.resources.moreImage
        }

        if let clipsItem = clipsItem {
            clipsItem.image = SJVideoPlayerConfigurations.shared.resources.clipsImage
        }
    }

    // 播放器当前是否只支持一个方向
    private func _whetherToSupportOnlyOneOrientation() -> Bool {
        guard let supported = rotationManager?.autorotationSupportedOrientations else { return false }
        if supported == SJOrientationMask.portrait.rawValue { return true }
        if supported == SJOrientationMask.landscapeLeft.rawValue { return true }
        if supported == SJOrientationMask.landscapeRight.rawValue { return true }
        return false
    }

    @objc private func _resumeOrStopTimeoutTimer() {
        if isBuffering || isEvaluating {
            if SJReachability.shared.networkStatus == .notReachable && sj_timeoutTimer == nil {
                let timer = Timer.sj_timer(withTimeInterval: 3, repeats: true) { [weak self] timer in
                    timer.invalidate()
                    MainActor.assumeIsolated {
                        guard let self = self else { return }
                        #if DEBUG
                        print("\(#line) \t \(#function) \t 网络超时, 切换到无网控制层!")
                        #endif
                        self.sj_isTimeout = true
                        self._switchControlLayerIfNeeded()
                    }
                }
                sj_timeoutTimer = timer
                timer.sj_fire()
                RunLoop.main.add(timer, forMode: .common)
            }
        }
        else if let timer = sj_timeoutTimer {
            timer.invalidate()
            sj_timeoutTimer = nil
            sj_isTimeout = false
        }
    }

    @objc private func _switchControlLayerIfNeeded() {
        // 资源出错时
        // - 发生错误时, 切换到加载失败控制层
        if assetStatus == .failed {
            switcher.switchControlLayer(forIdentifier: SJControlLayer_LoadFailed)
        }
        // 当处于缓冲状态时
        // - 当前如果没有网络, 则切换到无网控制层
        else if sj_isTimeout {
            switcher.switchControlLayer(forIdentifier: SJControlLayer_NotReachableAndPlaybackStalled)
        }
        else {
            if switcher.currentIdentifier == SJControlLayer_LoadFailed ||
               switcher.currentIdentifier == SJControlLayer_NotReachableAndPlaybackStalled {
                switcher.switchControlLayer(forIdentifier: SJControlLayer_Edge)
            }
        }
    }

    private func _initializeAppearManagerObserver() {
        let observer = controlLayerAppearManager.getObserver()
        observer.onAppearChanged = { [weak self] mgr in
            guard let self = self else { return }
            // refresh edge button items
            if self.switcher.currentIdentifier == SJControlLayer_Edge {
                self._updateAppearStateForMoteItemIfNeeded()
                self._updateAppearStateForClipsItemIfNeeded()
                self._updateContentForDefinitionItemIfNeeded()
            }
        }
        sj_appearManagerObserver = observer
    }

    private func _initializeReachabilityObserver() {
        let observer = reachability.getObserver()
        observer.networkStatusDidChangeExeBlock = { [weak self] r in
            guard let self = self else { return }
            if r.networkStatus == .notReachable {
                self._resumeOrStopTimeoutTimer()
            }
            else if self.switcher.currentIdentifier == SJControlLayer_NotReachableAndPlaybackStalled {
                #if DEBUG
                print("\(#line) \t \(#function) \t 网络恢复, 将刷新资源, 使播放器恢复播放!")
                #endif
                self.refresh()
            }
        }
        sj_reachabilityObserver = observer
    }

    private func _updateContentForDefinitionItemIfNeeded() {
        if let assets = definitionURLAssets, assets.count != 0 {
            // definition item
            definitionItem?.title = NSAttributedString.sj_UIKitText { [self] make in
                var asset = urlAsset
                if definitionSwitchingInfo.switchingAsset != nil &&
                   definitionSwitchingInfo.status != .failed {
                    asset = definitionSwitchingInfo.switchingAsset
                }
                _ = make.append(asset?.definition_lastName ?? "")
                _ = make.textColor(UIColor.white)
            }
            defaultEdgeControlLayer.bottomAdapter.reload()
        }
    }

    private func _updateAppearStateForMoteItemIfNeeded() {
        if let moreItem = moreItem {
            var isHidden = false
            // 如果已经显示, 则小屏的时候隐藏;
            if !moreItem.hidden {
                isHidden = !isFullscreen
            }
            else {
                isHidden = !(isFullscreen && !(rotationManager?.rotating ?? false))
            }

            if isHidden != moreItem.hidden {
                moreItem.innerHidden = isHidden
                defaultEdgeControlLayer.topAdapter.reload()
            }
        }
    }

    @objc private func _showsMoreItemWithNote(_ note: Notification) {
        if defaultEdgeControlLayer === (note.object as? SJEdgeControlLayer) {
            if defaultEdgeControlLayer.showsMoreItem {
                if moreItem == nil {
                    let item = SJEdgeControlButtonItem.placeholder(type: ._49x49, tag: SJEdgeControlLayerTopItem_More)
                    item.image = SJVideoPlayerConfigurations.shared.resources.moreImage
                    item.addAction(SJEdgeControlButtonItemAction.action(target: self, action: #selector(_moreItemWasTapped(_:))))
                    moreItem = item
                    _defaultEdgeControlLayer?.topAdapter.addItem(item)
                }
                _updateAppearStateForMoteItemIfNeeded()
            }
            else {
                _defaultMoreSettingControlLayer = nil
                moreItem = nil
                _defaultEdgeControlLayer?.topAdapter.removeItem(forTag: SJEdgeControlLayerTopItem_More)
                _defaultEdgeControlLayer?.topAdapter.reload()
                switcher.deleteControlLayer(forIdentifier: SJControlLayer_More)
            }
        }
    }

    private func _updateAppearStateForClipsItemIfNeeded() {
        if let clipsItem = clipsItem {
            // clips item
            // M3u8 暂时无法剪辑
            // 小屏或者 M3U8 的时候 自动隐藏
            let isUnsupportedFormat = urlAsset?.isM3u8 ?? false
            var isPictureInPictureEnabled = false
            if #available(iOS 14.0, *) {
                isPictureInPictureEnabled = playbackController.pictureInPictureStatus != .unknown
            }
            let isHidden = (urlAsset == nil) || !isFullscreen || isUnsupportedFormat || isPictureInPictureEnabled
            if isHidden != clipsItem.hidden {
                clipsItem.innerHidden = isHidden
                _defaultEdgeControlLayer?.rightAdapter.reload()
            }
        }
    }

    @objc private func _isEnabledClipsWithNote(_ note: Notification) {
        if defaultEdgeControlLayer === (note.object as? SJEdgeControlLayer) {
            if defaultEdgeControlLayer.enabledClips {
                if clipsItem == nil {
                    let item = SJEdgeControlButtonItem.placeholder(type: ._49x49, tag: SJEdgeControlLayerRightItem_Clips)
                    item.image = SJVideoPlayerConfigurations.shared.resources.clipsImage
                    item.addAction(SJEdgeControlButtonItemAction.action(target: self, action: #selector(_clipsItemWasTapped(_:))))
                    clipsItem = item
                    _defaultEdgeControlLayer?.rightAdapter.addItem(item)
                }
                _updateAppearStateForClipsItemIfNeeded()
            }
            else {
                _defaultClipsControlLayer = nil
                clipsItem = nil
                // 注: 保留原 ObjC 逻辑(对 nil 后的 _defaultClipsControlLayer 调用, 等价于空操作)。
                _defaultClipsControlLayer?.rightAdapter.removeItem(forTag: SJEdgeControlLayerRightItem_Clips)
                _defaultClipsControlLayer?.rightAdapter.reload()
                switcher.deleteControlLayer(forIdentifier: SJControlLayer_Clips)
            }
        }
    }
}

// MARK: - SJVideoPlayer (CommonSettings)

@MainActor
extension SJVideoPlayer {
    ///
    /// Note: The `block` runs on the sub thread.
    ///
    /// ```
    ///    SJVideoPlayer.updateResources { resources in
    ///        resources.placeholder = UIImage(named: "placeholder")
    ///        resources.progressThumbSize = 8
    ///        resources.progressTrackColor = UIColor(white: 0.8, alpha: 1)
    ///        resources.progressBufferColor = UIColor.white
    ///    }
    /// ```
    public static var updateResources: (@escaping @Sendable (any SJVideoPlayerControlLayerResources_Protocol) -> Void) -> Void {
        return { block in
            SJVideoPlayerConfigurations.update { configs in
                block(configs.resources)
            }
        }
    }

    public static var updateLocalizedStrings: (@escaping @Sendable (any SJVideoPlayerLocalizedStrings_Protocol) -> Void) -> Void {
        return { block in
            SJVideoPlayerConfigurations.update { configs in
                block(configs.localizedStrings)
            }
        }
    }

    public static var setLocalizedStrings: (Bundle) -> Void {
        return { bundle in
            SJVideoPlayerConfigurations.update { configs in
                configs.localizedStrings.setFromBundle(bundle)
            }
        }
    }

    ///
    /// Note: The `block` runs on the sub thread.
    ///
    /// ```
    ///     SJVideoPlayer.update { configs in
    ///         // 注意, 该 block 将在子线程执行
    ///         configs.resources.backImage = UIImage(named: "icon_back")
    ///         configs.resources.placeholder = UIImage(named: "placeholder")
    ///         configs.resources.progressTrackColor = UIColor(white: 0.4, alpha: 1)
    ///     }
    /// ```
    public static var update: (@escaping @Sendable (SJVideoPlayerConfigurations) -> Void) -> Void {
        return { block in
            SJVideoPlayerConfigurations.update(block)
        }
    }
}

// MARK: - SJVideoPlayer (RotationOrFitOnScreen)

@MainActor
extension SJVideoPlayer {
    ///
    /// 当视频 `宽 > 高` 时, 将执行 Rotation(旋转至横屏全屏) 相关方法.
    /// 当视频 `宽 < 高` 时, 将执行 FitOnScreen(竖屏全屏) 相关方法.
    ///
    ///     - Rotation: 播放器视图将会在横屏(全屏)与竖屏(小屏)之间切换
    ///     - FitOnScreen: 播放器视图将会在竖屏全屏与竖屏小屏之间切换
    ///
    @objc public var automaticallyPerformRotationOrFitOnScreen: Bool {
        get { defaultEdgeControlLayer.automaticallyPerformRotationOrFitOnScreen }
        set { defaultEdgeControlLayer.automaticallyPerformRotationOrFitOnScreen = newValue }
    }

    ///
    /// 处于小屏时, 当点击全屏按钮后, 是否先竖屏撑满全屏.
    ///
    @objc public var needsFitOnScreenFirst: Bool {
        get { defaultEdgeControlLayer.needsFitOnScreenFirst }
        set { defaultEdgeControlLayer.needsFitOnScreenFirst = newValue }
    }
}

// MARK: - SJVideoPlayer (SJExtendedControlLayerSwitcher)

@MainActor
extension SJVideoPlayer {
    ///
    /// 切换控制层
    ///
    @objc(switchControlLayerForIdentifier:)
    public func switchControlLayer(forIdentifier identifier: SJControlLayerIdentifier) {
        switcher.switchControlLayer(forIdentifier: identifier)
    }
}
