//
//  SJSpeedupPlaybackPopupViewDefines.swift
//  Pods
//
//  Created by BlueDancer on 2020/2/21.
//

import UIKit
import SJBaseVideoPlayer

///
/// 长按倍速播放弹窗协议
///
/// 对应原 `@protocol SJSpeedupPlaybackPopupView`。
/// 撞名: Implements 区存在同名类 SJSpeedupPlaybackPopupView, 故协议加 `_Protocol` 后缀, 但仍以 @objc(SJSpeedupPlaybackPopupView) 暴露原 ObjC 名。
@objc(SJSpeedupPlaybackPopupView)
@MainActor
public protocol SJSpeedupPlaybackPopupView_Protocol: NSObjectProtocol {
    @objc var rate: CGFloat { get set }

    @objc(isAnimating) var animating: Bool { get }
    @objc func show()
    @objc func hidden()

    @objc optional func layoutInRect(_ rect: CGRect, gestureState state: SJLongPressGestureRecognizerState, playbackRate rate: CGFloat)
}
