//
//  SJCommonProgressSlider.swift
//  SJProgressSlider
//
//  Created by 畅三江 on 2017/11/20.
//  Copyright © 2017年 changsanjiang. All rights reserved.
//

import UIKit
import SnapKit

/// 两个视图, 分别在左边和右边.
/// 你可以设置 `spacing`, 来调整他们之间的间距.
@objc(SJCommonProgressSlider)
@MainActor
open class SJCommonProgressSlider: UIView {

    // default is 4.
    @objc public var spacing: Float = 4 {
        didSet {
            slider.snp.updateConstraints { make in
                make.leading.equalTo(leftContainerView.snp.trailing).offset(spacing)
                make.trailing.equalTo(rightContainerView.snp.leading).offset(-spacing)
            }
        }
    }

    @objc public private(set) lazy var leftContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    @objc public private(set) lazy var slider: SJProgressSlider = SJProgressSlider()

    @objc public private(set) lazy var rightContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    private lazy var containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        _c_setupView()
        self.spacing = 4
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _c_setupView()
        self.spacing = 4
    }

    private func _c_setupView() {
        addSubview(containerView)
        containerView.addSubview(leftContainerView)
        containerView.addSubview(slider)
        containerView.addSubview(rightContainerView)

        containerView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        leftContainerView.snp.makeConstraints { make in
            make.top.leading.bottom.equalTo(leftContainerView.superview!)
            make.width.equalTo(leftContainerView.snp.height).priority(.low)
        }

        slider.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().offset(0)
        }

        rightContainerView.snp.makeConstraints { make in
            make.top.trailing.bottom.equalTo(rightContainerView.superview!)
            make.width.equalTo(rightContainerView.snp.height).priority(.low)
        }
    }
}
