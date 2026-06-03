//
//  SJSpeedupPlaybackPopupView.swift
//  Pods
//
//  Created by BlueDancer on 2020/2/21.
//
//  由 SJSpeedupPlaybackPopupView.h / SJSpeedupPlaybackPopupView.m 合并转换为 Swift。
//

import UIKit
import SJUIKit
import SJBaseVideoPlayer

// MARK: - SJSpeedupPlaybackPopupView
//
// 长按倍速弹窗: 两个三角 CAShapeLayer + 一个 CATextLayer。
// 文案走本地化(longPressSpeedupPlayback), 富文本经 SJUIKit 构建。
@objc(SJSpeedupPlaybackPopupView)
@MainActor
open class SJSpeedupPlaybackPopupView: UIView, SJSpeedupPlaybackPopupView_Protocol {

    @objc public var rate: CGFloat = 0 {
        didSet {
            if rate != oldValue {
                let sources = SJVideoPlayerConfigurations.shared.resources
                let strings = SJVideoPlayerConfigurations.shared.localizedStrings
                let text = NSAttributedString.sj_UIKitText { make in
                    _ = make.append(String(format: "%.01fx", rate)).textColor(sources.speedupPlaybackRateTextColor ?? .white).font(sources.speedupPlaybackRateTextFont ?? .systemFont(ofSize: 12))
                    let prompt = strings.longPressSpeedupPlayback; if prompt.count != 0 {
                        _ = make.append(" ")
                        _ = make.append(prompt).font(sources.speedupPlaybackTextFont ?? .systemFont(ofSize: 12)).textColor(sources.speedupPlaybackTextColor ?? .white)
                    }
                }

                textLayer.string = text
                let size = text.sj_textSize()
                textLayer.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                invalidateIntrinsicContentSize()
            }
        }
    }

    @objc(isAnimating) public private(set) var animating: Bool = false

    private var triangles: [CAShapeLayer] = []
    private let textLayer: CATextLayer = CATextLayer()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        _setupViews()
        NotificationCenter.default.addObserver(self, selector: #selector(_updateSettings), name: SJVideoPlayerConfigurationsDidUpdateNotification, object: nil)
        _updateSettings()
        rate = 2.0
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _setupViews()
        NotificationCenter.default.addObserver(self, selector: #selector(_updateSettings), name: SJVideoPlayerConfigurationsDidUpdateNotification, object: nil)
        _updateSettings()
        rate = 2.0
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    open override var intrinsicContentSize: CGSize {
        let size = triangles.first?.bounds.size.width ?? 0
        let left: CGFloat = 8
        let lineWidth = triangles.first?.lineWidth ?? 0
        return CGSize(width: ceil(left + lineWidth * 2 + size * 2 + 2 + textLayer.bounds.size.width + left), height: 28)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        let bounds = self.bounds
        layer.cornerRadius = bounds.size.height * 0.5
        let left: CGFloat = 8
        let lineWidth = triangles.first?.lineWidth ?? 0
        guard let first = triangles.first, let last = triangles.last else { return }
        first.frame = CGRect(x: left + lineWidth, y: (bounds.size.height - first.bounds.size.height) * 0.5, width: first.bounds.size.width, height: first.bounds.size.height)
        last.frame = CGRect(x: first.frame.maxX, y: (bounds.size.height - last.bounds.size.height) * 0.5, width: last.bounds.size.width, height: last.bounds.size.height)
        textLayer.frame = CGRect(x: last.frame.maxX + lineWidth + 2, y: (bounds.size.height - textLayer.bounds.size.height) * 0.5, width: textLayer.bounds.size.width, height: textLayer.bounds.size.height)
    }

    private func _setupViews() {
        animating = false
        backgroundColor = UIColor(white: 0, alpha: 0.8)
        alpha = 0.001
        isUserInteractionEnabled = false

        var m: [CAShapeLayer] = []
        let size: CGFloat = 6
        let bounds = CGRect(x: 0, y: 0, width: size, height: size)
        for _ in 0..<2 {
            let triangleLayer = CAShapeLayer()
            triangleLayer.bounds = bounds

            let angle: CGFloat = 60 * CGFloat.pi / 180.0
            let a = size * sin(angle)
            let b = size * cos(angle)
            let start = CGPoint(x: 0, y: 0)
            let middle = CGPoint(x: a, y: b)
            let end = CGPoint(x: 0, y: size)

            let bezierPath = UIBezierPath()
            bezierPath.move(to: start)
            bezierPath.addLine(to: middle)
            bezierPath.addLine(to: end)
            bezierPath.close()
            triangleLayer.path = bezierPath.cgPath
            triangleLayer.lineJoin = .round
            triangleLayer.lineWidth = size * 0.5
            layer.addSublayer(triangleLayer)
            m.append(triangleLayer)

            triangleLayer.opacity = 1
        }
        triangles = m

        textLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(textLayer)
    }

    @objc public func show() {
        animating = true
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.alpha = 1
        }
        _showAnimations()
    }

    @objc public func hidden() {
        animating = false
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.alpha = 0.001
        }
    }

    private func _showAnimations() {
        _recursiveAnimation(beginIndex: 0)
    }

    private func _recursiveAnimation(beginIndex idx: Int) {
        if animating == false { return }
        if idx < 0 { return }

        let layer = triangles[idx]
        layer.addAnimation(_opacityAnimation(duration: 0.3), stopHandler: { [weak self] _, _ in
            guard let self = self else { return }
            self._recursiveAnimation(beginIndex: idx > 0 ? (idx - 1) : (self.triangles.count - 1))
        })
    }

    private func _opacityAnimation(duration: TimeInterval) -> CAKeyframeAnimation {
        let anima = CAKeyframeAnimation(keyPath: "opacity")
        anima.values = [1, 0.1, 1]
        anima.duration = duration
        return anima
    }

    @objc private func _updateSettings() {
        let sources = SJVideoPlayerConfigurations.shared.resources
        for layer in triangles {
            let color = sources.speedupPlaybackTriangleColor?.cgColor
            layer.strokeColor = color
            layer.fillColor = color
        }
    }
}
