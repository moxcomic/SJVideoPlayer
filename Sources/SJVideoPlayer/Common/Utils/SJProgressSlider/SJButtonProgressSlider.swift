//
//  SJButtonProgressSlider.swift
//
//  Created by 畅三江 on 2017/11/20.
//  Copyright © 2017年 changsanjiang. All rights reserved.
//

import UIKit
import SnapKit

/// 两个按钮, 分别在左边和右边.
/// 你可以设置父类中的 `spacing`, 来调整他们之间的间距.
@objc(SJButtonProgressSlider)
@MainActor
open class SJButtonProgressSlider: SJCommonProgressSlider {

    @objc public private(set) lazy var leftBtn: UIButton = _createButton()
    @objc public private(set) lazy var rightBtn: UIButton = _createButton()

    @objc public var leftText: String? {
        didSet {
            leftBtn.setTitle(leftText, for: .normal)
        }
    }

    @objc public var rightText: String? {
        didSet {
            rightBtn.setTitle(rightText, for: .normal)
        }
    }

    @objc public var titleColor: UIColor? {
        didSet {
            leftBtn.setTitleColor(titleColor, for: .normal)
            rightBtn.setTitleColor(titleColor, for: .normal)
        }
    }

    @objc public var font: UIFont? {
        didSet {
            leftBtn.titleLabel?.font = font
            rightBtn.titleLabel?.font = font
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        _buttonSetupView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _buttonSetupView()
    }

    private func _buttonSetupView() {
        leftContainerView.addSubview(leftBtn)
        rightContainerView.addSubview(rightBtn)

        leftBtn.snp.makeConstraints { make in
            make.center.equalTo(leftBtn.superview!)
        }

        rightBtn.snp.makeConstraints { make in
            make.center.equalTo(rightBtn.superview!)
        }
    }

    private func _createButton() -> UIButton {
        let btn = UIButton()
        btn.setTitleColor(.black, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12)
        btn.sizeToFit()
        return btn
    }
}
