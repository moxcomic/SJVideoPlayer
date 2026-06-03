//
//  SJClipsButtonContainerView.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2019/1/20.
//  Copyright © 2019 畅三江. All rights reserved.
//

import UIKit
import SnapKit

/// 包裹返回按钮的容器视图, 居中布局并转发点击回调.
@objc(SJClipsButtonContainerView)
@MainActor
public class SJClipsButtonContainerView: UIView {

    @objc public private(set) var button: SJClipsBackButton!

    @objc public var clickedBackButtonExeBlock: ((SJClipsButtonContainerView) -> Void)?

    @objc(initWithFrame:buttonSize:)
    public init(frame: CGRect, buttonSize size: CGSize) {
        super.init(frame: frame)
        let button = SJClipsBackButton(type: .custom)
        self.button = button
        addSubview(button)
        button.snp.makeConstraints { make in
            make.size.equalTo(size)
            make.center.equalToSuperview().offset(0)
        }
        button.addTarget(self, action: #selector(clickedBackBtn(_:)), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func clickedBackBtn(_ btn: UIButton) {
        clickedBackButtonExeBlock?(self)
    }
}
