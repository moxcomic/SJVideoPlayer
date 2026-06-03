//
//  SJEdgeControlButtonItemAdapterLayout.swift
//  Pods
//
//  Created by 畅三江 on 2019/12/9.
//
//  说明: 由 ObjC 文件 SJEdgeControlButtonItemAdapterLayout.h / .m 合并而来。
//  注意: 此布局计算器保留原手写 frame 计算逻辑, 不使用约束布局。
//

import Foundation
import UIKit

/// 布局方式 (原 NS_ENUM SJAdapterLayoutType)。
@objc(SJAdapterLayoutType)
public enum SJAdapterLayoutType: UInt {
    ///
    /// 垂直布局
    ///
    case verticalLayout

    ///
    /// 水平布局
    ///
    case horizontalLayout

    ///
    /// 帧布局(一层一层往上盖, 并居中显示)
    ///
    case frameLayout
}

@objc(SJEdgeControlButtonItemAdapterLayout)
@MainActor
public class SJEdgeControlButtonItemAdapterLayout: NSObject {

    private var _layoutAttributes: [SJEdgeControlButtonItemLayoutAttributes] = []

    @objc(initWithLayoutType:)
    public init(layoutType type: SJAdapterLayoutType) {
        _layoutType = type
        super.init()
    }

    private var _intrinsicContentSize: CGSize = .zero
    @objc public var intrinsicContentSize: CGSize {
        return _intrinsicContentSize
    }

    private var _layoutType: SJAdapterLayoutType
    @objc public var layoutType: SJAdapterLayoutType {
        get { _layoutType }
        set { _layoutType = newValue }
    }

    @objc public var items: [SJEdgeControlButtonItem]?

    @objc public var preferredMaxLayoutSize: CGSize = .zero

    @objc public var itemFillSizeForFrameLayout: CGSize = .zero

    @objc public func prepareLayout() {
        _intrinsicContentSize = .zero
        _layoutAttributes.removeAll()

        switch _layoutType {
        case .verticalLayout:
            _prepareLayoutVertical()
        case .horizontalLayout:
            _prepareLayoutHorizontal()
        case .frameLayout:
            _prepareLayoutFrame()
        }
    }

    @objc public func layoutAttributesForItems() -> [SJEdgeControlButtonItemLayoutAttributes]? {
        return !_layoutAttributes.isEmpty ? _layoutAttributes : nil
    }

    @objc(layoutAttributesForItemAtIndex:)
    public func layoutAttributesForItem(at index: Int) -> SJEdgeControlButtonItemLayoutAttributes? {
        if index < _layoutAttributes.count && index >= 0 {
            return _layoutAttributes[index]
        }
        return nil
    }

    // MARK: -

    private func _prepareLayoutHorizontal() {
        if preferredMaxLayoutSize == .zero {
            return
        }

        let items = self.items ?? []
        var content_w: CGFloat = 0                    // 内容宽度
        var bounds_arr = [CGRect](repeating: .zero, count: items.count)  // 所有内容的bounds
        var fillIndexes: [Int] = []
        let height = preferredMaxLayoutSize.height
        for i in 0..<items.count {
            var width: CGFloat = 0
            let item = items[i]
            if item.fill {
                fillIndexes.append(i)
            } else if item.hidden {
                // 隐藏
            } else if item.size != 0 {
                width = item.size
            } else if item.placeholderType == ._49x49 {
                width = height
            } else if let customView = item.customView {
                if item.placeholderType == ._49xAutoresizing {
                    width = _autoresizing(for: customView, maxSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)).width
                } else {
                    width = customView.frame.size.width
                }
            } else if let title = item.title, title.length != 0 {
                width = _size(for: title, width: CGFloat.greatestFiniteMagnitude, height: height).width
            } else if item.image != nil {
                width = height
            }

            let bounds = CGRect(origin: .zero, size: CGSize(width: width, height: height))
            content_w += item.insets.front + bounds.size.width + item.insets.rear
            bounds_arr[i] = bounds
        }

        // 填充剩余空间
        if !fillIndexes.isEmpty {
            let max_w = preferredMaxLayoutSize.width
            let remanentW = max_w - content_w
            let itemW = remanentW / CGFloat(fillIndexes.count)
            for idx in fillIndexes {
                bounds_arr[idx] = CGRect(origin: .zero, size: CGSize(width: itemW, height: height))
            }
        }

        // create `LayoutAttributes`
        var current_x: CGFloat = 0
        for index in 0..<items.count {
            let item = items[index]
            current_x += item.insets.front
            let attrs = SJEdgeControlButtonItemLayoutAttributes.layoutAttributes(forItemWithIndex: index)
            attrs.frame = CGRect(origin: CGPoint(x: current_x, y: 0), size: bounds_arr[index].size)
            _layoutAttributes.append(attrs)
            current_x += bounds_arr[index].size.width + item.insets.rear
        }

        _intrinsicContentSize = CGSize(width: _layoutAttributes.last?.frame.maxX ?? 0,
                                       height: _layoutAttributes.last?.frame.maxY ?? 0)
    }

    private func _prepareLayoutVertical() {
        if preferredMaxLayoutSize == .zero {
            return
        }

        let items = self.items ?? []
        var content_h: CGFloat = 0                    // 内容高度
        var bounds_arr = [CGRect](repeating: .zero, count: items.count)  // 所有内容的bounds
        let width = preferredMaxLayoutSize.width
        var fillIndexes: [Int] = []
        for i in 0..<items.count {
            var height: CGFloat = 0
            let item = items[i]
            if item.fill {
                fillIndexes.append(i)
            } else if item.hidden {
                // 隐藏
            } else if item.size != 0 {
                height = item.size
            } else if item.placeholderType == ._49x49 {
                height = width
            } else if let customView = item.customView {
                if item.placeholderType == ._49xAutoresizing {
                    height = _autoresizing(for: customView, maxSize: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)).height
                } else {
                    height = customView.frame.size.height
                }
            } else if let title = item.title, title.length != 0 {
                height = _size(for: title, width: width, height: CGFloat.greatestFiniteMagnitude).height
            } else if item.image != nil {
                height = width
            }

            let bounds = CGRect(origin: .zero, size: CGSize(width: width, height: height))
            content_h += item.insets.front + bounds.size.height + item.insets.rear
            bounds_arr[i] = bounds
        }

        // 填充剩余空间
        let max_h = preferredMaxLayoutSize.height
        if !fillIndexes.isEmpty {
            let allFillItemsHeight = max_h - content_h
            let fillItemHeight = allFillItemsHeight / CGFloat(fillIndexes.count)
            for idx in fillIndexes {
                bounds_arr[idx] = CGRect(origin: .zero, size: CGSize(width: width, height: fillItemHeight))
            }
            if fillItemHeight > 0 { content_h = max_h }
        }

        var current_y: CGFloat = floor((max_h - content_h) * 0.5)
        for index in 0..<items.count {
            let item = items[index]
            current_y += item.insets.front
            let attrs = SJEdgeControlButtonItemLayoutAttributes.layoutAttributes(forItemWithIndex: index)
            attrs.frame = CGRect(origin: CGPoint(x: 0, y: current_y), size: bounds_arr[index].size)
            _layoutAttributes.append(attrs)
            current_y += bounds_arr[index].size.height + item.insets.rear
        }

        _intrinsicContentSize = CGSize(width: _layoutAttributes.last?.frame.maxX ?? 0,
                                       height: _layoutAttributes.last?.frame.maxY ?? 0)
    }

    private func _prepareLayoutFrame() {
        let items = self.items ?? []
        var maxContentSize: CGSize = .zero
        var bounds_arr = [CGRect](repeating: .zero, count: items.count)
        for i in 0..<items.count {
            var size: CGSize = .zero
            let item = items[i]
            if item.hidden {
                // 隐藏
            } else if item.fill {
                size = itemFillSizeForFrameLayout
            } else if item.isFrameLayout {
                if let customView = item.customView, customView.bounds.size != .zero {
                    size = customView.bounds.size
                } else if let customView = item.customView {
                    size = _autoresizing(for: customView, maxSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
                }
            } else if item.size != 0 {
                size = CGSize(width: item.size, height: item.size)
            } else if item.placeholderType == ._49x49 || item.image != nil {
                size = CGSize(width: 49, height: 49)
            } else if let title = item.title, title.length != 0 {
                size = _size(for: title, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            }

            let bounds = CGRect(origin: .zero, size: size)
            bounds_arr[i] = bounds
            if bounds.size.width > maxContentSize.width {
                maxContentSize.width = bounds.size.width
            }
            if bounds.size.height > maxContentSize.height {
                maxContentSize.height = bounds.size.height
            }
        }

        let center = CGPoint(x: maxContentSize.width * 0.5, y: maxContentSize.height * 0.5)
        for index in 0..<items.count {
            let bounds = bounds_arr[index]
            let attrs = SJEdgeControlButtonItemLayoutAttributes.layoutAttributes(forItemWithIndex: index)
            attrs.size = bounds.size
            attrs.center = center
            _layoutAttributes.append(attrs)
        }

        _intrinsicContentSize = maxContentSize
    }

    private func _size(for attrStr: NSAttributedString, width: Double, height: Double) -> CGSize {
        if attrStr.length == 0 { return .zero }
        var bounds = attrStr.boundingRect(with: CGSize(width: width, height: height),
                                          options: [.usesLineFragmentOrigin, .usesFontLeading],
                                          context: nil)
        bounds.size.width = ceil(bounds.size.width)
        bounds.size.height = ceil(bounds.size.height)
        return bounds.size
    }

    private func _autoresizing(for view: UIView, maxSize: CGSize) -> CGSize {
        var size = view.systemLayoutSizeFitting(maxSize)
        let maxWidth = preferredMaxLayoutSize.width
        let maxHeight = preferredMaxLayoutSize.height
        if maxWidth != 0 && size.width > maxWidth { size.width = maxWidth }
        if maxHeight != 0 && size.height > maxHeight { size.height = maxHeight }
        return size
    }
}

@objc(SJEdgeControlButtonItemLayoutAttributes)
@MainActor
public class SJEdgeControlButtonItemLayoutAttributes: NSObject {

    @objc(layoutAttributesForItemWithIndex:)
    public static func layoutAttributes(forItemWithIndex index: Int) -> SJEdgeControlButtonItemLayoutAttributes {
        let attrs = SJEdgeControlButtonItemLayoutAttributes()
        attrs.index = index
        return attrs
    }

    @objc public var index: Int = 0

    private var _frame: CGRect = .zero
    @objc public var frame: CGRect {
        get { _frame }
        set { _frame = newValue }
    }

    @objc public var size: CGSize {
        get { _frame.size }
        set { _frame.size = newValue }
    }

    @objc public var center: CGPoint {
        get {
            return CGPoint(x: _frame.origin.x + size.width * 0.5,
                           y: _frame.origin.y + size.height * 0.5)
        }
        set {
            let x = newValue.x - size.width * 0.5
            let y = newValue.y - size.height * 0.5
            _frame.origin = CGPoint(x: x, y: y)
        }
    }
}
