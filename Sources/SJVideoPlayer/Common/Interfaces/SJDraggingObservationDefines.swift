//
//  SJDraggingObservationDefines.swift
//  Pods
//
//  Created by 畅三江 on 2019/11/27.
//

import Foundation

///
/// 拖动观察者协议
///
/// 对应原 `@protocol SJDraggingObservation`。
/// 撞名: Implements 区存在同名类 SJDraggingObservation, 故协议加 `_Protocol` 后缀, 但仍以 @objc(SJDraggingObservation) 暴露原 ObjC 名。
@objc(SJDraggingObservation)
public protocol SJDraggingObservation_Protocol: NSObjectProtocol {
    ///
    /// 拖动开始的回调
    ///
    @objc var willBeginDraggingExeBlock: ((_ time: TimeInterval) -> Void)? { get set }

    ///
    /// 拖动中的回调
    ///
    @objc var didMoveExeBlock: ((_ time: TimeInterval) -> Void)? { get set }

    ///
    /// 将要结束的回调
    ///
    @objc var willEndDraggingExeBlock: ((_ time: TimeInterval) -> Void)? { get set }

    ///
    /// 结束了的回调
    ///
    @objc var didEndDraggingExeBlock: ((_ time: TimeInterval) -> Void)? { get set }
}
