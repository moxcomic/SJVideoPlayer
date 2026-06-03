//
//  SJEdgeControlLayerAdapters.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2018/10/20.
//  Copyright © 2018 畅三江. All rights reserved.
//

import UIKit
import SnapKit

/// 屏幕几何信息 (原 C struct SJ_Screen 的 Swift 等价物)
/// - max: 屏幕长边
/// - min: 屏幕短边
/// - is_iPhoneXSeries: 是否为 iPhone X 系列 (带安全区)
public struct SJ_Screen {
    public var max: CGFloat
    public var min: CGFloat
    public var is_iPhoneXSeries: Bool

    public init(max: CGFloat = 0, min: CGFloat = 0, is_iPhoneXSeries: Bool = false) {
        self.max = max
        self.min = min
        self.is_iPhoneXSeries = is_iPhoneXSeries
    }
}

/// 判断当前设备是否为 iPhone X 系列 (依据 keyWindow 底部安全区)
private func _isIPhoneXSeries() -> Bool {
    if UIDevice.current.userInterfaceIdiom == .phone {
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                if let window = windowScene.windows.first, window.isKeyWindow {
                    return window.safeAreaInsets.bottom > 0.0
                }
            }
        }
    }
    return false
}

/// 各控制层共同基类: 五方位 (top/left/bottom/right/center) item 容器与渐变遮罩,
/// 负责状态栏让位、iPhone X 系列适配、各边尺寸/间距、设备方向监听。
/// 当前界面方向 (取代已废弃的 UIApplication.statusBarOrientation)。文件级函数, 避免闭包内实例成员解析问题。
@MainActor
private func sjvp_currentInterfaceOrientation() -> UIInterfaceOrientation {
    for scene in UIApplication.shared.connectedScenes {
        if let windowScene = scene as? UIWindowScene,
           windowScene.windows.contains(where: { $0.isKeyWindow }) {
            return windowScene.interfaceOrientation
        }
    }
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        return windowScene.interfaceOrientation
    }
    return .unknown
}

@objc(SJEdgeControlLayerAdapters)
@MainActor
open class SJEdgeControlLayerAdapters: UIView {

    // MARK: - @protected ivar (供子类直接访问, 改为 internal 存储属性)

    var _topAdapter: SJEdgeControlButtonItemAdapter?
    var _leftAdapter: SJEdgeControlButtonItemAdapter?
    var _bottomAdapter: SJEdgeControlButtonItemAdapter?
    var _rightAdapter: SJEdgeControlButtonItemAdapter?
    var _centerAdapter: SJEdgeControlButtonItemAdapter?

    var _topContainerView: SJVideoPlayerControlMaskView?
    var _bottomContainerView: SJVideoPlayerControlMaskView?
    var _leftContainerView: UIView?
    var _rightContainerView: UIView?
    var _centerContainerView: UIView?

    var _screen = SJ_Screen()

    // MARK: - 私有状态

    nonisolated(unsafe) private var _notifyToken: NSObjectProtocol?
    private var _beforeBounds: CGRect = .zero

    // MARK: - 只读属性 (lazy load)

    @objc public var topAdapter: SJEdgeControlButtonItemAdapter {
        if let v = _topAdapter { return v }
        let adapter = SJEdgeControlButtonItemAdapter(frame: .zero, layoutType: .horizontalLayout)
        _topAdapter = adapter
        topContainerView.addSubview(adapter.view)
        _updateTopLayout(nil)
        return adapter
    }

    @objc public var leftAdapter: SJEdgeControlButtonItemAdapter {
        if let v = _leftAdapter { return v }
        let adapter = SJEdgeControlButtonItemAdapter(frame: .zero, layoutType: .verticalLayout)
        _leftAdapter = adapter
        leftContainerView.addSubview(adapter.view)
        adapter.view.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview().offset(0)
            make.left.equalTo(self.leftContainerView.safeAreaLayoutGuide.snp.left).offset(self.leftMargin)
            make.width.equalToSuperview().offset(self.leftWidth)
        }
        return adapter
    }

    @objc public var bottomAdapter: SJEdgeControlButtonItemAdapter {
        if let v = _bottomAdapter { return v }
        let adapter = SJEdgeControlButtonItemAdapter(frame: .zero, layoutType: .horizontalLayout)
        _bottomAdapter = adapter
        bottomContainerView.addSubview(adapter.view)
        adapter.view.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(0)
            make.left.equalTo(self.bottomContainerView.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.bottomContainerView.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.bottomContainerView.safeAreaLayoutGuide.snp.bottom).offset(-self.bottomMargin)
            make.height.equalToSuperview().offset(self.bottomHeight)
        }
        return adapter
    }

    @objc public var rightAdapter: SJEdgeControlButtonItemAdapter {
        if let v = _rightAdapter { return v }
        let adapter = SJEdgeControlButtonItemAdapter(frame: .zero, layoutType: .verticalLayout)
        _rightAdapter = adapter
        rightContainerView.addSubview(adapter.view)
        adapter.view.snp.makeConstraints { make in
            make.top.left.bottom.equalToSuperview().offset(0)
            make.right.equalTo(self.rightContainerView.safeAreaLayoutGuide.snp.right).offset(-self.rightMargin)
            make.width.equalToSuperview().offset(self.rightWidth)
        }
        return adapter
    }

    @objc public var centerAdapter: SJEdgeControlButtonItemAdapter {
        if let v = _centerAdapter { return v }
        let adapter = SJEdgeControlButtonItemAdapter(frame: .zero, layoutType: .frameLayout)
        _centerAdapter = adapter
        adapter.itemFillSizeForFrameLayout = self.bounds.size
        centerContainerView.addSubview(adapter)
        adapter.snp.makeConstraints { make in
            make.edges.equalToSuperview().offset(0)
        }
        return adapter
    }

    @objc public var topContainerView: SJVideoPlayerControlMaskView {
        if let v = _topContainerView { return v }
        let containerView = SJVideoPlayerControlMaskView(style: .top)
        _topContainerView = containerView
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(0)
            make.right.equalToSuperview().offset(0)
        }

        #if DEBUG
        if showBackgroundColor {
            containerView.backgroundColor = UIColor(red: CGFloat(arc4random() % 256) / 255.0,
                                                    green: CGFloat(arc4random() % 256) / 255.0,
                                                    blue: CGFloat(arc4random() % 256) / 255.0,
                                                    alpha: 1)
        }
        #endif
        return containerView
    }

    @objc public var bottomContainerView: SJVideoPlayerControlMaskView {
        if let v = _bottomContainerView { return v }
        let containerView = SJVideoPlayerControlMaskView(style: .bottom)
        _bottomContainerView = containerView
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(0)
            make.bottom.right.equalToSuperview().offset(0)
        }

        #if DEBUG
        if showBackgroundColor {
            containerView.backgroundColor = UIColor(red: CGFloat(arc4random() % 256) / 255.0,
                                                    green: CGFloat(arc4random() % 256) / 255.0,
                                                    blue: CGFloat(arc4random() % 256) / 255.0,
                                                    alpha: 1)
        }
        #endif
        return containerView
    }

    @objc public var leftContainerView: UIView {
        if let v = _leftContainerView { return v }
        let containerView = UIView()
        _leftContainerView = containerView
        insertSubview(containerView, at: 0)
        containerView.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(0)
            make.bottom.equalToSuperview().offset(0)
        }

        #if DEBUG
        if showBackgroundColor {
            containerView.backgroundColor = UIColor(red: CGFloat(arc4random() % 256) / 255.0,
                                                    green: CGFloat(arc4random() % 256) / 255.0,
                                                    blue: CGFloat(arc4random() % 256) / 255.0,
                                                    alpha: 1)
        }
        #endif
        return containerView
    }

    @objc public var rightContainerView: UIView {
        if let v = _rightContainerView { return v }
        let containerView = UIView()
        _rightContainerView = containerView
        insertSubview(containerView, at: 0)
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(0)
            make.right.bottom.equalToSuperview().offset(0)
        }

        #if DEBUG
        if showBackgroundColor {
            containerView.backgroundColor = UIColor(red: CGFloat(arc4random() % 256) / 255.0,
                                                    green: CGFloat(arc4random() % 256) / 255.0,
                                                    blue: CGFloat(arc4random() % 256) / 255.0,
                                                    alpha: 1)
        }
        #endif
        return containerView
    }

    @objc public var centerContainerView: UIView {
        if let v = _centerContainerView { return v }
        let containerView = UIView()
        _centerContainerView = containerView
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview().offset(0)
        }

        #if DEBUG
        if showBackgroundColor {
            containerView.backgroundColor = UIColor(red: CGFloat(arc4random() % 256) / 255.0,
                                                    green: CGFloat(arc4random() % 256) / 255.0,
                                                    blue: CGFloat(arc4random() % 256) / 255.0,
                                                    alpha: 1)
        }
        #endif
        return containerView
    }

    // MARK: - 可配置属性

    /// 自动调整顶部间距, 让出状态栏. default is YES.
    @objc public var autoAdjustTopSpacing: Bool = false

    /// 自动调整布局, 如果是 iPhone X. default is YES.
    @objc public var autoAdjustLayoutWhenDeviceIsIPhoneXSeries: Bool = false

    #if DEBUG
    @objc public var showBackgroundColor: Bool = false
    #endif

    // - default is 49.
    @objc public var topHeight: CGFloat = 49 {
        didSet {
            _topAdapter?.view.snp.updateConstraints { make in
                make.height.equalToSuperview().offset(self.topHeight)
            }
        }
    }
    @objc public var leftWidth: CGFloat = 49 {
        didSet {
            _leftAdapter?.view.snp.updateConstraints { make in
                make.width.equalToSuperview().offset(self.leftWidth)
            }
        }
    }
    @objc public var bottomHeight: CGFloat = 49 {
        didSet {
            _bottomAdapter?.view.snp.updateConstraints { make in
                make.height.equalToSuperview().offset(self.bottomHeight)
            }
        }
    }
    @objc public var rightWidth: CGFloat = 49 {
        didSet {
            _rightAdapter?.view.snp.updateConstraints { make in
                make.width.equalToSuperview().offset(self.rightWidth)
            }
        }
    }

    // - default is 4.
    @objc public var topMargin: CGFloat = 4 {
        didSet {
            _updateLayout()
        }
    }
    // - default is 0.
    @objc public var leftMargin: CGFloat = 0 {
        didSet {
            let margin = self.leftMargin
            _leftAdapter?.view.snp.updateConstraints { make in
                make.left.equalTo(self.leftContainerView.safeAreaLayoutGuide.snp.left).offset(margin)
            }
        }
    }
    @objc public var bottomMargin: CGFloat = 0 {
        didSet {
            let margin = self.bottomMargin
            _bottomAdapter?.view.snp.updateConstraints { make in
                make.bottom.equalTo(self.bottomContainerView.safeAreaLayoutGuide.snp.bottom).offset(-margin)
            }
        }
    }
    @objc public var rightMargin: CGFloat = 0 {
        didSet {
            let margin = self.rightMargin
            _rightAdapter?.view.snp.updateConstraints { make in
                make.right.equalTo(self.rightContainerView.safeAreaLayoutGuide.snp.right).offset(-margin)
            }
        }
    }

    // MARK: - 私有计算属性

    private var isFitOnScreen: Bool {
        return (_screen.min == self.bounds.size.width && _screen.max == self.bounds.size.height) ||
               (_screen.min == self.bounds.size.height && _screen.max == self.bounds.size.width)
    }

    // MARK: - 生命周期

    public override init(frame: CGRect) {
        super.init(frame: frame)
        let screenW = UIScreen.main.bounds.size.width
        let screenH = UIScreen.main.bounds.size.height
        let max = Swift.max(screenW, screenH)
        let min = Swift.min(screenW, screenH)
        _screen = SJ_Screen(max: max, min: min, is_iPhoneXSeries: _isIPhoneXSeries())

        // topHeight/leftWidth/bottomHeight/rightWidth 默认 49, topMargin 默认 4 已在属性声明处设置.

        _observeNotifies()
        self.autoAdjustTopSpacing = true
        self.autoAdjustLayoutWhenDeviceIsIPhoneXSeries = true
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let token = _notifyToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

    // MARK: - 命中测试 / frame & bounds

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        /// 自身不消费事件, 由子视图消费;
        return view == self ? nil : view
    }

    public override var frame: CGRect {
        didSet {
            _updateLayout()
        }
    }

    public override var bounds: CGRect {
        didSet {
            _updateLayout()
        }
    }

    // MARK: - 布局

    private func _updateLayout() {
        _centerAdapter?.itemFillSizeForFrameLayout = self.bounds.size

        let curr = self.bounds
        if _screen.is_iPhoneXSeries && autoAdjustLayoutWhenDeviceIsIPhoneXSeries {
            if !_beforeBounds.equalTo(curr) {
                let viewW = curr.size.width
                let viewH = curr.size.height

                let isFullscreen = (viewW == _screen.max) && (viewH == _screen.min)

                if isFullscreen {
                    _updateLayout_isFullscreen_iPhone_X()
                } else {
                    _updateLayout_isNormal_iPhone_X()
                }
            }
        } else if !_beforeBounds.equalTo(curr) {
            _updateTopLayout(nil)
        }
        _beforeBounds = curr
    }

    private func _updateLayout_isNormal_iPhone_X() {
        _topAdapter?.view.snp.remakeConstraints { make in
            make.top.equalTo(self.topContainerView.safeAreaLayoutGuide.snp.top).offset(self.topMargin)
            make.left.equalTo(self.topContainerView.safeAreaLayoutGuide.snp.left)
            make.bottom.equalToSuperview().offset(0)
            make.right.equalTo(self.topContainerView.safeAreaLayoutGuide.snp.right)

            make.height.equalToSuperview().offset(self.topHeight)
        }

        _leftAdapter?.view.snp.remakeConstraints { make in
            make.top.bottom.right.equalToSuperview().offset(0)
            make.left.equalTo(self.leftContainerView.safeAreaLayoutGuide.snp.left).offset(self.leftMargin)

            make.width.equalToSuperview().offset(self.leftWidth)
        }

        _bottomAdapter?.view.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(0)
            make.left.equalTo(self.bottomContainerView.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.bottomContainerView.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.bottomContainerView.safeAreaLayoutGuide.snp.bottom).offset(-self.bottomMargin)

            make.height.equalToSuperview().offset(self.bottomHeight)
        }

        _rightAdapter?.view.snp.remakeConstraints { make in
            make.top.left.bottom.equalToSuperview().offset(0)
            make.right.equalTo(self.rightContainerView.safeAreaLayoutGuide.snp.right).offset(-self.rightMargin)

            make.width.equalToSuperview().offset(self.rightWidth)
        }
    }

    private func _updateLayout_isFullscreen_iPhone_X() {
        let safeWidth = ceil(_screen.min * 16 / 9.0)
        let safeLeftMargin = ceil((_screen.max - safeWidth) * 0.5)

        _topAdapter?.view.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(self.autoAdjustTopSpacing ? 20 : self.topMargin)
            make.left.greaterThanOrEqualTo(0).priority(.low)
            make.bottom.equalToSuperview().offset(0)
            make.right.lessThanOrEqualTo(0).priority(.low)
            make.centerX.equalToSuperview().offset(0)

            make.width.equalToSuperview().offset(safeWidth)
            make.height.equalToSuperview().offset(self.topHeight)
        }

        _leftAdapter?.view.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(0)
            make.left.equalToSuperview().offset(safeLeftMargin + self.leftMargin)
            make.bottom.equalToSuperview().offset(0)
            make.right.equalToSuperview().offset(0)

            make.width.equalToSuperview().offset(self.leftWidth)
        }

        _bottomAdapter?.view.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(0)
            make.left.greaterThanOrEqualTo(0).priority(.low)
            make.bottom.equalToSuperview().offset(-(self.bottomMargin + 20))
            make.right.lessThanOrEqualTo(0).priority(.low)
            make.centerX.equalToSuperview().offset(0)

            make.width.equalToSuperview().offset(safeWidth)
            make.height.equalToSuperview().offset(self.bottomHeight)
        }

        _rightAdapter?.view.snp.remakeConstraints { make in
            make.top.left.bottom.equalToSuperview().offset(0)
            make.right.equalToSuperview().offset(-(safeLeftMargin + self.rightMargin))

            make.width.equalToSuperview().offset(self.rightWidth)
        }
    }

    // MARK: - 方向监听

    private func _observeNotifies() {
        _notifyToken = NotificationCenter.default.addObserver(
            forName: UIApplication.willChangeStatusBarOrientationNotification,
            object: nil,
            queue: nil
        ) { [weak self] note in
            nonisolated(unsafe) let note = note
            MainActor.assumeIsolated {
                guard let self = self else { return }
                self._updateTopLayout(note)
            }
        }
    }


    /// 是否处于"适配屏幕"尺寸(对应 ObjC -isFitOnScreen)。
    private var fitOnScreen: Bool {
        return (_screen.min == bounds.size.width && _screen.max == bounds.size.height) ||
               (_screen.min == bounds.size.height && _screen.max == bounds.size.width)
    }

    private func _updateTopLayout(_ notify: Notification?) {
        guard _topAdapter != nil else { return }
        if _screen.is_iPhoneXSeries && autoAdjustLayoutWhenDeviceIsIPhoneXSeries { return }
        UIView.animate(withDuration: 0, animations: {}, completion: { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self = self else { return }
                let orientation: UIInterfaceOrientation
                if let value = notify?.userInfo?[UIApplication.statusBarOrientationUserInfoKey] as? Int,
                   let o = UIInterfaceOrientation(rawValue: value) {
                    orientation = o
                } else {
                    orientation = sjvp_currentInterfaceOrientation()
                }

                switch orientation {
                case .unknown:
                    break
                case .portrait, .portraitUpsideDown:
                    self.topAdapter.view.snp.remakeConstraints { make in
                        make.top.equalTo(self.topContainerView.safeAreaLayoutGuide.snp.top).offset(self.topMargin)
                        make.left.equalTo(self.topContainerView.safeAreaLayoutGuide.snp.left)
                        make.right.equalTo(self.topContainerView.safeAreaLayoutGuide.snp.right)
                        make.bottom.equalToSuperview().offset(0)
                        make.height.equalToSuperview().offset(self.topHeight)
                    }
                case .landscapeLeft, .landscapeRight:
                    self.topAdapter.view.snp.remakeConstraints { make in
                        make.top.equalToSuperview().offset(self.topMargin + (self.fitOnScreen && self.autoAdjustTopSpacing ? 20 : 0)) // 统一 20
                        make.left.equalTo(self.topContainerView.safeAreaLayoutGuide.snp.left)
                        make.right.equalTo(self.topContainerView.safeAreaLayoutGuide.snp.right)
                        make.bottom.equalToSuperview().offset(0)
                        make.height.equalToSuperview().offset(self.topHeight)
                    }
                @unknown default:
                    break
                }

//                UIView.animate(withDuration: 0.4) {
//                    self.layoutIfNeeded()
//                }
            }
        })
    }
}
