//
//  SJClipsBackButton.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2019/1/20.
//  Copyright © 2019 畅三江. All rights reserved.
//

import UIKit

/// 剪辑模块的返回按钮, 使用 SJClipsCommonViewLayer 作为底层图层.
@objc(SJClipsBackButton)
@MainActor
public class SJClipsBackButton: UIButton {

    public override class var layerClass: AnyClass {
        return SJClipsCommonViewLayer.self
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel?.font = UIFont.systemFont(ofSize: 12)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
