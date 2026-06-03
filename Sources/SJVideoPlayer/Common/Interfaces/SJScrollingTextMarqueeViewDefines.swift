//
//  SJScrollingTextMarqueeViewDefines.swift
//  Pods
//
//  Created by 畅三江 on 2019/12/7.
//

import UIKit

///
/// 滚动标题(跑马灯)协议
///
/// 对应原 `@protocol SJScrollingTextMarqueeView`。
/// 撞名: Implements 区存在同名类 SJScrollingTextMarqueeView, 故协议加 `_Protocol` 后缀, 但仍以 @objc(SJScrollingTextMarqueeView) 暴露原 ObjC 名。
@objc(SJScrollingTextMarqueeView)
@MainActor
public protocol SJScrollingTextMarqueeView_Protocol: NSObjectProtocol {
    @objc var attributedText: NSAttributedString? { get set }
    @objc var margin: CGFloat { get set }

    @objc(isScrolling) var scrolling: Bool { get }
    /// 默认值为 YES
    @objc(isScrollEnabled) var scrollEnabled: Bool { get set }
    /// 默认值为 NO。标题太短无法滚动时, 是否居中显示
    @objc(isCentered) var centered: Bool { get set }
}
