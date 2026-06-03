//
//  SJLoadingView.swift
//  Pods
//
//  Created by 畅三江 on 2019/11/27.
//
//  由 SJLoadingView.h / SJLoadingView.m 合并转换为 Swift。
//

import UIKit
import SnapKit

// MARK: - 私有: 旋转加载动画视图
//
// 原 ObjC 私有类 `_SJRotatingAnimationView`(UIView 子类, CAAnimationDelegate)。
// 不进公共类型表, 仅库内私有使用。
@MainActor
final class _SJRotatingAnimationView: UIView, CAAnimationDelegate {

    /// 线条颜色, 默认 whiteColor(null_resettable: 置 nil 回落白色)。
    var lineColor: UIColor? {
        get {
            if let c = _lineColor { return c }
            return UIColor.white
        }
        set {
            let color = newValue ?? UIColor.white
            _lineColor = color
            gradientLayer.colors = [
                UIColor(white: 0.001, alpha: 0.001).cgColor,
                color.withAlphaComponent(0.25).cgColor,
                color.cgColor
            ]
        }
    }
    private var _lineColor: UIColor?

    /// 旋转速度(秒/圈), 默认 1。
    var speed: Double = 1

    /// 动画状态。
    private(set) var isAnimating: Bool = false

    private var lineWidth: CGFloat = 0 {
        didSet {
            shapeLayer.lineWidth = lineWidth
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(gradientLayer)
        gradientLayer.mask = shapeLayer
        alpha = 0.001
        speed = 1
        lineWidth = 2
        lineColor = UIColor.white
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.addSublayer(gradientLayer)
        gradientLayer.mask = shapeLayer
        alpha = 0.001
        speed = 1
        lineWidth = 2
        lineColor = UIColor.white
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 38, height: 38)
    }

    func start() {
        if isAnimating { return }
        isAnimating = true
        alpha = 1
        let rotationAnim = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnim.toValue = NSNumber(value: Float(2 * Double.pi))
        rotationAnim.duration = speed
        rotationAnim.repeatCount = Float(CGFloat.greatestFiniteMagnitude)
        rotationAnim.isRemovedOnCompletion = false
        gradientLayer.add(rotationAnim, forKey: "rotation")
    }

    func stop() {
        if !isAnimating { return }
        isAnimating = false
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            self?.alpha = 0.001
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            if !self.isAnimating {
                self.gradientLayer.removeAnimation(forKey: "rotation")
            }
        })
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = min(bounds.size.width, bounds.size.height)
        let height = width
        gradientLayer.bounds = CGRect(x: 0, y: 0, width: width, height: height)
        gradientLayer.position = CGPoint(x: bounds.size.width * 0.5, y: bounds.size.height * 0.5)
        shapeLayer.position = CGPoint(x: lineWidth, y: lineWidth)
        shapeLayer.path = UIBezierPath(
            arcCenter: CGPoint(x: width * 0.5 - lineWidth, y: height * 0.5 - lineWidth),
            radius: (width - lineWidth) * 0.5,
            startAngle: 0,
            endAngle: CGFloat.pi * 2,
            clockwise: true
        ).cgPath
    }

    // MARK: 懒加载图层

    private lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 1, y: 1)
        layer.endPoint = CGPoint(x: 0, y: 0)
        layer.locations = [0, 0.3, 0.5, 1]
        return layer
    }()

    private lazy var shapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.blue.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeStart = 0.15
        layer.strokeEnd = 0.8
        layer.lineCap = .round
        return layer
    }()
}

// MARK: - SJLoadingView
//
// 加载指示视图; start/stop 经延迟 0.1s 防抖(原 performSelector:afterDelay: +
// cancelPreviousPerformRequestsWithTarget: → 可取消的 DispatchWorkItem)。
@objc(SJLoadingView)
@MainActor
open class SJLoadingView: UIView, SJLoadingView_Protocol {

    @objc(isAnimating) public var animating: Bool {
        return animationView.isAnimating
    }

    @objc public var showsNetworkSpeed: Bool {
        get { return !speedLabel.isHidden }
        set { speedLabel.isHidden = !newValue }
    }

    @objc public var networkSpeedStr: NSAttributedString? {
        get { return speedLabel.attributedText }
        set { speedLabel.attributedText = newValue }
    }

    private let speedLabel: UILabel = UILabel(frame: .zero)
    private let animationView: _SJRotatingAnimationView = _SJRotatingAnimationView(frame: .zero)

    /// 延迟/防抖任务(可取消)。
    private var pendingWorkItem: DispatchWorkItem?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        _setupView()
        _updateSettings()
        NotificationCenter.default.addObserver(self, selector: #selector(_updateSettings), name: SJVideoPlayerConfigurationsDidUpdateNotification, object: nil)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _setupView()
        _updateSettings()
        NotificationCenter.default.addObserver(self, selector: #selector(_updateSettings), name: SJVideoPlayerConfigurationsDidUpdateNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc public func start() {
        pendingWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?._start()
        }
        pendingWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: work)
    }

    @objc public func stop() {
        pendingWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?._stop()
        }
        pendingWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: work)
    }

    // MARK: -

    private func _start() {
        if animationView.isAnimating { return }
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            self.animationView.start()
            self.alpha = 1
        }
    }

    private func _stop() {
        if !animationView.isAnimating { return }
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            self.animationView.stop()
            self.alpha = 0.001
        }
    }

    private func _setupView() {
        clipsToBounds = false
        isUserInteractionEnabled = false

        addSubview(animationView)
        addSubview(speedLabel)

        animationView.snp.makeConstraints { make in
            make.edges.equalToSuperview().offset(0)
        }

        speedLabel.snp.makeConstraints { make in
            make.top.equalTo(self.animationView.snp.bottom).offset(8)
            make.centerX.equalToSuperview().offset(0)
            make.width.equalToSuperview().offset(80)
        }

        alpha = 0.001
    }

    @objc private func _updateSettings() {
        animationView.lineColor = SJVideoPlayerConfigurations.shared.resources.loadingLineColor
    }
}
