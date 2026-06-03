//
//  SJEdgeControlButtonItemAdapter.swift
//  Pods
//
//  Created by 畅三江 on 2019/12/9.
//
//  说明: 由 ObjC 文件 SJEdgeControlButtonItemAdapter.h / .m 合并而来。
//

import UIKit
import SnapKit

/// 旧名别名 (原 typedef SJEdgeControlButtonItemAdapter SJEdgeControlLayerItemAdapter)。
public typealias SJEdgeControlLayerItemAdapter = SJEdgeControlButtonItemAdapter

@objc(SJEdgeControlButtonItemAdapter)
@MainActor
public class SJEdgeControlButtonItemAdapter: UIView {

    private var views: [SJEdgeControlButtonItemView] = []
    private var _items: [SJEdgeControlButtonItem] = []
    private let layout: SJEdgeControlButtonItemAdapterLayout

    @objc(initWithFrame:layoutType:)
    public init(frame: CGRect, layoutType type: SJAdapterLayoutType) {
        _layoutType = type
        layout = SJEdgeControlButtonItemAdapterLayout(layoutType: type)
        super.init(frame: frame)
    }

    @available(*, unavailable)
    public override init(frame: CGRect) {
        fatalError("init(frame:) is unavailable")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    ///
    /// 刷新
    ///
    @objc public func reload() {
        _reload()
    }

    @objc(updateContentForItemWithTag:)
    public func updateContent(forItemWithTag tag: SJEdgeControlButtonItemTag) {
        if let item = item(forTag: tag) {
            for view in views {
                if view.item === item {
                    view.reloadItemIfNeeded()
                    break
                }
            }
        }
    }

    ///
    /// 布局方式
    ///
    /// - 注意: 修改后, 记得调用刷新
    ///
    private var _layoutType: SJAdapterLayoutType
    @objc public var layoutType: SJAdapterLayoutType {
        get { _layoutType }
        set { _layoutType = newValue }
    }

    @objc public var itemFillSizeForFrameLayout: CGSize = .zero {
        didSet {
            if _layoutType == .frameLayout {
                reload()
            }
        }
    }

    ///
    /// 获取
    ///
    @objc(itemAtIndex:)
    public func item(at index: Int) -> SJEdgeControlButtonItem? {
        if index < _items.count && index >= 0 {
            return _items[index]
        }
        return nil
    }

    @objc(itemForTag:)
    public func item(forTag tag: SJEdgeControlButtonItemTag) -> SJEdgeControlButtonItem? {
        let index = indexOfItem(forTag: tag)
        return index != NSNotFound ? _items[index] : nil
    }

    @objc(indexOfItemForTag:)
    public func indexOfItem(forTag tag: SJEdgeControlButtonItemTag) -> Int {
        var index = NSNotFound
        for idx in 0..<_items.count {
            if _items[idx].tag == tag {
                index = idx
                break
            }
        }
        return index
    }

    @objc(indexOfItem:)
    public func indexOfItem(_ item: SJEdgeControlButtonItem) -> Int {
        if let idx = _items.firstIndex(where: { $0 === item }) {
            return idx
        }
        return NSNotFound
    }

    @objc(itemsWithRange:)
    public func items(withRange range: NSRange) -> [SJEdgeControlButtonItem]? {
        if NSMaxRange(range) <= _items.count {
            return Array(_items[range.location..<NSMaxRange(range)])
        }
        return nil
    }

    /// 此范围的items是否已隐藏
    @objc(isHiddenWithRange:)
    public func isHidden(withRange range: NSRange) -> Bool {
        if let items = items(withRange: range) {
            for item in items {
                if item.hidden == false {
                    return false
                }
            }
        }
        return true
    }

    /// 某个点是否在item中
    @objc(itemContainsPoint:)
    public func itemContains(_ point: CGPoint) -> Bool {
        return item(at: point) != nil
    }

    @objc(itemAtPoint:)
    public func item(at point: CGPoint) -> SJEdgeControlButtonItem? {
        if let attributes = layout.layoutAttributesForItems() {
            for attr in attributes {
                if attr.frame.contains(point) {
                    if let item = item(at: attr.index), item.hidden == false, item.alpha > 0.01 {
                        return item
                    }
                }
            }
        }
        return nil
    }

    @objc(containsItem:)
    public func contains(_ item: SJEdgeControlButtonItem?) -> Bool {
        guard let item = item else { return false }
        return _items.contains(where: { $0 === item })
    }

    ///
    /// 添加
    ///
    /// - 注意: 添加后, 记得调用刷新
    ///
    @objc(addItem:)
    public func addItem(_ item: SJEdgeControlButtonItem) {
        _items.append(item)
    }

    @objc(addItemsFromArray:)
    public func addItems(from items: [SJEdgeControlButtonItem]) {
        _items.append(contentsOf: items)
    }

    @objc(insertItem:atIndex:)
    public func insertItem(_ item: SJEdgeControlButtonItem, at index: Int) {
        var index = index
        if index >= _items.count { index = _items.count }
        else if index < 0 { index = 0 }
        _items.insert(item, at: index)
    }

    @objc(insertItem:frontItem:)
    public func insertItem(_ item: SJEdgeControlButtonItem, frontItem tag: SJEdgeControlButtonItemTag) {
        insertItem(item, at: indexOfItem(forTag: tag) + 1)
    }

    @objc(insertItem:rearItem:)
    public func insertItem(_ item: SJEdgeControlButtonItem, rearItem tag: SJEdgeControlButtonItemTag) {
        insertItem(item, at: indexOfItem(forTag: tag))
    }

    ///
    /// 删除
    ///
    /// - 注意: 删除后, 记得调用刷新
    ///
    @objc(removeItemAtIndex:)
    public func removeItem(at index: Int) {
        if index < 0 { return }
        if index >= _items.count { return }
        _items.remove(at: index)
    }

    @objc(removeItemForTag:)
    public func removeItem(forTag tag: SJEdgeControlButtonItemTag) {
        removeItem(at: indexOfItem(forTag: tag))
    }

    @objc public func removeAllItems() {
        _items.removeAll()
    }

    ///
    /// 交换位置
    ///
    /// - 注意: 交换后, 记得调用刷新
    ///
    @objc(exchangeItemAtIndex:withItemAtIndex:)
    public func exchangeItem(at idx1: Int, withItemAt idx2: Int) {
        if idx1 == idx2 { return }
        if idx1 < 0 || idx1 >= _items.count { return }
        if idx2 < 0 || idx2 >= _items.count { return }
        _items.swapAt(idx1, idx2)
    }

    @objc(exchangeItemForTag:withItemForTag:)
    public func exchangeItem(forTag tag1: SJEdgeControlButtonItemTag, withItemForTag tag2: SJEdgeControlButtonItemTag) {
        exchangeItem(at: indexOfItem(forTag: tag1), withItemAt: indexOfItem(forTag: tag2))
    }

    ///
    /// 获取当前 item 对应视图
    ///
    @objc(viewForItemAtIndex:)
    public func viewForItem(at idx: Int) -> UIView? {
        if idx != NSNotFound {
            return views[idx]
        }
        return nil
    }

    @objc(viewForItemForTag:)
    public func viewForItem(forTag tag: SJEdgeControlButtonItemTag) -> UIView? {
        return viewForItem(at: indexOfItem(forTag: tag))
    }

    // MARK: -

    private func _reload() {
        let items = _items
        layout.layoutType = _layoutType
        layout.items = items
        layout.itemFillSizeForFrameLayout = itemFillSizeForFrameLayout
        layout.preferredMaxLayoutSize = bounds.size
        layout.prepareLayout()

        //
        // 移除多余的视图
        //
        if items.count < views.count {
            let range = items.count..<views.count
            let uselessViews = Array(views[range])
            for obj in uselessViews.reversed() {
                if obj.superview == self { obj.removeFromSuperview() }
            }
            views.removeSubrange(range)
        }
        //
        // 补充新增的视图
        //
        else if items.count > views.count {
            for _ in views.count..<items.count {
                let view = SJEdgeControlButtonItemView(frame: .zero)
                views.append(view)
                addSubview(view)
            }
        }

        //
        // 刷新视图
        //
        if let attributes = layout.layoutAttributesForItems() {
            for attr in attributes {
                let view = views[attr.index]
                view.item = items[attr.index]
                view.frame = attr.frame
                view.reloadItemIfNeeded()
            }
        }

        //
        // 填充size
        //
        if _layoutType == .frameLayout {
            if superview != nil && layout.intrinsicContentSize != bounds.size {
                let contentSize = layout.intrinsicContentSize
                snp.updateConstraints { make in
                    make.size.equalTo(contentSize).priority(.required)
                }
            }
        }
    }

    @objc public var numberOfItems: Int {
        return _items.count
    }

    // MARK: -

    public override func layoutSubviews() {
        super.layoutSubviews()
        if _layoutType != .frameLayout {
            if layout.preferredMaxLayoutSize != bounds.size {
                reload()
            }
        }
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let item = item(at: point) {
            let index = indexOfItem(item)
            if index != NSNotFound {
                let view = views[index]
                return view.point(inside: convert(point, to: view), with: event)
            }
        }
        return super.point(inside: point, with: event)
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let item = item(at: point) {
            let index = indexOfItem(item)
            if index != NSNotFound {
                let view = views[index]
                return view.hitTest(convert(point, to: view), with: event)
            }
        }
        return super.hitTest(point, with: event)
    }

    // MARK: -

    //
    // 以下为兼容老的adapter
    //
    @objc public var view: SJEdgeControlButtonItemAdapter {
        return self
    }

    @objc public var itemCount: Int {
        return numberOfItems
    }
}
