//
//  SJEdgeControlButtonItemView.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2018/10/19.
//  Copyright © 2018 畅三江. All rights reserved.
//
//  说明: 由 ObjC 文件 SJEdgeControlButtonItemView.h / .m 合并而来。
//

import UIKit

/// item 的 customView 容器视图 (原 .m 内私有类 _SJItemCustomViewContainerView)。
@MainActor
final class _SJItemCustomViewContainerView: UIView {

    var customView: UIView? {
        return subviews.first
    }

    func removeCustomView() {
        if let customView = customView {
            customView.removeFromSuperview()
        }
    }

    func addCustomView(_ customView: UIView) {
        if self.customView != customView {
            removeCustomView()
            customView.frame = bounds
            customView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(customView)
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view != self ? view : nil
    }
}

@objc(SJEdgeControlButtonItemView)
@MainActor
public class SJEdgeControlButtonItemView: UIControl {

    @objc public var item: SJEdgeControlButtonItem? {
        get { _item }
        set { _item = newValue }
    }
    private var _item: SJEdgeControlButtonItem?

    private var containerView: _SJItemCustomViewContainerView?
    private var itemImageView: UIImageView?
    private var itemTitleLabel: UILabel?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(performAction), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if super.point(inside: point, with: event) {
            return _shouldPerformAction()
        }
        return false
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.point(inside: point, with: event) {
            if let customView = _item?.customView, _item?.actions == nil {
                return customView.hitTest(convert(point, to: customView), with: event)
            }
            return self
        }
        return super.hitTest(point, with: event)
    }

    @objc public func performAction() {
        _item?.performActions()
    }

    @objc public func reloadItemIfNeeded() {
        alpha = _item?.alpha ?? 0

        ///
        /// 优先级
        ///
        /// 1. 自定义视图
        /// 2. 图片视图
        /// 3. 标签视图
        /// 4. 空白
        ///

        containerView?.isHidden = true
        itemImageView?.isHidden = true
        itemTitleLabel?.isHidden = true

        guard let item = _item, item.hidden == false else {
            // clean
            containerView?.removeCustomView()
            return
        }

        // 1.
        if let customView = item.customView {
            // show containerView
            if let containerView = containerView {
                containerView.isHidden = false
            } else {
                let containerView = _SJItemCustomViewContainerView(frame: bounds)
                containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                addSubview(containerView)
                self.containerView = containerView
            }

            // add customView
            containerView?.addCustomView(customView)
        }
        // 2.
        else if let image = item.image {
            // show itemImageView
            if let itemImageView = itemImageView {
                itemImageView.isHidden = false
            } else {
                let itemImageView = UIImageView(frame: bounds)
                itemImageView.contentMode = .center
                itemImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                addSubview(itemImageView)
                self.itemImageView = itemImageView
            }

            // set image
            if image != itemImageView?.image {
                itemImageView?.image = image
            }
        }
        // 3.
        else if let title = item.title {
            // show itemTitleLabel
            if let itemTitleLabel = itemTitleLabel {
                itemTitleLabel.isHidden = false
            } else {
                let itemTitleLabel = UILabel(frame: bounds)
                itemTitleLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                addSubview(itemTitleLabel)
                self.itemTitleLabel = itemTitleLabel
            }

            // set title
            if title != itemTitleLabel?.attributedText {
                itemTitleLabel?.attributedText = title
            }
            if item.numberOfLines != itemTitleLabel?.numberOfLines {
                itemTitleLabel?.numberOfLines = item.numberOfLines
            }
        }
        // 4.
        // else
    }

    // MARK: -

    private func _shouldPerformAction() -> Bool {
        guard let item = _item else {
            return false
        }

        if item.hidden == true || item.alpha < 0.01 {
            return false
        }

        if item.customView == nil && item.actions == nil {
            return false
        }

        return true
    }
}
