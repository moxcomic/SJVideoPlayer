//
//  SJClipsResultShareItemsContainerView.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2019/1/20.
//  Copyright © 2019 畅三江. All rights reserved.
//

import UIKit
import SnapKit
import SJUIKit

/// 结果分享项的横向容器视图: 根据 shareItems 动态创建按钮并横向排布.
@objc(SJClipsResultShareItemsContainerView)
@MainActor
public class SJClipsResultShareItemsContainerView: UIView {

    @objc public var shareItems: [SJClipsResultShareItem]? {
        get { _shareItems }
        set { setShareItems(newValue) }
    }
    private var _shareItems: [SJClipsResultShareItem]?

    @objc public var clickedShareItemExeBlock: ((SJClipsResultShareItemsContainerView, SJClipsResultShareItem) -> Void)?

    @objc private func clickedBtn(_ btn: UIButton) {
        guard let items = _shareItems, btn.tag >= 0, btn.tag < items.count else { return }
        clickedShareItemExeBlock?(self, items[btn.tag])
    }

    private func setShareItems(_ shareItems: [SJClipsResultShareItem]?) {
        if (shareItems as NSArray?) === (_shareItems as NSArray?) { return }
        _shareItems = shareItems
        guard let shareItems = shareItems else { return }
        for (idx, obj) in shareItems.enumerated() {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.numberOfLines = 0
            btn.setAttributedTitle(NSAttributedString.sj_UIKitText { make in
                _ = make.lineSpacing(8)
                    .alignment(.center)
                    .font(UIFont.systemFont(ofSize: 10))
                    .textColor(UIColor.white)

                _ = make.appendImage { attach in
                    attach.image = obj.image
                    attach.bounds = CGRect(x: 0, y: 0, width: 40, height: 40)
                }

                _ = make.append("\n")
                _ = make.append(obj.title)
            }, for: .normal)
            btn.tag = idx
            btn.addTarget(self, action: #selector(clickedBtn(_:)), for: .touchUpInside)

            addSubview(btn)
            if idx == 0 {
                btn.snp.makeConstraints { make in
                    make.left.equalTo(self)
                    make.top.bottom.equalToSuperview().offset(0)
                }
            } else if idx != shareItems.count - 1 {
                let beforeBtn = subviews[idx - 1]
                btn.snp.makeConstraints { make in
                    make.left.equalTo(beforeBtn.snp.right).offset(20)
                    make.top.bottom.equalTo(beforeBtn)
                }
            } else {
                let beforeBtn = subviews[idx - 1]
                btn.snp.makeConstraints { make in
                    make.left.equalTo(beforeBtn.snp.right).offset(20)
                    make.top.bottom.equalTo(beforeBtn)
                    make.right.equalToSuperview().offset(0)
                }
            }
        }
    }
}
