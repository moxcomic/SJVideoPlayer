//
//  SJScrollingTextMarqueeView.swift
//  SJVideoPlayer_Example
//
//  Created by 畅三江 on 2019/12/7.
//  Copyright © 2019 changsanjiang. All rights reserved.
//
//  由 SJScrollingTextMarqueeView.h / SJScrollingTextMarqueeView.m 合并转换为 Swift。
//

import UIKit
import SJUIKit
import SJBaseVideoPlayer

// MARK: - SJScrollingTextMarqueeView
//
// 双 label 跑马灯 + 渐变 fade mask。
// 用 SJBaseVideoPlayer 的几何扩展 sj_w/sj_h/sj_x, SJUIKit 的 sj_textSize()。
// 滚动启动用可取消的 DispatchWorkItem 重写(原 performSelector:afterDelay: +
// cancelPreviousPerformRequestsWithTarget:)。
@objc(SJScrollingTextMarqueeView)
@MainActor
open class SJScrollingTextMarqueeView: UIView, SJScrollingTextMarqueeView_Protocol {

    @objc public var attributedText: NSAttributedString? {
        get { return leftLabel.attributedText }
        set {
            if leftLabel.attributedText != newValue {
                leftLabel.attributedText = newValue
                leftLabel.sj_w = scrollEnabled ? (newValue?.sj_textSize().width ?? 0) : sj_w
                leftLabel.sj_h = sj_h
                if scrollEnabled { _reset() }
            }
        }
    }

    @objc public var margin: CGFloat = 28 {
        didSet {
            if margin != oldValue {
                if scrollEnabled { _reset() }
            }
        }
    }

    @objc(isScrolling) public private(set) var scrolling: Bool = false

    @objc(isScrollEnabled) public var scrollEnabled: Bool = true {
        didSet {
            if scrollEnabled != oldValue {
                _reset()
            }
        }
    }

    @objc(isCentered) public var centered: Bool = false

    private let contentView: UIView = UIView(frame: .zero)
    private let leftLabel: UILabel = UILabel(frame: .zero)
    private let rightLabel: UILabel = UILabel(frame: .zero)
    private var fadeMaskLayer: CAGradientLayer = CAGradientLayer()

    private var previousBounds: CGRect = .zero

    /// 延迟启动滚动的可取消任务。
    private var startAnimationWorkItem: DispatchWorkItem?
    /// 右侧 fade mask 切换的可取消任务。
    private var setRightFadeMaskWorkItem: DispatchWorkItem?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        _initialize()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _initialize()
    }

    private func _initialize() {
        margin = 28
        scrollEnabled = true
        clipsToBounds = true
        NotificationCenter.default.addObserver(self, selector: #selector(_reset), name: UIApplication.willEnterForegroundNotification, object: nil)
        _setupViews()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: -

    open override func layoutSubviews() {
        super.layoutSubviews()

        let bounds = self.bounds
        if !previousBounds.equalTo(bounds) {
            previousBounds = bounds
            fadeMaskLayer.frame = bounds
            leftLabel.sj_h = sj_h
            rightLabel.sj_h = sj_h
            contentView.sj_h = sj_h
            if !scrollEnabled { leftLabel.sj_w = bounds.size.width }
            _reset()
        }
    }

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        _reset()
    }

    // MARK: -

    private func _setupViews() {
        isUserInteractionEnabled = false

        addSubview(contentView)
        contentView.addSubview(leftLabel)
        contentView.addSubview(rightLabel)

        fadeMaskLayer = CAGradientLayer()
        fadeMaskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        fadeMaskLayer.endPoint = CGPoint(x: 1, y: 0.5)
        _setFadeMasks()
        layer.mask = fadeMaskLayer
    }

    private func _shouldScroll() -> Bool {
        return scrollEnabled && leftLabel.attributedText != nil && leftLabel.sj_w > sj_w && sj_h != 0
    }

    @objc private func _reset() {
        contentView.layer.removeAllAnimations()
        startAnimationWorkItem?.cancel()
        setRightFadeMaskWorkItem?.cancel()

        if _shouldScroll() {
            _prepareForAnimation()
            if window != nil {
                _startAnimationIfNeeded(afterDelay: 2)
            }
        } else {
            _prepareForNormalState()
        }
    }

    private func _prepareForAnimation() {
        _setRightFadeMask()

        if centered {
            leftLabel.sj_x = 0
        }

        rightLabel.isHidden = false
        rightLabel.attributedText = leftLabel.attributedText
        rightLabel.sj_x = leftLabel.sj_w + margin
        rightLabel.sj_w = leftLabel.sj_w

        contentView.sj_w = rightLabel.frame.maxX
    }

    private func _prepareForNormalState() {
        _removeFadeMasks()

        rightLabel.isHidden = true

        if centered {
            leftLabel.sj_x = sj_w * 0.5 - leftLabel.sj_w * 0.5
        }
    }

    private func _startAnimationIfNeeded(afterDelay seconds: TimeInterval) {
        if !_shouldScroll() { return }

        // - 静止2秒
        // - 2秒后开始滚动, 如此循环
        startAnimationWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?._startAnimation()
        }
        startAnimationWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }

    private func _startAnimation() {
        let pointDuration: CGFloat = 0.02
        let points = leftLabel.sj_w + margin
        let step1 = CABasicAnimation(keyPath: "transform")
        step1.fromValue = NSValue(caTransform3D: CATransform3DIdentity)
        step1.toValue = NSValue(caTransform3D: CATransform3DMakeTranslation(-points, 0, 0))
        step1.duration = points * pointDuration
        step1.repeatCount = 1
        _setFadeMasks()
        scrolling = true
        contentView.layer.addAnimation(step1, stopHandler: { [weak self] _, _ in
            guard let self = self else { return }
            self.scrolling = false
            self._startAnimationIfNeeded(afterDelay: 2)
        })

        let step2: TimeInterval = TimeInterval(leftLabel.sj_w * pointDuration)
        setRightFadeMaskWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?._setRightFadeMask()
        }
        setRightFadeMaskWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + step2, execute: work)
    }

    private func _setFadeMasks() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fadeMaskLayer.colors = [
            UIColor(white: 1, alpha: 0.05).cgColor,
            UIColor(white: 1, alpha: 1.0).cgColor,
            UIColor(white: 1, alpha: 1.0).cgColor,
            UIColor(white: 1, alpha: 0.05).cgColor
        ]
        fadeMaskLayer.locations = [0, 0.1, 0.9, 1]
        CATransaction.commit()
    }

    private func _setRightFadeMask() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fadeMaskLayer.colors = [
            UIColor(white: 1, alpha: 1.0).cgColor,
            UIColor(white: 1, alpha: 0.05).cgColor
        ]
        fadeMaskLayer.locations = [0.9, 1]
        CATransaction.commit()
    }

    private func _removeFadeMasks() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fadeMaskLayer.colors = [
            UIColor(white: 1, alpha: 1.0).cgColor,
            UIColor(white: 1, alpha: 1.0).cgColor
        ]
        fadeMaskLayer.locations = [0, 1]
        CATransaction.commit()
    }
}
