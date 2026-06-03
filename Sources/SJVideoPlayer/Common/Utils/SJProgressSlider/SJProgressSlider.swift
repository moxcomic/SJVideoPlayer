//
//  SJProgressSlider.swift
//  Pods-SJProgressSlider_Example
//
//  Created by 畅三江 on 2017/11/20.
//  Copyright © 2017年 changsanjiang. All rights reserved.
//

import UIKit
import ObjectiveC.runtime

// MARK: - 私有内部 ImageView

/// 内部使用的 UIImageView 子类: 在 setImage 时回调, 用于拇指图片更新后重新布局
@MainActor
private final class SJProgressSliderImageView: UIImageView {
    var setImageExeBlock: ((SJProgressSliderImageView) -> Void)?

    override var image: UIImage? {
        didSet {
            setImageExeBlock?(self)
        }
    }
}

// MARK: - SJProgressSlider

/// 自绘进度条
@objc(SJProgressSlider)
@MainActor
open class SJProgressSlider: UIView {

    @objc public weak var delegate: (any SJProgressSliderDelegate_Protocol)?

    /// Default is YES. 是否切圆角. 默认YES
    @objc(isRound) public var round: Bool = true {
        didSet {
            if round == oldValue { return }
            _needUpdateContainerCornerRadius()
        }
    }

    /// Track height. default is 8.0. 轨道高度
    @objc public var trackHeight: CGFloat = 8 {
        didSet {
            _needUpdateContainerCornerRadius()
            _needUpdateContainerLayout()
        }
    }

    /// 轨道, 你可以设置图片或者将它当做 `view`, 设置背景颜色来使用. 以下 `trace` & `thumb` 相同.
    @objc public private(set) lazy var trackImageView: UIImageView = _makeImageView()

    /// 走过的痕迹.
    @objc public private(set) lazy var traceImageView: UIImageView = _makeImageView()

    /// 拇指
    @objc public private(set) lazy var thumbImageView: UIImageView = _makeImageView()

    @objc(setThumbCornerRadius:size:)
    public func setThumbCornerRadius(_ thumbCornerRadius: CGFloat, size: CGSize) {
        setThumbCornerRadius(thumbCornerRadius, size: size, thumbBackgroundColor: .green)
    }

    @objc(setThumbCornerRadius:size:thumbBackgroundColor:)
    public func setThumbCornerRadius(_ thumbCornerRadius: CGFloat, size: CGSize, thumbBackgroundColor: UIColor) {
        thumbImageView.layer.masksToBounds = false
        thumbImageView.layer.shadowColor = UIColor(white: 0.382, alpha: 0.614).cgColor
        thumbImageView.layer.shadowOpacity = 1
        thumbImageView.layer.shadowOffset = CGSize(width: 0.001, height: 0.2)
        thumbImageView.layer.shadowPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: thumbCornerRadius).cgPath
        thumbImageView.layer.cornerRadius = thumbCornerRadius
        thumbImageView.backgroundColor = thumbBackgroundColor
        _updateThumbSize(size)
    }

    /// current Value
    @objc public var value: CGFloat {
        get { _value }
        set { setValue(newValue, animated: false) }
    }
    private var _value: CGFloat = 0

    @objc(setValue:animated:)
    public func setValue(_ value_new: CGFloat, animated: Bool) {
        var value_new = value_new
        if minValue > maxValue { return }
        if value_new.isNaN { return }
        if value_new == _value { return }
        let value_old = _value
        if value_new < minValue { value_new = minValue }
        else if value_new > maxValue { value_new = maxValue }
//        if showsStopNode {
//            let stop = stopNodeLocation * maxValue
//            if value_new > stop { value_new = stop }
//        }
        _value = value_new

        if animated {
            let duration = _calculateAnimaDuration(value_new - value_old)
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(duration)
            _needUpdateTraceLayout()
            UIView.commitAnimations()
        } else {
            _needUpdateTraceLayout()
        }

        if let delegate = delegate, delegate.responds(to: #selector(SJProgressSliderDelegate_Protocol.slider(_:valueDidChange:))) {
            delegate.slider?(self, valueDidChange: _value)
        }
    }

    @objc public var animaMaxDuration: CGFloat = 0.5 // default is 0.5.

    /// default is 0.0;
    @objc public var minValue: CGFloat = 0 {
        didSet {
            if minValue != oldValue { _needUpdateContainerLayout() }
        }
    }

    /// default is 1.0;
    @objc public var maxValue: CGFloat = 1 {
        didSet {
            if maxValue != oldValue { _needUpdateContainerLayout() }
        }
    }

    /// default is 0;
    @objc public var expand: CGFloat = 0

    /// default is 0.382;  0...1
    @objc public var thumbOutsideSpace: Float = 0.382

    /// If you don't want to use this gesture, you can disable it: pan.isEnabled = false.
    @objc public private(set) lazy var pan: UIPanGestureRecognizer = {
        let gr = UIPanGestureRecognizer(target: self, action: #selector(handlePanGR(_:)))
        gr.delaysTouchesBegan = true
        return gr
    }()

    /// 点击跳转的手势
    /// - 当你想点击跳转时, 需要开启手势
    /// - 默认是关闭, 即 tap.isEnabled = false;
    @objc public private(set) lazy var tap: UITapGestureRecognizer = {
        let gr = UITapGestureRecognizer(target: self, action: #selector(handleTapGR(_:)))
        gr.delaysTouchesBegan = true
        return gr
    }()

    @objc public var tappedExeBlock: ((_ slider: SJProgressSlider, _ location: CGFloat) -> Void)?

    /// The state of dragging. 是否在拖拽.
    @objc public private(set) var isDragging: Bool = false

    /// 是否加载中
    /// - 如果是 YES, 将会在拇指上显示菊花圈圈(前提是设置了拇指 thumb)
    @objc public var isLoading: Bool = false {
        didSet {
            if isLoading { indicatorView.startAnimating() }
            else { indicatorView.stopAnimating() }
        }
    }

    /// 菊花圈圈的线颜色
    /// - 默认是黑色
    @objc public var loadingColor: UIColor = .black {
        didSet {
            _indicatorView?.color = loadingColor
        }
    }

    // MARK: - 私有存储

    private var _indicatorView: UIActivityIndicatorView?
    private lazy var containerView: UIView = {
        let v = UIView()
        v.clipsToBounds = true
        return v
    }()

    // buffer
    private var _bufferProgressView: UIView?
    private var _bufferProgressColor: UIColor?
    private var _showsBufferProgress: Bool = false
    private var _bufferProgress: CGFloat = 0

    // border
    private var _borderColor: UIColor?
    private var _showsBorder: Bool = false
    private var _borderWidth: CGFloat = 0

    // prompt
    private var _promptLabel: UILabel?
    private var _promptLabelBottomConstraint: NSLayoutConstraint?
    private var _promptSpacing: CGFloat = 0

    // stop node
    private var _showsStopNode: Bool = false
    private var _stopNodeView: UIView?
    private var _stopNodeLocation: CGFloat = 0

    private var _isCancelled: Bool = false

    // MARK: - 生命周期

    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

    private func _init() {
        _setupDefaultValues()
        _setupView()
        _setupGestrue()
        _needUpdateContainerCornerRadius()
    }

    private func _setupDefaultValues() {
        animaMaxDuration = 0.5
        trackHeight = 8
        maxValue = 1
        minValue = 0
        round = true
        _value = 0
        thumbOutsideSpace = 0.382
        promptSpacing = 4.0
        loadingColor = .black
    }

    private func _setupGestrue() {
        addGestureRecognizer(pan)
        addGestureRecognizer(tap)
        tap.require(toFail: pan)
        tap.isEnabled = false
    }

    // MARK: - 手势

    @objc private func handlePanGR(_ pan: UIPanGestureRecognizer) {
        if pan.state == .began {
            isDragging = true
            if let delegate = delegate, delegate.responds(to: #selector(SJProgressSliderDelegate_Protocol.sliderWillBeginDragging(_:))) {
                delegate.sliderWillBeginDragging?(self)
            }
        }

        if _isCancelled == false {
            let offset = pan.translation(in: pan.view).x
            let add = (offset / containerView.bounds.size.width) * (maxValue - minValue)
            setValue(self.value + add, animated: true)
            pan.setTranslation(.zero, in: pan.view)
        }

        switch pan.state {
        case .ended, .failed, .cancelled:
            if !_isCancelled, let delegate = delegate, delegate.responds(to: #selector(SJProgressSliderDelegate_Protocol.sliderDidEndDragging(_:))) {
                delegate.sliderDidEndDragging?(self)
            }
            isDragging = false
            _isCancelled = false
        default:
            break
        }
    }

    @objc private func handleTapGR(_ tap: UITapGestureRecognizer) {
        if containerView.frame.size.width == 0 { return }
        let point = tap.location(in: tap.view).x
        let value = point / containerView.frame.size.width * (maxValue - minValue)
        if let tappedExeBlock = tappedExeBlock { tappedExeBlock(self, value) }
        else { setValue(value, animated: true) }
    }

    /// 取消拖拽
    @objc public func cancelDragging() {
        _isCancelled = true
        pan.setValue(NSNumber(value: UIGestureRecognizer.State.cancelled.rawValue), forKey: "state")
    }

    // MARK: - 动画时长

    /// add 此次增加的值
    private func _calculateAnimaDuration(_ add: CGFloat) -> CGFloat {
        let add = abs(add)
        var sum = maxValue - minValue
        if sum.isNaN || sum <= 0 { sum = 0.001 }
        let scale = add / sum
        return animaMaxDuration * scale + 0.08
    }

    // MARK: - 视图构建

    private func _makeImageView() -> SJProgressSliderImageView {
        let imageView = SJProgressSliderImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .center
        return imageView
    }

    private func _setupView() {
        // 触发 trackImageView/traceImageView/thumbImageView 懒加载
        let trace = traceImageView
        let track = trackImageView
        let thumb = thumbImageView

        (thumb as? SJProgressSliderImageView)?.setImageExeBlock = { [weak self] imageView in
            guard let self = self else { return }
            imageView.bounds = CGRect(origin: .zero, size: imageView.image?.size ?? .zero)
            self._needUpdateThumbLayout()
        }

        addSubview(containerView)
        containerView.addSubview(track)
        containerView.addSubview(trace)
        addSubview(thumb)

        trace.backgroundColor = .green
        track.backgroundColor = .lightGray
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        _needUpdateContainerLayout()
    }

    private var indicatorView: UIActivityIndicatorView {
        if let v = _indicatorView { return v }
        let v = UIActivityIndicatorView()
        _indicatorView = v
        thumbImageView.addSubview(v)
        v.color = loadingColor
        v.translatesAutoresizingMaskIntoConstraints = false
        thumbImageView.addConstraint(NSLayoutConstraint(item: v, attribute: .centerX, relatedBy: .equal, toItem: thumbImageView, attribute: .centerX, multiplier: 1, constant: 0))
        thumbImageView.addConstraint(NSLayoutConstraint(item: v, attribute: .centerY, relatedBy: .equal, toItem: thumbImageView, attribute: .centerY, multiplier: 1, constant: 0))
        _needUpdateIndicatorTransform()
        return v
    }

    // MARK: - slider 布局

    private func _needUpdateContainerLayout() {
        if self.bounds.size == .zero { return }

        let maxW = self.frame.size.width
        let maxH = self.frame.size.height

        let containerW = maxW - expand * 2
        let containerH = trackHeight
        containerView.bounds = CGRect(x: 0, y: 0, width: containerW, height: containerH)
        containerView.center = CGPoint(x: maxW * 0.5, y: maxH * 0.5)
        _needUpdateTrackLayout()
        if showsBufferProgress { _needUpdateBufferViewLayout() }
        if showsStopNode { _needUpdateStopNodeViewLayout() }
    }

    private func _needUpdateContainerCornerRadius() {
        if round { containerView.layer.cornerRadius = trackHeight * 0.5 }
        else { containerView.layer.cornerRadius = 0.0 }
    }

    private func _needUpdateTrackLayout() {
        if containerView.bounds.size == .zero { return }
        let trackW = containerView.frame.size.width
        let trackH = containerView.frame.size.height
        trackImageView.frame = CGRect(x: 0, y: 0, width: trackW, height: trackH)
        _needUpdateTraceLayout()
    }

    private func _needUpdateTraceLayout() {
        if containerView.bounds.size == .zero { return }

        let maxW = containerView.frame.size.width
        let sum = maxValue - minValue
        var traceW = maxW * (_value - minValue) / sum
        var traceH = containerView.frame.size.height

        if traceW.isNaN || traceW.isInfinite { traceW = 0 }
        if traceH.isNaN || traceH.isInfinite { traceH = 0 }

        traceImageView.frame = CGRect(x: 0, y: 0, width: traceW, height: traceH)
        _needUpdateThumbLayout()
    }

    private func _needUpdateThumbLayout() {
        if self.bounds.size == .zero { return }

        let height = self.frame.size.height

        let thumbW = thumbImageView.frame.size.width
        let outside = ceil(thumbImageView.frame.size.width * CGFloat(thumbOutsideSpace))
        let minCenterX = expand - outside + thumbW * 0.5
        let maxCenterX = containerView.bounds.size.width - thumbW * 0.5 + outside + expand

        var tracePosition = traceImageView.frame.size.width + expand
        if tracePosition <= minCenterX { tracePosition = minCenterX }
        else if tracePosition >= maxCenterX { tracePosition = maxCenterX }

        if tracePosition.isNaN || tracePosition.isInfinite { tracePosition = 0 }
        thumbImageView.center = CGPoint(x: tracePosition, y: height * 0.5)
    }

    private func _updateThumbSize(_ size: CGSize) {
        thumbImageView.bounds = CGRect(origin: .zero, size: size)
        _needUpdateThumbLayout()
        _needUpdateIndicatorTransform()
    }

    private func _needUpdateIndicatorTransform() {
        _indicatorView?.transform = CGAffineTransform(scaleX: thumbImageView.bounds.size.width / 16 * 0.6, y: thumbImageView.bounds.size.height / 16 * 0.6)
    }
}

// MARK: - Prompt

extension SJProgressSlider {

    @objc public var promptLabel: UILabel {
        if let label = _promptLabel { return label }
        let label = UILabel()
        _promptLabel = label
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: traceImageView, attribute: .trailing, multiplier: 1, constant: 0))
        let bottom = NSLayoutConstraint(item: label, attribute: .bottom, relatedBy: .equal, toItem: thumbImageView, attribute: .top, multiplier: 1, constant: -_promptSpacing)
        _promptLabelBottomConstraint = bottom
        addConstraint(bottom)
        return label
    }

    /// default is 4.0
    @objc public var promptSpacing: CGFloat {
        get { _promptSpacing }
        set {
            _promptSpacing = newValue
            _promptLabelBottomConstraint?.constant = -newValue
        }
    }
}

// MARK: - Border

extension SJProgressSlider {

    /// default is NO.
    @objc public var showsBorder: Bool {
        get { _showsBorder }
        set {
            if _showsBorder == newValue { return }
            // 注: 保留原 ObjC 实现行为(此处未更新 _showsBorder, 与原代码一致)
            if newValue {
                containerView.layer.borderColor = _borderColor?.cgColor
                containerView.layer.borderWidth = _borderWidth
            } else {
                containerView.layer.borderColor = nil
                containerView.layer.borderWidth = 0
            }
        }
    }

    /// borderColor, default is lightGrayColor.
    @objc public var borderColor: UIColor! {
        get {
            if let c = _borderColor { return c }
            return .lightGray
        }
        set {
            _borderColor = newValue
            if _showsBorder { containerView.layer.borderColor = newValue?.cgColor }
        }
    }

    /// borderWidth, default is 0.4.
    @objc public var borderWidth: CGFloat {
        get {
            // 保留原 ObjC 行为: getter 读取关联对象(原代码 objc_getAssociatedObject(self, _cmd)),
            // 与 setter 写入的 ivar 不是同一存储, 故除非外部写入关联对象, 否则恒返回 0.4。
            // 此处用静态稳定 key 替代 _cmd。
            let width = (objc_getAssociatedObject(self, &SJProgressSlider._borderWidthAssocKey) as? NSNumber)?.doubleValue ?? 0
            if width != 0 { return width }
            return 0.4
        }
        set {
            _borderWidth = newValue
            if _showsBorder { containerView.layer.borderWidth = newValue }
        }
    }

    private static var _borderWidthAssocKey: UInt8 = 0
}

// MARK: - Buffer

extension SJProgressSlider {

    /// 开启缓冲进度. default is NO.
    @objc public var showsBufferProgress: Bool {
        get { _showsBufferProgress }
        set {
            if newValue == _showsBufferProgress { return }
            _showsBufferProgress = newValue
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if newValue {
                    let bufferView = self.bufferProgressView
                    self.containerView.insertSubview(bufferView, aboveSubview: self.trackImageView)
                    bufferView.frame = CGRect(x: 0, y: 0, width: 0, height: self.containerView.frame.size.height)
                    let bufferProgress = self.bufferProgress
                    if bufferProgress != 0 { self._needUpdateBufferViewLayout() }
                } else {
                    self.bufferProgressView.removeFromSuperview()
                }
            }
        }
    }

    /// 缓冲进度颜色. default is grayColor
    @objc public var bufferProgressColor: UIColor! {
        get {
            if let c = _bufferProgressColor { return c }
            return .gray
        }
        set {
            _bufferProgressColor = newValue
            DispatchQueue.main.async { [weak self] in
                self?.bufferProgressView.backgroundColor = newValue
            }
        }
    }

    /// 缓冲进度  0...1
    @objc public var bufferProgress: CGFloat {
        get { _bufferProgress }
        set {
            var bufferProgress = newValue
            if bufferProgress.isNaN { return }
            if bufferProgress < 0 { bufferProgress = 0 }
            else if bufferProgress > 1 { bufferProgress = 1 }
            _bufferProgress = bufferProgress
            _needUpdateBufferViewLayout()
        }
    }

    fileprivate var bufferProgressView: UIView {
        if let v = _bufferProgressView { return v }
        let v = UIView()
        _bufferProgressView = v
        v.backgroundColor = bufferProgressColor
        return v
    }

    fileprivate func _needUpdateBufferViewLayout() {
        let bufferView = bufferProgressView
        var progress = bufferProgress
        if _showsStopNode && progress > _stopNodeLocation { progress = _stopNodeLocation }
        let width = progress * containerView.frame.size.width
        var frame = bufferView.frame
        frame.size.height = containerView.frame.size.height
        frame.size.width = width
        bufferView.frame = frame
    }
}

// MARK: - Stop Node

extension SJProgressSlider {

    @objc public var showsStopNode: Bool {
        get { _showsStopNode }
        set {
            if newValue != _showsStopNode {
                _showsStopNode = newValue
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if newValue {
                        self.insertSubview(self.stopNodeView, belowSubview: self.thumbImageView)
                        self._needUpdateStopNodeViewLayout()
                    } else {
                        self._stopNodeView?.removeFromSuperview()
                    }
                }
            }
        }
    }

    @objc public var stopNodeView: UIView! {
        get {
            if _stopNodeView == nil {
                let v = UIView(frame: .zero)
                v.backgroundColor = trackImageView.backgroundColor
                v.clipsToBounds = true
                _stopNodeView = v
            }
            return _stopNodeView
        }
        set {
            _stopNodeView = newValue
        }
    }

    /// 0..1
    @objc public var stopNodeLocation: CGFloat {
        get { _stopNodeLocation }
        set {
            var stopNodeLocation = newValue
            if stopNodeLocation > 1 { stopNodeLocation = 1 }
            else if stopNodeLocation < 0 { stopNodeLocation = 0 }

            if stopNodeLocation != _stopNodeLocation {
                _stopNodeLocation = stopNodeLocation
                if _showsStopNode {
                    _needUpdateStopNodeViewLayout()
                    _needUpdateBufferViewLayout()
                }
            }
        }
    }

    @objc(setStopNodeViewCornerRadius:size:)
    public func setStopNodeViewCornerRadius(_ cornerRadius: CGFloat, size: CGSize) {
        setStopNodeViewCornerRadius(cornerRadius, size: size, backgroundColor: trackImageView.backgroundColor ?? .clear)
    }

    @objc(setStopNodeViewCornerRadius:size:backgroundColor:)
    public func setStopNodeViewCornerRadius(_ cornerRadius: CGFloat, size: CGSize, backgroundColor: UIColor) {
        if _showsStopNode {
            stopNodeView.layer.cornerRadius = cornerRadius
            stopNodeView.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            stopNodeView.backgroundColor = backgroundColor
            _needUpdateStopNodeViewLayout()
        }
    }

    fileprivate func _needUpdateStopNodeViewLayout() {
        if self.bounds.size == .zero { return }
        if stopNodeView.bounds.size == .zero { return }

        var location = _stopNodeLocation
        if location.isNaN || location.isInfinite { location = 0 }
        _ = location // 与原实现一致: 计算 centerX 时仍用 _stopNodeLocation
        let centerX = _stopNodeLocation * containerView.bounds.size.width + expand
        let centerY = self.bounds.size.height * 0.5
        _stopNodeView?.center = CGPoint(x: centerX, y: centerY)
    }
}

// MARK: - Delegate

@objc(SJProgressSliderDelegate)
@MainActor
public protocol SJProgressSliderDelegate_Protocol: NSObjectProtocol {

    /// 开始滑动
    @objc(sliderWillBeginDragging:)
    optional func sliderWillBeginDragging(_ slider: SJProgressSlider)

    @objc(slider:valueDidChange:)
    optional func slider(_ slider: SJProgressSlider, valueDidChange value: CGFloat)

    /// 滑动完成
    @objc(sliderDidEndDragging:)
    optional func sliderDidEndDragging(_ slider: SJProgressSlider)

    @available(*, deprecated, message: "use `slider:valueDidChange:`")
    @objc(sliderDidDrag:)
    optional func sliderDidDrag(_ slider: SJProgressSlider)
}
