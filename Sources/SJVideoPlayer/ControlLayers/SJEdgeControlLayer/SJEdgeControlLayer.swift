//
//  SJEdgeControlLayer.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2018/10/24.
//  Copyright © 2018 畅三江. All rights reserved.
//
//  ObjC 源文件 SJEdgeControlLayer.h / SJEdgeControlLayer.m 合并迁移而来。
//  边缘控制层: 全库最核心的控制层, 装配五方位(顶/左/底/右/中) item,
//  实现 SJBaseVideoPlayer 的全部数据源 / 代理回调。
//

import UIKit
import SnapKit
import SJBaseVideoPlayer
import SJUIKit

// MARK: - 边缘控制层

///
/// 边缘控制层
///
/// 对应原 ObjC 类 `SJEdgeControlLayer`, 基类为 `SJEdgeControlLayerAdapters`, 遵循 `SJControlLayer`。
///
@objc(SJEdgeControlLayer)
@MainActor
open class SJEdgeControlLayer: SJEdgeControlLayerAdapters, SJControlLayer, SJProgressSliderDelegate_Protocol {

    // MARK: 对外属性

    ///
    /// loading 视图
    ///
    ///     当需要自定义时, 可以实现指定的协议赋值给该控制层
    ///
    private var _loadingView: (UIView & SJLoadingView_Protocol)?
    @objc public var loadingView: (UIView & SJLoadingView_Protocol)! {
        get {
            if _loadingView == nil {
                self.loadingView = SJLoadingView(frame: .zero)
            }
            return _loadingView
        }
        set {
            if newValue !== _loadingView {
                _loadingView?.removeFromSuperview()
                _loadingView = newValue
                if let loadingView = newValue {
                    self.controlView().addSubview(loadingView)
                    loadingView.snp.makeConstraints { make in
                        make.center.equalToSuperview().offset(0)
                    }
                }
            }
        }
    }

    ///
    /// 拖拽进度视图
    ///
    ///     当需要自定义时, 可以实现指定的协议赋值给该控制层
    ///
    private var _draggingProgressPopupView: (UIView & SJDraggingProgressPopupView_Protocol)?
    @objc public var draggingProgressPopupView: (UIView & SJDraggingProgressPopupView_Protocol)! {
        get {
            if _draggingProgressPopupView == nil {
                self.draggingProgressPopupView = SJDraggingProgressPopupView(frame: .zero)
            }
            return _draggingProgressPopupView
        }
        set {
            _draggingProgressPopupView = newValue
            _updateForDraggingProgressPopupView()
        }
    }

    ///
    /// 拖拽进度观察者
    ///
    ///     拖拽开始, 移动, 完成的回调
    ///
    private var _draggingObserver: (any SJDraggingObservation_Protocol)?
    @objc public var draggingObserver: any SJDraggingObservation_Protocol {
        if _draggingObserver == nil {
            _draggingObserver = SJDraggingObservation()
        }
        return _draggingObserver!
    }

    ///
    /// 标题视图
    ///
    ///     当需要自定义时, 可以实现指定的协议赋值给该控制层
    ///
    private var _titleView: (UIView & SJScrollingTextMarqueeView_Protocol)?
    @objc public var titleView: (UIView & SJScrollingTextMarqueeView_Protocol)! {
        get {
            if _titleView == nil {
                self.titleView = SJScrollingTextMarqueeView(frame: .zero)
            }
            return _titleView
        }
        set {
            _titleView = newValue
            _reloadTopAdapterIfNeeded()
        }
    }

    ///
    /// 长按手势触发加速播放时弹出的视图
    ///
    private var _speedupPlaybackPopupView: (UIView & SJSpeedupPlaybackPopupView_Protocol)?
    @objc public var speedupPlaybackPopupView: (UIView & SJSpeedupPlaybackPopupView_Protocol)! {
        get {
            if _speedupPlaybackPopupView == nil {
                _speedupPlaybackPopupView = SJSpeedupPlaybackPopupView(frame: .zero)
            }
            return _speedupPlaybackPopupView
        }
        set {
            if _speedupPlaybackPopupView !== newValue {
                _speedupPlaybackPopupView?.removeFromSuperview()
                _speedupPlaybackPopupView = newValue
            }
        }
    }

    ///
    /// 当设备支持画中画时, 自动显示画中画按钮. default value is Yes
    ///
    @available(iOS 14.0, *)
    @objc public var automaticallyShowsPictureInPictureItem: Bool {
        get { _automaticallyShowsPictureInPictureItem }
        set {
            if newValue != _automaticallyShowsPictureInPictureItem {
                _automaticallyShowsPictureInPictureItem = newValue
                _reloadTopAdapterIfNeeded()
            }
        }
    }
    // 因 stored property 不能标 @available, 用普通存储 + 计算属性桥接。
    private var _automaticallyShowsPictureInPictureItem: Bool = false

    ///
    /// 是否竖屏时隐藏标题
    ///
    @objc(isHiddenTitleItemWhenOrientationIsPortrait)
    public var hiddenTitleItemWhenOrientationIsPortrait: Bool = false

    ///
    /// 是否竖屏时隐藏返回按钮
    ///
    @objc(isHiddenBackButtonWhenOrientationIsPortrait)
    public var hiddenBackButtonWhenOrientationIsPortrait: Bool = false {
        didSet {
            if oldValue != hiddenBackButtonWhenOrientationIsPortrait {
                _updateAppearStateForFixedBackButtonIfNeeded()
                _reloadTopAdapterIfNeeded()
            }
        }
    }

    ///
    /// 是否将返回按钮固定
    ///
    @objc public var fixesBackItem: Bool = false {
        didSet {
            if oldValue == fixesBackItem { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.fixesBackItem {
                    self.controlView().addSubview(self.fixedBackButton)
                    self.fixedBackButton.snp.makeConstraints { make in
                        make.top.left.bottom.equalTo(self.topAdapter.view)
                        make.width.equalTo(self.topAdapter.view.snp.height)
                    }
                    self._updateAppearStateForFixedBackButtonIfNeeded()
                    self._reloadTopAdapterIfNeeded()
                } else {
                    if self._fixedBackButton != nil {
                        self._fixedBackButton?.removeFromSuperview()
                        self._fixedBackButton = nil
                        // back item
                        self._reloadTopAdapterIfNeeded()
                    }
                }
            }
        }
    }

    ///
    /// 是否禁止网络状态变化提示
    ///
    @objc(isDisabledPromptingWhenNetworkStatusChanges)
    public var disabledPromptingWhenNetworkStatusChanges: Bool = false

    ///
    /// 是否隐藏底部进度条
    ///
    @objc(isHiddenBottomProgressIndicator)
    public var hiddenBottomProgressIndicator: Bool = false {
        didSet {
            if oldValue != hiddenBottomProgressIndicator {
                DispatchQueue.main.async { [weak self] in
                    self?._showOrRemoveBottomProgressIndicator()
                }
            }
        }
    }

    ///
    /// 底部进度条高度. default value is 1.0
    ///
    @objc public var bottomProgressIndicatorHeight: CGFloat = 1 {
        didSet {
            if oldValue != bottomProgressIndicatorHeight {
                DispatchQueue.main.async { [weak self] in
                    self?._updateLayoutForBottomProgressIndicator()
                }
            }
        }
    }

    ///
    /// 自定义状态栏, 当 shouldShowsCustomStatusBar 返回YES, 将会显示该状态栏
    ///
    private var _customStatusBar: (UIView & SJFullscreenModeStatusBar_Protocol)?
    @available(iOS 11.0, *)
    @objc public var customStatusBar: (UIView & SJFullscreenModeStatusBar_Protocol)! {
        get {
            if _customStatusBar == nil {
                self.customStatusBar = SJFullscreenModeStatusBar(frame: .zero)
            }
            return _customStatusBar
        }
        set {
            if newValue !== _customStatusBar {
                _customStatusBar?.removeFromSuperview()
                _customStatusBar = newValue
                _reloadCustomStatusBarIfNeeded()
            }
        }
    }

    ///
    /// 是否应该显示自定义状态栏
    ///
    private var _shouldShowsCustomStatusBar: ((SJEdgeControlLayer) -> Bool)?
    @available(iOS 11.0, *)
    @objc public var shouldShowsCustomStatusBar: ((SJEdgeControlLayer) -> Bool)! {
        get {
            if _shouldShowsCustomStatusBar == nil {
                let is_iPhoneXSeries = _screen.is_iPhoneXSeries
                self.shouldShowsCustomStatusBar = { controlLayer -> Bool in
                    if UIUserInterfaceIdiom.pad == UIDevice.current.userInterfaceIdiom { return false }

                    if controlLayer.videoPlayer?.fitOnScreen == true { return false }
                    if controlLayer.videoPlayer?.rotationManager?.rotating == true { return false }

                    var isFullscreen = controlLayer.videoPlayer?.isFullscreen ?? false
                    if isFullscreen == false {
                        let bounds = UIScreen.main.bounds
                        if bounds.size.width > bounds.size.height {
                            isFullscreen = controlLayer.bounds.equalTo(bounds)
                        }
                    }

                    var shouldShow = false
                    if isFullscreen {
                        ///
                        /// 13 以后, 全屏后显示自定义状态栏
                        ///
                        if #available(iOS 13.0, *) {
                            shouldShow = true
                        }
                        ///
                        /// 11 仅 iPhone X 显示自定义状态栏
                        ///
                        else {
                            shouldShow = is_iPhoneXSeries
                        }
                    }
                    return shouldShow
                }
            }
            return _shouldShowsCustomStatusBar
        }
        set {
            _shouldShowsCustomStatusBar = newValue
            _updateAppearStateForCustomStatusBar()
        }
    }

    ///
    /// 是否自动选择`Rotation(旋转)`或`FitOnScreen(充满全屏)`
    ///
    /// - Rotation(旋转): 播放器视图将会在横屏(全屏)与竖屏(小屏)之间切换
    ///
    /// - FitOnScreen(充满全屏): 播放器视图将会在竖屏全屏与竖屏小屏之间切换
    ///
    ///     当视频`宽 > 高`时, 将执行 Rotation 相关方法.
    ///     当视频`宽 < 高`时, 将执行 FitOnScreen 相关方法.
    ///
    @objc public var automaticallyPerformRotationOrFitOnScreen: Bool = true

    ///
    /// 处于小屏时, 当点击全屏按钮后, 是否先竖屏撑满全屏.
    ///
    @objc public var needsFitOnScreenFirst: Bool = false

    @objc public weak var delegate: (any SJEdgeControlLayerDelegate_Protocol)?

    // MARK: 私有 / 内部属性 (对应 ObjC class extension)

    @objc public weak var videoPlayer: SJBaseVideoPlayer?

    private var reachabilityObserver: SJReachabilityObserver?

    private var automaticallyFitOnScreen: Bool = false

    /// SJControlLayerRestartProtocol
    public private(set) var restarted: Bool = false

    // MARK: 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        bottomProgressIndicatorHeight = 1
        automaticallyPerformRotationOrFitOnScreen = true
        _setupView()
        self.autoAdjustTopSpacing = true
        self.hiddenBottomProgressIndicator = true
        if #available(iOS 14.0, *) {
            self.automaticallyShowsPictureInPictureItem = true
        }
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: -

    ///
    /// 切换器(player.switcher)重启该控制层
    ///
    @objc public func restartControlLayer() {
        restarted = true
        sj_view_makeAppear(self.controlView(), true)
        _showOrHiddenLoadingView()
        _updateAppearStateForContainerViews()
        _reloadAdaptersIfNeeded()
    }

    ///
    /// 控制层退场
    ///
    @objc public func exitControlLayer() {
        restarted = false

        sj_view_makeDisappear(self.controlView(), true) { [weak self] in
            guard let self = self else { return }
            if !self.restarted { self.controlView().removeFromSuperview() }
        }

        sj_view_makeDisappear(topContainerView, true)
        sj_view_makeDisappear(leftContainerView, true)
        sj_view_makeDisappear(bottomContainerView, true)
        sj_view_makeDisappear(rightContainerView, true)
        if let v = _draggingProgressPopupView { sj_view_makeDisappear(v, true) }
        sj_view_makeDisappear(centerContainerView, true)
    }

    // MARK: - item actions

    @objc private func _fixedBackButtonWasTapped() {
        backItem?.performActions()
    }

    @objc private func _backItemWasTapped() {
        if let delegate = self.delegate,
           delegate.responds(to: #selector(SJEdgeControlLayerDelegate_Protocol.backItemWasTapped(forControlLayer:))) {
            delegate.backItemWasTapped(forControlLayer: self)
        }
    }

    @objc private func _lockItemWasTapped() {
        if let videoPlayer = videoPlayer {
            videoPlayer.lockedScreen = !videoPlayer.lockedScreen
        }
    }

    @objc private func _playItemWasTapped() {
        guard let videoPlayer = videoPlayer else { return }
        videoPlayer.isPaused ? videoPlayer.play() : videoPlayer.pauseForUser()
    }

    @objc private func _fullItemWasTapped() {
        guard let videoPlayer = videoPlayer else { return }
        if videoPlayer.onlyFitOnScreen || automaticallyFitOnScreen {
            videoPlayer.fitOnScreen = !videoPlayer.fitOnScreen
            return
        }

        if needsFitOnScreenFirst && !videoPlayer.fitOnScreen {
            videoPlayer.fitOnScreen = true
            return
        }

        videoPlayer.rotate()
    }

    @objc private func _replayItemWasTapped() {
        videoPlayer?.replay()
    }

    @available(iOS 14.0, *)
    @objc public func pictureInPictureItemWasTapped() {
        guard let videoPlayer = videoPlayer else { return }
        switch videoPlayer.playbackController.pictureInPictureStatus {
        case .starting, .running:
            videoPlayer.playbackController.stopPictureInPicture()
        case .unknown, .stopping, .stopped:
            videoPlayer.playbackController.startPictureInPicture()
        @unknown default:
            videoPlayer.playbackController.startPictureInPicture()
        }
    }

    // MARK: - slider delegate methods

    public func sliderWillBeginDragging(_ slider: SJProgressSlider) {
        guard let videoPlayer = videoPlayer else { return }
        if videoPlayer.assetStatus != .readyToPlay {
            slider.cancelDragging()
            return
        } else if let canSeekToTime = videoPlayer.canSeekToTime, !canSeekToTime(videoPlayer) {
            slider.cancelDragging()
            return
        }

        _willBeginDragging()
    }

    public func slider(_ slider: SJProgressSlider, valueDidChange value: CGFloat) {
        if slider.isDragging { _didMove(value) }
    }

    public func sliderDidEndDragging(_ slider: SJProgressSlider) {
        _endDragging()
    }

    // MARK: - player delegate methods

    public func controlView() -> UIView {
        return self
    }

    public func installedControlView(toVideoPlayer videoPlayer: SJBaseVideoPlayer) {
        self.videoPlayer = videoPlayer
        sj_view_makeDisappear(topContainerView, false)
        sj_view_makeDisappear(leftContainerView, false)
        sj_view_makeDisappear(bottomContainerView, false)
        sj_view_makeDisappear(rightContainerView, false)
        sj_view_makeDisappear(centerContainerView, false)

        _reloadSizeForBottomTimeLabel()
        _updateContentForBottomCurrentTimeItemIfNeeded()
        _updateContentForBottomDurationItemIfNeeded()

        reachabilityObserver = videoPlayer.reachability.getObserver()
        reachabilityObserver?.networkSpeedDidChangeExeBlock = { [weak self] _ in
            guard let self = self else { return }
            self._updateNetworkSpeedStrForLoadingView()
        }
    }

    ///
    /// 当播放器尝试自动隐藏控制层之前 将会调用这个方法
    ///
    public func controlLayerOfVideoPlayerCanAutomaticallyDisappear(_ videoPlayer: SJBaseVideoPlayer) -> Bool {
        if let progressItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_Progress), !progressItem.hidden {
            if let slider = progressItem.customView as? SJProgressSlider {
                return !slider.isDragging
            }
        }
        return true
    }

    public func controlLayerNeedAppear(_ videoPlayer: SJBaseVideoPlayer) {
        if videoPlayer.lockedScreen { return }

        _updateAppearStateForFixedBackButtonIfNeeded()
        _updateAppearStateForContainerViews()
        _reloadAdaptersIfNeeded()
        _updateContentForBottomCurrentTimeItemIfNeeded()
        _updateContentForBottomProgressSliderItemIfNeeded()
        _updateAppearStateForBottomProgressIndicatorIfNeeded()
        if #available(iOS 11.0, *) {
            _reloadCustomStatusBarIfNeeded()
        }
    }

    public func controlLayerNeedDisappear(_ videoPlayer: SJBaseVideoPlayer) {
        if videoPlayer.lockedScreen { return }

        _updateAppearStateForFixedBackButtonIfNeeded()
        _updateAppearStateForContainerViews()
        _updateAppearStateForBottomProgressIndicatorIfNeeded()
    }

    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, prepareToPlay asset: SJVideoPlayerURLAsset?) {
        automaticallyFitOnScreen = false
        _reloadSizeForBottomTimeLabel()
        _updateContentForBottomDurationItemIfNeeded()
        _updateContentForBottomCurrentTimeItemIfNeeded()
        _updateContentForBottomProgressSliderItemIfNeeded()
        _updateContentForBottomProgressIndicatorIfNeeded()
        _updateAppearStateForFixedBackButtonIfNeeded()
        _updateAppearStateForBottomProgressIndicatorIfNeeded()
        _reloadAdaptersIfNeeded()
        _showOrHiddenLoadingView()
    }

    public func videoPlayerPlaybackStatusDidChange(_ videoPlayer: SJBaseVideoPlayer) {
        _reloadAdaptersIfNeeded()
        _showOrHiddenLoadingView()
        _updateContentForBottomCurrentTimeItemIfNeeded()
        _updateContentForBottomDurationItemIfNeeded()
        _updateContentForBottomProgressIndicatorIfNeeded()
        _updateContentForBottomProgressSliderItemIfNeeded()
    }

    @available(iOS 14.0, *)
    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, pictureInPictureStatusDidChange status: SJPictureInPictureStatus) {
        _updateContentForPictureInPictureItem()
        topAdapter.reload()
    }

    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, currentTimeDidChange currentTime: TimeInterval) {
        _updateContentForBottomCurrentTimeItemIfNeeded()
        _updateContentForBottomProgressIndicatorIfNeeded()
        _updateContentForBottomProgressSliderItemIfNeeded()
        _updateCurrentTimeForDraggingProgressPopupViewIfNeeded()
    }

    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, durationDidChange duration: TimeInterval) {
        _reloadSizeForBottomTimeLabel()
        _updateContentForBottomDurationItemIfNeeded()
        _updateContentForBottomProgressIndicatorIfNeeded()
        _updateContentForBottomProgressSliderItemIfNeeded()
    }

    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, playableDurationDidChange duration: TimeInterval) {
        _updateContentForBottomProgressSliderItemIfNeeded()
    }

    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, playbackTypeDidChange playbackType: SJPlaybackType) {
        let currentTimeItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_CurrentTime)
        let separatorItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_Separator)
        let durationTimeItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_DurationTime)
        let progressItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_Progress)
        let liveItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_LIVEText)
        switch playbackType {
        case .LIVE:
            currentTimeItem?.innerHidden = true
            separatorItem?.innerHidden = true
            durationTimeItem?.innerHidden = true
            progressItem?.innerHidden = true
            liveItem?.innerHidden = false
        case .unknown, .VOD, .FILE:
            currentTimeItem?.innerHidden = false
            separatorItem?.innerHidden = false
            durationTimeItem?.innerHidden = false
            progressItem?.innerHidden = false
            liveItem?.innerHidden = true
        @unknown default:
            currentTimeItem?.innerHidden = false
            separatorItem?.innerHidden = false
            durationTimeItem?.innerHidden = false
            progressItem?.innerHidden = false
            liveItem?.innerHidden = true
        }
        bottomAdapter.reload()
        _showOrRemoveBottomProgressIndicator()
    }

    @objc(canTriggerRotationOfVideoPlayer:)
    public func canTriggerRotation(ofVideoPlayer videoPlayer: SJBaseVideoPlayer) -> Bool {
        if needsFitOnScreenFirst || automaticallyFitOnScreen {
            return videoPlayer.fitOnScreen
        }

        if automaticallyFitOnScreen {
            if videoPlayer.fitOnScreen { return videoPlayer.allowsRotationInFitOnScreen }
            return false
        }

        return true
    }

    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, willRotateView isFull: Bool) {
        _updateAppearStateForBottomProgressIndicatorIfNeeded()
        _updateAppearStateForFixedBackButtonIfNeeded()
        _updateAppearStateForContainerViews()
        _reloadAdaptersIfNeeded()
    }

    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, didEndRotation isFull: Bool) {
        _updateAppearStateForBottomProgressIndicatorIfNeeded()
        _updateAppearStateForFixedBackButtonIfNeeded()
        _updateAppearStateForContainerViews()
        _reloadAdaptersIfNeeded()
    }

    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, willFitOnScreen isFitOnScreen: Bool) {
        _updateAppearStateForFixedBackButtonIfNeeded()
        _updateAppearStateForContainerViews()
        _reloadAdaptersIfNeeded()
    }

    /// 是否可以触发播放器的手势
    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, gestureRecognizerShouldTrigger type: SJPlayerGestureType, location: CGPoint) -> Bool {
        var adapter: SJEdgeControlButtonItemAdapter? = nil
        let locationInTheView: (UIView) -> Bool = { container in
            return container.frame.contains(location) && !sj_view_isDisappeared(container)
        }

        if locationInTheView(topContainerView) {
            adapter = topAdapter
        } else if locationInTheView(bottomContainerView) {
            adapter = bottomAdapter
        } else if locationInTheView(leftContainerView) {
            adapter = leftAdapter
        } else if locationInTheView(rightContainerView) {
            adapter = rightAdapter
        } else if locationInTheView(centerContainerView) {
            adapter = centerAdapter
        }
        guard let adapter = adapter else { return true }

        let point = self.controlView().convert(location, to: adapter.view)
        if !adapter.view.frame.contains(point) { return true }

        if let item = adapter.item(at: point) {
            return (item.actions?.count ?? 0) == 0
        }
        return true
    }

    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, panGestureTriggeredInTheHorizontalDirection state: SJPanGestureRecognizerState, progressTime: TimeInterval) {
        switch state {
        case .began:
            _willBeginDragging()
        case .changed:
            _didMove(progressTime)
        case .ended:
            _endDragging()
        @unknown default:
            break
        }
    }

    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, longPressGestureStateDidChange state: SJLongPressGestureRecognizerState) {
        if speedupPlaybackPopupView.responds(to: #selector(SJSpeedupPlaybackPopupView_Protocol.layoutInRect(_:gestureState:playbackRate:))) {
            if state == .began {
                if speedupPlaybackPopupView.superview !== self {
                    insertSubview(speedupPlaybackPopupView, at: 0)
                }
            }
            speedupPlaybackPopupView.layoutInRect?(self.frame, gestureState: state, playbackRate: videoPlayer.rateWhenLongPressGestureTriggered)
        } else {
            switch state {
            case .changed:
                break
            case .began:
                if speedupPlaybackPopupView.superview !== self {
                    insertSubview(speedupPlaybackPopupView, at: 0)
                    speedupPlaybackPopupView.snp.makeConstraints { make in
                        make.center.equalTo(self.topAdapter)
                    }
                }
                speedupPlaybackPopupView.rate = videoPlayer.rateWhenLongPressGestureTriggered
                speedupPlaybackPopupView.show()
            case .ended:
                speedupPlaybackPopupView.hidden()
            @unknown default:
                break
            }
        }
    }

    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, presentationSizeDidChange size: CGSize) {
        if automaticallyPerformRotationOrFitOnScreen && !videoPlayer.isFullscreen && !videoPlayer.fitOnScreen {
            automaticallyFitOnScreen = size.width < size.height
        }
    }

    /// 这是一个只有在播放器锁屏状态下, 才会回调的方法
    /// 当播放器锁屏后, 用户每次点击都会回调这个方法
    @objc(tappedPlayerOnTheLockedState:)
    public func tappedPlayer(onTheLockedState videoPlayer: SJBaseVideoPlayer) {
        if sj_view_isDisappeared(leftContainerView) {
            sj_view_makeAppear(leftContainerView, true)
            lockStateTappedTimerControl.resume()
        } else {
            sj_view_makeDisappear(leftContainerView, true)
            lockStateTappedTimerControl.interrupt()
        }
    }

    public func lockedVideoPlayer(_ videoPlayer: SJBaseVideoPlayer) {
        _updateAppearStateForFixedBackButtonIfNeeded()
        _updateAppearStateForBottomProgressIndicatorIfNeeded()
        _updateAppearStateForContainerViews()
        _reloadAdaptersIfNeeded()
        lockStateTappedTimerControl.resume()
    }

    public func unlockedVideoPlayer(_ videoPlayer: SJBaseVideoPlayer) {
        _updateAppearStateForBottomProgressIndicatorIfNeeded()
        lockStateTappedTimerControl.interrupt()
        videoPlayer.controlLayerNeedAppear()
    }

    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, reachabilityChanged status: SJNetworkStatus) {
        if #available(iOS 11.0, *) {
            _reloadCustomStatusBarIfNeeded()
        }
        if disabledPromptingWhenNetworkStatusChanges { return }
        if self.videoPlayer?.assetURL?.isFileURL == true { return } // return when is local video.

        switch status {
        case .notReachable:
            self.videoPlayer?.textPopupController.show(NSAttributedString.sj_UIKitText { make in
                _ = make.append(SJVideoPlayerConfigurations.shared.localizedStrings.unstableNetworkPrompt ?? "")
                _ = make.textColor(UIColor.white)
            }, duration: 3)
        case .reachableViaWWAN:
            self.videoPlayer?.textPopupController.show(NSAttributedString.sj_UIKitText { make in
                _ = make.append(SJVideoPlayerConfigurations.shared.localizedStrings.cellularNetworkPrompt ?? "")
                _ = make.textColor(UIColor.white)
            }, duration: 3)
        case .reachableViaWiFi:
            break
        @unknown default:
            break
        }
    }

    // MARK: -

    @objc public func stringForSeconds(_ secs: Int) -> String {
        return videoPlayer != nil ? videoPlayer!.stringForSeconds(secs) : ""
    }

    // MARK: - setup view

    private func _setupView() {
        _addItemsToTopAdapter()
        _addItemsToLeftAdapter()
        _addItemsToBottomAdapter()
        _addItemsToRightAdapter()
        _addItemsToCenterAdapter()

        topContainerView.sjv_disappearDirection = .top
        leftContainerView.sjv_disappearDirection = .left
        bottomContainerView.sjv_disappearDirection = .bottom
        rightContainerView.sjv_disappearDirection = .right
        centerContainerView.sjv_disappearDirection = .none

        sj_view_initializes([topContainerView, leftContainerView,
                             bottomContainerView, rightContainerView])

        NotificationCenter.default.addObserver(self, selector: #selector(_resetControlLayerAppearIntervalForItemIfNeeded(_:)), name: SJEdgeControlButtonItemPerformedActionNotification, object: nil)

        //    NotificationCenter.default.addObserver(self, selector: #selector(configurationsDidUpdate(_:)), name: SJVideoPlayerConfigurationsDidUpdateNotification, object: nil)
    }

    // 固定左上角的返回按钮. 设置`fixesBackItem`后显示
    private var _fixedBackButton: UIButton?
    private var fixedBackButton: UIButton {
        if let btn = _fixedBackButton { return btn }
        let btn = UIButton(type: .custom)
        btn.setImage(SJVideoPlayerConfigurations.shared.resources.backImage, for: .normal)
        btn.addTarget(self, action: #selector(_fixedBackButtonWasTapped), for: .touchUpInside)
        _fixedBackButton = btn
        return btn
    }

    private var _bottomProgressIndicator: SJProgressSlider?
    private var bottomProgressIndicator: SJProgressSlider {
        if let v = _bottomProgressIndicator { return v }
        let v = SJProgressSlider()
        v.pan.isEnabled = false
        v.trackHeight = bottomProgressIndicatorHeight
        v.round = false
        let sources = SJVideoPlayerConfigurations.shared.resources
        let traceColor = sources.bottomIndicatorTraceColor ?? sources.progressTraceColor
        let trackColor = sources.bottomIndicatorTrackColor ?? sources.progressTrackColor
        v.traceImageView.backgroundColor = traceColor
        v.trackImageView.backgroundColor = trackColor
        v.frame = CGRect(x: 0, y: self.bounds.size.height - bottomProgressIndicatorHeight, width: self.bounds.size.width, height: bottomProgressIndicatorHeight)
        v.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        _bottomProgressIndicator = v
        return v
    }

    private var _lockStateTappedTimerControl: SJTimerControl?
    private var lockStateTappedTimerControl: SJTimerControl {
        if let c = _lockStateTappedTimerControl { return c }
        let c = SJTimerControl()
        c.exeBlock = { [weak self] control in
            guard let self = self else { return }
            sj_view_makeDisappear(self.leftContainerView, true)
            control.interrupt()
        }
        _lockStateTappedTimerControl = c
        return c
    }

    private var _pictureInPictureItem: SJEdgeControlButtonItem?
    @available(iOS 14.0, *)
    private var pictureInPictureItem: SJEdgeControlButtonItem {
        if let item = _pictureInPictureItem { return item }
        let item = SJEdgeControlButtonItem(tag: SJEdgeControlLayerTopItem_PictureInPicture)
        item.addAction(SJEdgeControlButtonItemAction(target: self, action: #selector(pictureInPictureItemWasTapped)))
        _pictureInPictureItem = item
        return item
    }

    private var _dateTimerControl: SJTimerControl?
    @available(iOS 11.0, *)
    private var dateTimerControl: SJTimerControl {
        if let c = _dateTimerControl { return c }
        let c = SJTimerControl()
        c.interval = 1
        c.exeBlock = { [weak self] control in
            guard let self = self else { return }
            if self.customStatusBar.isHidden {
                control.interrupt()
            } else {
                self._reloadCustomStatusBarIfNeeded()
            }
        }
        _dateTimerControl = c
        return c
    }

    private weak var _backItem: SJEdgeControlButtonItem?
    private var backItem: SJEdgeControlButtonItem? { _backItem }

    private func _addItemsToTopAdapter() {
        let backItem = SJEdgeControlButtonItem.placeholder(type: ._49x49, tag: SJEdgeControlLayerTopItem_Back)
        backItem.resetsAppearIntervalWhenPerformingItemAction = false
        backItem.addAction(SJEdgeControlButtonItemAction(target: self, action: #selector(_backItemWasTapped)))
        topAdapter.addItem(backItem)
        _backItem = backItem

        let titleItem = SJEdgeControlButtonItem.placeholder(type: ._49xFill, tag: SJEdgeControlLayerTopItem_Title)
        topAdapter.addItem(titleItem)

        topAdapter.reload()
    }

    private func _addItemsToLeftAdapter() {
        let lockItem = SJEdgeControlButtonItem.placeholder(type: ._49x49, tag: SJEdgeControlLayerLeftItem_Lock)
        lockItem.addAction(SJEdgeControlButtonItemAction(target: self, action: #selector(_lockItemWasTapped)))
        leftAdapter.addItem(lockItem)

        leftAdapter.reload()
    }

    private func _addItemsToBottomAdapter() {
        // 播放按钮
        let playItem = SJEdgeControlButtonItem.placeholder(type: ._49x49, tag: SJEdgeControlLayerBottomItem_Play)
        playItem.addAction(SJEdgeControlButtonItemAction(target: self, action: #selector(_playItemWasTapped)))
        bottomAdapter.addItem(playItem)

        let liveItem = SJEdgeControlButtonItem(tag: SJEdgeControlLayerBottomItem_LIVEText)
        liveItem.innerHidden = true
        bottomAdapter.addItem(liveItem)

        // 当前时间
        let currentTimeItem = SJEdgeControlButtonItem.placeholder(size: 8, tag: SJEdgeControlLayerBottomItem_CurrentTime)
        bottomAdapter.addItem(currentTimeItem)

        // 时间分隔符
        let separatorItem = SJEdgeControlButtonItem(title: NSAttributedString.sj_UIKitText { make in
            _ = make.append("/ ").font(UIFont.systemFont(ofSize: 11)).textColor(UIColor.white).alignment(.center)
        }, target: nil, action: nil, tag: SJEdgeControlLayerBottomItem_Separator)
        bottomAdapter.addItem(separatorItem)

        // 全部时长
        let durationTimeItem = SJEdgeControlButtonItem.placeholder(size: 8, tag: SJEdgeControlLayerBottomItem_DurationTime)
        bottomAdapter.addItem(durationTimeItem)

        // 播放进度条
        let slider = SJProgressSlider()
        slider.trackHeight = 3
        slider.delegate = self
        slider.tap.isEnabled = true
        slider.showsBufferProgress = true
        slider.tappedExeBlock = { [weak self] _, location in
            guard let self = self else { return }
            guard let videoPlayer = self.videoPlayer else { return }
            if let canSeekToTime = videoPlayer.canSeekToTime, canSeekToTime(videoPlayer) == false {
                return
            }

            if videoPlayer.assetStatus != .readyToPlay {
                return
            }

            videoPlayer.seek(toTime: location, completionHandler: nil)
        }
        let progressItem = SJEdgeControlButtonItem(customView: slider, tag: SJEdgeControlLayerBottomItem_Progress)
        progressItem.insets = SJEdgeInsetsMake(8, 8)
        progressItem.fill = true
        bottomAdapter.addItem(progressItem)

        // 全屏按钮
        let fullItem = SJEdgeControlButtonItem.placeholder(type: ._49x49, tag: SJEdgeControlLayerBottomItem_Full)
        fullItem.resetsAppearIntervalWhenPerformingItemAction = false
        fullItem.addAction(SJEdgeControlButtonItemAction(target: self, action: #selector(_fullItemWasTapped)))
        bottomAdapter.addItem(fullItem)

        bottomAdapter.reload()
    }

    private func _addItemsToRightAdapter() {

    }

    private func _addItemsToCenterAdapter() {
        let replayLabel = UILabel()
        replayLabel.numberOfLines = 0
        let replayItem = SJEdgeControlButtonItem.frameLayout(customView: replayLabel, tag: SJEdgeControlLayerCenterItem_Replay)
        replayItem.addAction(SJEdgeControlButtonItemAction(target: self, action: #selector(_replayItemWasTapped)))
        centerAdapter.addItem(replayItem)
        centerAdapter.reload()
    }

    // MARK: - appear state

    private func _updateAppearStateForContainerViews() {
        _updateAppearStateForTopContainerView()
        _updateAppearStateForLeftContainerView()
        _updateAppearStateForBottomContainerView()
        _updateAppearStateForRightContainerView()
        _updateAppearStateForCenterContainerView()
        if #available(iOS 11.0, *) {
            _updateAppearStateForCustomStatusBar()
        }
    }

    private func _updateAppearStateForTopContainerView() {
        if 0 == topAdapter.numberOfItems {
            sj_view_makeDisappear(topContainerView, true)
            return
        }

        /// 锁屏状态下, 使隐藏
        if videoPlayer?.lockedScreen == true {
            sj_view_makeDisappear(topContainerView, true)
            return
        }

        /// 是否显示
        if videoPlayer?.controlLayerAppeared == true {
            sj_view_makeAppear(topContainerView, true)
        } else {
            sj_view_makeDisappear(topContainerView, true)
        }
    }

    private func _updateAppearStateForLeftContainerView() {
        if 0 == leftAdapter.numberOfItems {
            sj_view_makeDisappear(leftContainerView, true)
            return
        }

        /// 锁屏状态下显示
        if videoPlayer?.lockedScreen == true {
            sj_view_makeAppear(leftContainerView, true)
            return
        }

        /// 是否显示
        if videoPlayer?.controlLayerAppeared == true {
            sj_view_makeAppear(leftContainerView, true)
        } else {
            sj_view_makeDisappear(leftContainerView, true)
        }
    }

    /// 更新显示状态
    private func _updateAppearStateForBottomContainerView() {
        if 0 == bottomAdapter.numberOfItems {
            sj_view_makeDisappear(bottomContainerView, true)
            return
        }

        /// 锁屏状态下, 使隐藏
        if videoPlayer?.lockedScreen == true {
            sj_view_makeDisappear(bottomContainerView, true)
            return
        }

        /// 是否显示
        if videoPlayer?.controlLayerAppeared == true {
            sj_view_makeAppear(bottomContainerView, true)
        } else {
            sj_view_makeDisappear(bottomContainerView, true)
        }
    }

    /// 更新显示状态
    private func _updateAppearStateForRightContainerView() {
        if 0 == rightAdapter.numberOfItems {
            sj_view_makeDisappear(rightContainerView, true)
            return
        }

        /// 锁屏状态下, 使隐藏
        if videoPlayer?.lockedScreen == true {
            sj_view_makeDisappear(rightContainerView, true)
            return
        }

        /// 是否显示
        if videoPlayer?.controlLayerAppeared == true {
            sj_view_makeAppear(rightContainerView, true)
        } else {
            sj_view_makeDisappear(rightContainerView, true)
        }
    }

    private func _updateAppearStateForCenterContainerView() {
        if 0 == centerAdapter.numberOfItems {
            sj_view_makeDisappear(centerContainerView, true)
            return
        }

        sj_view_makeAppear(centerContainerView, true)
    }

    private func _updateAppearStateForBottomProgressIndicatorIfNeeded() {
        guard let bottomProgressIndicator = _bottomProgressIndicator else { return }

        let hidden = ((videoPlayer?.controlLayerAppeared == true) && (videoPlayer?.lockedScreen != true)) || (videoPlayer?.isRotating == true)

        if hidden {
            sj_view_makeDisappear(bottomProgressIndicator, false)
        } else {
            sj_view_makeAppear(bottomProgressIndicator, false)
        }
    }

    @available(iOS 11.0, *)
    private func _updateAppearStateForCustomStatusBar() {
        let shouldShow = self.shouldShowsCustomStatusBar(self)
        if shouldShow {
            if self.customStatusBar.superview == nil {
                SJEdgeControlLayer._enableBatteryMonitoringOnce

                NotificationCenter.default.addObserver(self, selector: #selector(_reloadCustomStatusBarIfNeededAction), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(_reloadCustomStatusBarIfNeededAction), name: UIDevice.batteryStateDidChangeNotification, object: nil)

                self.customStatusBar.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
                self.topContainerView.addSubview(self.customStatusBar)
            }
            let containerW = self.topContainerView.frame.size.width
            let statusBarW = self.topAdapter.frame.size.width
            let startX = (containerW - statusBarW) * 0.5
            self.customStatusBar.frame = CGRect(x: startX, y: 0, width: self.topAdapter.bounds.size.width, height: 20)
        }

        _customStatusBar?.isHidden = !shouldShow
        if _customStatusBar?.isHidden == true {
            self.dateTimerControl.interrupt()
        } else if _customStatusBar != nil {
            self.dateTimerControl.resume()
        }
    }

    // 电量监控只需要开启一次 (对应原 dispatch_once)
    private static let _enableBatteryMonitoringOnce: Void = {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }()

    @available(iOS 14.0, *)
    private func _updateContentForPictureInPictureItem() {
        let sources = SJVideoPlayerConfigurations.shared.resources
        switch self.videoPlayer?.playbackController.pictureInPictureStatus {
        case .running:
            self.pictureInPictureItem.image = sources.pictureInPictureItemStopImage
        case .unknown, .starting, .stopping, .stopped, .none:
            self.pictureInPictureItem.image = sources.pictureInPictureItemStartImage
        case .some:
            self.pictureInPictureItem.image = sources.pictureInPictureItemStartImage
        }
    }

    // MARK: - update items

    private func _reloadAdaptersIfNeeded() {
        _reloadTopAdapterIfNeeded()
        _reloadLeftAdapterIfNeeded()
        _reloadBottomAdapterIfNeeded()
        _reloadRightAdapterIfNeeded()
        _reloadCenterAdapterIfNeeded()
    }

    private func _reloadTopAdapterIfNeeded() {
        if sj_view_isDisappeared(topContainerView) { return }
        let sources = SJVideoPlayerConfigurations.shared.resources
        let isFullscreen = videoPlayer?.isFullscreen ?? false
        let isFitOnScreen = videoPlayer?.fitOnScreen ?? false
        let isPlayOnScrollView = videoPlayer?.isPlayOnScrollView ?? false
        let isSmallscreen = !isFullscreen && !isFitOnScreen

        // back item
        do {
            if let backItem = topAdapter.item(forTag: SJEdgeControlLayerTopItem_Back) {
                if fixesBackItem {
                    if !isFullscreen && hiddenBackButtonWhenOrientationIsPortrait {
                        backItem.innerHidden = true
                    } else {
                        backItem.innerHidden = false
                    }
                } else {
                    if isFullscreen || isFitOnScreen {
                        backItem.innerHidden = false
                    } else if hiddenBackButtonWhenOrientationIsPortrait {
                        backItem.innerHidden = true
                    } else {
                        backItem.innerHidden = isPlayOnScrollView
                    }
                }

                if backItem.hidden == false {
                    backItem.alpha = 1.0
                    backItem.image = fixesBackItem ? nil : sources.backImage
                } else {
                    backItem.alpha = 0
                    backItem.image = nil
                }
            }
        }

        // title item
        do {
            if let titleItem = topAdapter.item(forTag: SJEdgeControlLayerTopItem_Title) {
                if self.hiddenTitleItemWhenOrientationIsPortrait && isSmallscreen {
                    titleItem.innerHidden = true
                } else {
                    if titleItem.customView !== self.titleView {
                        titleItem.customView = self.titleView
                    }
                    let asset = videoPlayer?.urlAsset?.original ?? videoPlayer?.urlAsset
                    let attributedTitle = asset?.attributedTitle
                    self.titleView.attributedText = attributedTitle
                    titleItem.innerHidden = ((attributedTitle?.length ?? 0) == 0)
                }

                if titleItem.hidden == false {
                    // margin
                    let atIndex = topAdapter.indexOfItem(forTag: SJEdgeControlLayerTopItem_Title)
                    let left: CGFloat = topAdapter.isHidden(withRange: NSRange(location: 0, length: atIndex)) ? 16 : 0
                    let right: CGFloat = topAdapter.isHidden(withRange: NSRange(location: atIndex, length: topAdapter.numberOfItems)) ? 16 : 0
                    titleItem.insets = SJEdgeInsetsMake(left, right)
                }
            }
        }

        // picture in picture item
        do {
            if #available(iOS 14.0, *) {
                if !self.automaticallyShowsPictureInPictureItem || ((self.videoPlayer?.isPlayOnScrollView == true) && isSmallscreen) {
                    topAdapter.removeItem(forTag: SJEdgeControlLayerTopItem_PictureInPicture)
                } else if self.videoPlayer?.playbackController.isPictureInPictureSupported() == true {
                    if !topAdapter.contains(self.pictureInPictureItem) {
                        _updateContentForPictureInPictureItem()
                        topAdapter.insertItem(self.pictureInPictureItem, frontItem: SJEdgeControlLayerTopItem_Title)
                    }
                }
            }
        }

        topAdapter.reload()
    }

    private func _reloadLeftAdapterIfNeeded() {
        if sj_view_isDisappeared(leftContainerView) { return }

        let isFullscreen = videoPlayer?.isFullscreen ?? false
        let isLockedScreen = videoPlayer?.lockedScreen ?? false
        let showsLockItem = isFullscreen && !(videoPlayer?.rotationManager?.rotating ?? false)

        if let lockItem = leftAdapter.item(forTag: SJEdgeControlLayerLeftItem_Lock) {
            lockItem.innerHidden = !showsLockItem
            if showsLockItem {
                let sources = SJVideoPlayerConfigurations.shared.resources
                lockItem.image = isLockedScreen ? sources.lockImage : sources.unlockImage
            }
        }

        leftAdapter.reload()
    }

    private func _reloadBottomAdapterIfNeeded() {
        if sj_view_isDisappeared(bottomContainerView) { return }

        let sources = SJVideoPlayerConfigurations.shared.resources
        let strings = SJVideoPlayerConfigurations.shared.localizedStrings

        // play item
        do {
            if let playItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_Play), playItem.hidden == false {
                playItem.image = (videoPlayer?.isPaused ?? true) ? sources.playImage : sources.pauseImage
            }
        }

        // progress item
        do {
            if let progressItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_Progress), progressItem.hidden == false {
                if let slider = progressItem.customView as? SJProgressSlider {
                    slider.traceImageView.backgroundColor = sources.progressTraceColor
                    slider.trackImageView.backgroundColor = sources.progressTrackColor
                    slider.bufferProgressColor = sources.progressBufferColor
                    slider.trackHeight = CGFloat(sources.progressTrackHeight)
                    slider.loadingColor = sources.loadingLineColor ?? .black

                    if let thumbImage = sources.progressThumbImage {
                        slider.thumbImageView.image = thumbImage
                    } else if sources.progressThumbSize != 0 {
                        let size = CGFloat(sources.progressThumbSize)
                        slider.setThumbCornerRadius(size * 0.5, size: CGSize(width: size, height: size), thumbBackgroundColor: sources.progressThumbColor ?? .clear)
                    }
                }
            }
        }

        // full item
        do {
            if let fullItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_Full), fullItem.hidden == false {
                let isFullscreen = videoPlayer?.isFullscreen ?? false
                let isFitOnScreen = videoPlayer?.fitOnScreen ?? false
                fullItem.image = (isFullscreen || isFitOnScreen) ? sources.smallScreenImage : sources.fullscreenImage
            }
        }

        // live text
        do {
            if let liveItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_LIVEText), liveItem.hidden == false {
                liveItem.title = NSAttributedString.sj_UIKitText { make in
                    _ = make.append(strings.liveBroadcast ?? "")
                    if let font = sources.titleLabelFont { _ = make.font(font) }
                    if let color = sources.titleLabelColor { _ = make.textColor(color) }
                    _ = make.shadow { shadow in
                        shadow.shadowOffset = CGSize(width: 0, height: 0.5)
                        shadow.shadowColor = UIColor.black
                    }
                }
            }
        }

        bottomAdapter.reload()
    }

    private func _reloadRightAdapterIfNeeded() {
        //    if sj_view_isDisappeared(rightContainerView) { return }
    }

    private func _reloadCenterAdapterIfNeeded() {
        if sj_view_isDisappeared(centerContainerView) { return }

        if let replayItem = centerAdapter.item(forTag: SJEdgeControlLayerCenterItem_Replay) {
            replayItem.innerHidden = !(videoPlayer?.isPlaybackFinished ?? false)
            if replayItem.hidden == false && replayItem.title == nil {
                let resources = SJVideoPlayerConfigurations.shared.resources
                let strings = SJVideoPlayerConfigurations.shared.localizedStrings
                if let textLabel = replayItem.customView as? UILabel {
                    textLabel.attributedText = NSAttributedString.sj_UIKitText { make in
                        _ = make.alignment(.center).lineSpacing(6)
                        if let font = resources.replayTitleFont { _ = make.font(font) }
                        if let color = resources.replayTitleColor { _ = make.textColor(color) }
                        if let replayImage = resources.replayImage {
                            _ = make.appendImage { imgMake in
                                imgMake.image = replayImage
                            }
                        }
                        if strings.replay.count != 0 {
                            if resources.replayImage != nil { _ = make.append("\n") }
                            _ = make.append(strings.replay ?? "")
                        }
                    }
                    textLabel.bounds = CGRect(origin: .zero, size: (textLabel.attributedText ?? NSAttributedString()).sj_textSize())
                }
            }
        }

        centerAdapter.reload()
    }

    private func _updateContentForBottomCurrentTimeItemIfNeeded() {
        if sj_view_isDisappeared(bottomContainerView) { return }
        guard let videoPlayer = videoPlayer else { return }
        let currentTimeStr = videoPlayer.stringForSeconds(Int(videoPlayer.currentTime))
        if let currentTimeItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_CurrentTime), currentTimeItem.hidden == false {
            currentTimeItem.title = _textForTimeString(currentTimeStr)
            bottomAdapter.updateContent(forItemWithTag: SJEdgeControlLayerBottomItem_CurrentTime)
        }
    }

    private func _updateContentForBottomDurationItemIfNeeded() {
        guard let videoPlayer = videoPlayer else { return }
        if let durationTimeItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_DurationTime), durationTimeItem.hidden == false {
            durationTimeItem.title = _textForTimeString(videoPlayer.stringForSeconds(Int(videoPlayer.duration)))
            bottomAdapter.updateContent(forItemWithTag: SJEdgeControlLayerBottomItem_DurationTime)
        }
    }

    private func _reloadSizeForBottomTimeLabel() {
        // 00:00
        // 00:00:00
        let ms = "00:00"
        let hms = "00:00:00"
        let durationTimeStr = videoPlayer?.stringForSeconds(Int(videoPlayer?.duration ?? 0)) ?? ""
        let format = (durationTimeStr.count == ms.count) ? ms : hms
        let formatSize = (_textForTimeString(format) ?? NSAttributedString()).sj_textSize()

        let currentTimeItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_CurrentTime)
        let durationTimeItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_DurationTime)

        if durationTimeItem == nil && currentTimeItem == nil { return }
        currentTimeItem?.size = formatSize.width
        durationTimeItem?.size = formatSize.width
        bottomAdapter.reload()
    }

    private func _updateContentForBottomProgressSliderItemIfNeeded() {
        if !sj_view_isDisappeared(bottomContainerView) {
            if let progressItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_Progress), !progressItem.hidden {
                if let slider = progressItem.customView as? SJProgressSlider, let videoPlayer = videoPlayer {
                    slider.maxValue = videoPlayer.duration != 0 ? CGFloat(videoPlayer.duration) : 1
                    if !slider.isDragging { slider.value = CGFloat(videoPlayer.currentTime) }
                    slider.bufferProgress = CGFloat(videoPlayer.playableDuration) / slider.maxValue
                }
            }
        }
    }

    private func _updateContentForBottomProgressIndicatorIfNeeded() {
        if let bottomProgressIndicator = _bottomProgressIndicator, !sj_view_isDisappeared(bottomProgressIndicator), let videoPlayer = videoPlayer {
            bottomProgressIndicator.value = CGFloat(videoPlayer.currentTime)
            bottomProgressIndicator.maxValue = videoPlayer.duration != 0 ? CGFloat(videoPlayer.duration) : 1
        }
    }

    private func _updateCurrentTimeForDraggingProgressPopupViewIfNeeded() {
        if let v = _draggingProgressPopupView, !sj_view_isDisappeared(v) {
            v.currentTime = videoPlayer?.currentTime ?? 0
        }
    }

    private func _updateAppearStateForFixedBackButtonIfNeeded() {
        if !fixesBackItem { return }
        let isFitOnScreen = videoPlayer?.fitOnScreen ?? false
        let isFullscreen = videoPlayer?.isFullscreen ?? false
        let isLockedScreen = videoPlayer?.lockedScreen ?? false
        if isLockedScreen {
            _fixedBackButton?.isHidden = true
        } else if hiddenBackButtonWhenOrientationIsPortrait && !isFullscreen {
            _fixedBackButton?.isHidden = true
        } else {
            let isPlayOnScrollView = videoPlayer?.isPlayOnScrollView ?? false
            _fixedBackButton?.isHidden = isPlayOnScrollView && !isFitOnScreen && !isFullscreen
        }
    }

    private func _updateNetworkSpeedStrForLoadingView() {
        guard let videoPlayer = videoPlayer, self.loadingView.animating else { return }

        if self.loadingView.showsNetworkSpeed && !(videoPlayer.assetURL?.isFileURL ?? false) {
            self.loadingView.networkSpeedStr = NSAttributedString.sj_UIKitText { [weak self] make in
                let resources = SJVideoPlayerConfigurations.shared.resources
                if let font = resources.loadingNetworkSpeedTextFont { _ = make.font(font) }
                if let color = resources.loadingNetworkSpeedTextColor { _ = make.textColor(color) }
                _ = make.alignment(.center)
                _ = make.append(self?.videoPlayer?.reachability.networkSpeedStr ?? "")
            }
        } else {
            self.loadingView.networkSpeedStr = nil
        }
    }

    @available(iOS 11.0, *)
    @objc private func _reloadCustomStatusBarIfNeededAction() {
        _reloadCustomStatusBarIfNeeded()
    }

    @available(iOS 11.0, *)
    private func _reloadCustomStatusBarIfNeeded() {
        guard let customStatusBar = _customStatusBar, !sj_view_isDisappeared(customStatusBar) else { return }
        customStatusBar.networkStatus = videoPlayer?.reachability.networkStatus ?? .notReachable
        customStatusBar.date = Date()
        customStatusBar.batteryState = UIDevice.current.batteryState
        customStatusBar.batteryLevel = UIDevice.current.batteryLevel
    }

    // MARK: -

    private func _updateForDraggingProgressPopupView() {
        guard let popup = _draggingProgressPopupView else { return }
        var style: SJDraggingProgressPopupViewStyle = .normal
        if let videoPlayer = videoPlayer,
           !(videoPlayer.urlAsset?.isM3u8 ?? false),
           videoPlayer.playbackController.responds(to: #selector(SJMediaPlaybackScreenshotController.screenshot(withTime:size:completion:))) {
            if videoPlayer.isFullscreen {
                style = .fullscreen
            } else if videoPlayer.fitOnScreen {
                style = .fitOnScreen
            }
        }
        popup.style = style
        popup.duration = (videoPlayer?.duration ?? 0) != 0 ? (videoPlayer?.duration ?? 1) : 1
        popup.currentTime = videoPlayer?.currentTime ?? 0
        popup.dragTime = videoPlayer?.currentTime ?? 0
    }

    private func _textForTimeString(_ timeStr: String) -> NSAttributedString? {
        let resources = SJVideoPlayerConfigurations.shared.resources
        return NSAttributedString.sj_UIKitText { make in
            var attr = make.append(timeStr)
            if let font = resources.timeLabelFont { attr = attr.font(font) }
            if let color = resources.timeLabelColor { attr = attr.textColor(color) }
            _ = attr.alignment(.center)
        }
    }

    /// 此处为重置控制层的隐藏间隔.(如果点击到当前控制层上的item, 则重置控制层的隐藏间隔)
    @objc private func _resetControlLayerAppearIntervalForItemIfNeeded(_ note: Notification) {
        guard let item = note.object as? SJEdgeControlButtonItem else { return }
        if item.resetsAppearIntervalWhenPerformingItemAction {
            if topAdapter.contains(item) ||
                leftAdapter.contains(item) ||
                bottomAdapter.contains(item) ||
                rightAdapter.contains(item) {
                videoPlayer?.controlLayerNeedAppear()
            }
        }
    }

    private func _showOrRemoveBottomProgressIndicator() {
        if hiddenBottomProgressIndicator || videoPlayer?.playbackType == .LIVE {
            if _bottomProgressIndicator != nil {
                _bottomProgressIndicator?.removeFromSuperview()
                _bottomProgressIndicator = nil
            }
        } else {
            if _bottomProgressIndicator == nil {
                self.controlView().addSubview(self.bottomProgressIndicator)
                _updateLayoutForBottomProgressIndicator()
            }
        }
    }

    private func _updateLayoutForBottomProgressIndicator() {
        guard let bottomProgressIndicator = _bottomProgressIndicator else { return }
        bottomProgressIndicator.trackHeight = bottomProgressIndicatorHeight
        bottomProgressIndicator.frame = CGRect(x: 0, y: self.bounds.size.height - bottomProgressIndicatorHeight, width: self.bounds.size.width, height: bottomProgressIndicatorHeight)
    }

    private func _showOrHiddenLoadingView() {
        guard let videoPlayer = videoPlayer, videoPlayer.urlAsset != nil else {
            self.loadingView.stop()
            return
        }

        if videoPlayer.isPaused {
            self.loadingView.stop()
        } else if videoPlayer.assetStatus == .preparing {
            self.loadingView.start()
        } else if videoPlayer.assetStatus == .failed {
            self.loadingView.stop()
        } else if videoPlayer.assetStatus == .readyToPlay {
            videoPlayer.reasonForWaitingToPlay == SJWaitingToMinimizeStallsReason ? self.loadingView.start() : self.loadingView.stop()
        }
    }

    private func _willBeginDragging() {
        self.controlView().addSubview(self.draggingProgressPopupView)
        _updateForDraggingProgressPopupView()
        draggingProgressPopupView.snp.makeConstraints { make in
            make.center.equalToSuperview().offset(0)
        }

        sj_view_initializes(draggingProgressPopupView)
        sj_view_makeAppear(draggingProgressPopupView, false)

        if let willBeginDraggingExeBlock = _draggingObserver?.willBeginDraggingExeBlock {
            willBeginDraggingExeBlock(draggingProgressPopupView.dragTime)
        }
    }

    private func _didMove(_ progressTime: TimeInterval) {
        draggingProgressPopupView.dragTime = progressTime
        // 是否生成预览图
        if draggingProgressPopupView.previewImageHidden == false {
            videoPlayer?.screenshot(withTime: progressTime, size: CGSize(width: draggingProgressPopupView.frame.size.width, height: draggingProgressPopupView.frame.size.height), completion: { [weak self] _, image, _ in
                guard let self = self else { return }
                self.draggingProgressPopupView.previewImage = image
            })
        }

        if let didMoveExeBlock = _draggingObserver?.didMoveExeBlock {
            didMoveExeBlock(draggingProgressPopupView.dragTime)
        }
    }

    private func _endDragging() {
        let time = draggingProgressPopupView.dragTime
        if let willEndDraggingExeBlock = _draggingObserver?.willEndDraggingExeBlock {
            willEndDraggingExeBlock(time)
        }

        videoPlayer?.seek(toTime: time, completionHandler: nil)

        sj_view_makeDisappear(draggingProgressPopupView, true) { [weak self] in
            guard let self = self else { return }
            if let v = self._draggingProgressPopupView, sj_view_isDisappeared(v) {
                v.removeFromSuperview()
            }
        }

        if let didEndDraggingExeBlock = _draggingObserver?.didEndDraggingExeBlock {
            didEndDraggingExeBlock(time)
        }
    }

    //#pragma mark - mark
    //
    //    @objc private func configurationsDidUpdate(_ note: Notification) {
    //        if #available(iOS 14.0, *) { _updateContentForPictureInPictureItem() }
    //        _updateContentForBottomProgressSliderItemIfNeeded()
    //    }
}

// MARK: - SJEdgeControlLayerDelegate

///
/// 边缘控制层代理。
///
/// 对应原 ObjC 协议 `SJEdgeControlLayerDelegate`(撞名规则: Delegate 协议加 `_Protocol` 后缀, ObjC 名仍为 `SJEdgeControlLayerDelegate`)。
///
@objc(SJEdgeControlLayerDelegate)
@MainActor
public protocol SJEdgeControlLayerDelegate_Protocol: NSObjectProtocol {
    @objc(backItemWasTappedForControlLayer:)
    func backItemWasTapped(forControlLayer controlLayer: any SJControlLayer)
}

// MARK: - SJEdgeControlButtonItem (SJControlLayerExtended)

extension SJEdgeControlButtonItem {
    private static var resetsAppearIntervalKey: UInt8 = 0

    ///
    /// 点击item时是否重置控制层的显示间隔
    ///
    ///     default value is YES
    ///
    @objc public var resetsAppearIntervalWhenPerformingItemAction: Bool {
        get {
            let result = objc_getAssociatedObject(self, &SJEdgeControlButtonItem.resetsAppearIntervalKey)
            return (result as? NSNumber)?.boolValue ?? true
        }
        set {
            objc_setAssociatedObject(self, &SJEdgeControlButtonItem.resetsAppearIntervalKey, NSNumber(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
