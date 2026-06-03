//
//  SJDraggingObservation.swift
//  Pods
//
//  Created by 畅三江 on 2019/11/27.
//
//  Swift 6.3 转换: SJDraggingObservation.h / .m 合并.
//  撞名(协议 + 同名类): 协议加 _Protocol 后缀, 类保持原名.
//

import Foundation

/// 拖动观察者默认实现.
///
/// 纯数据类: 持有四个拖动阶段回调 block, 遵循 `SJDraggingObservation_Protocol`(原协议名).
@objc(SJDraggingObservation)
public final class SJDraggingObservation: NSObject, SJDraggingObservation_Protocol {

    ///
    /// 拖动开始的回调
    ///
    @objc public var willBeginDraggingExeBlock: ((TimeInterval) -> Void)?

    ///
    /// 拖动中的回调
    ///
    @objc public var didMoveExeBlock: ((TimeInterval) -> Void)?

    ///
    /// 将要结束的回调
    ///
    @objc public var willEndDraggingExeBlock: ((TimeInterval) -> Void)?

    ///
    /// 结束了的回调
    ///
    @objc public var didEndDraggingExeBlock: ((TimeInterval) -> Void)?

    @objc public override init() {
        super.init()
    }
}
