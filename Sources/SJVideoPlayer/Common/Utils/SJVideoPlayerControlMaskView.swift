//
//  SJVideoPlayerControlMaskView.swift
//  SJVideoPlayerProject
//
//  Created by 畅三江 on 2017/9/25.
//  Copyright © 2017年 changsanjiang. All rights reserved.
//

import UIKit

/**
 style

 - bottom:  从上到下的颜色 浅->深
 - top:     从上到下的颜色 深->浅
 */
@objc(SJMaskStyle)
public enum SJMaskStyle: UInt {
    case bottom
    case top
}

@MainActor
@objc(SJVideoPlayerControlMaskView)
public class SJVideoPlayerControlMaskView: UIView {

    private(set) var style: SJMaskStyle = .bottom

    public override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    @objc(initWithStyle:)
    public init(style: SJMaskStyle) {
        super.init(frame: .zero)
        self.style = style
        guard let maskGradientLayer = self.layer as? CAGradientLayer else { return }
        switch style {
        case .top:
            maskGradientLayer.colors = [
                UIColor(white: 0, alpha: 0.8).cgColor,
                UIColor.clear.cgColor
            ]
        case .bottom:
            maskGradientLayer.colors = [
                UIColor.clear.cgColor,
                UIColor(white: 0, alpha: 0.8).cgColor
            ]
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc public func cleanColors() {
        guard let maskGradientLayer = self.layer as? CAGradientLayer else { return }
        maskGradientLayer.colors = nil
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
    }
}
