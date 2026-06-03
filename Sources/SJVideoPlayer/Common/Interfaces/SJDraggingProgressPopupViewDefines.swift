//
//  SJDraggingProgressPopupViewDefines.swift
//  Pods
//
//  Created by 畅三江 on 2019/11/27.
//

import UIKit

/// 拖动进度预览弹窗样式
///
/// 对应原 `NS_ENUM(NSUInteger, SJDraggingProgressPopupViewStyle)`。
@objc(SJDraggingProgressPopupViewStyle)
public enum SJDraggingProgressPopupViewStyle: UInt, Sendable {
    case normal
    case fullscreen
    case fitOnScreen
}

///
/// 拖动进度预览弹窗协议
///
/// 对应原 `@protocol SJDraggingProgressPopupView`。
/// 撞名: Implements 区存在同名类 SJDraggingProgressPopupView, 故协议加 `_Protocol` 后缀, 但仍以 @objc(SJDraggingProgressPopupView) 暴露原 ObjC 名。
@objc(SJDraggingProgressPopupView)
@MainActor
public protocol SJDraggingProgressPopupView_Protocol: NSObjectProtocol {
    @objc var style: SJDraggingProgressPopupViewStyle { get set }
    /// 拖拽到的时间
    @objc var dragTime: TimeInterval { get set }
    /// 当前播放到的时间
    @objc var currentTime: TimeInterval { get set }
    /// 播放时长
    @objc var duration: TimeInterval { get set }

    ///
    /// 当需要显示预览时, 可以返回 NO, 管理类将会设置 previewImage
    ///
    @objc(isPreviewImageHidden) var previewImageHidden: Bool { get }
    @objc var previewImage: UIImage? { get set }
}
