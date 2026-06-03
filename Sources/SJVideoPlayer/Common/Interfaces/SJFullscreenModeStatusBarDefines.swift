//
//  SJFullscreenModeStatusBarDefines.swift
//  Pods
//
//  Created by 畅三江 on 2019/12/11.
//

import UIKit
import SJBaseVideoPlayer

///
/// 全屏模式下模拟状态栏协议
///
/// 对应原 `@protocol SJFullscreenModeStatusBar`。
/// 撞名: Implements 区存在同名类 SJFullscreenModeStatusBar, 故协议加 `_Protocol` 后缀, 但仍以 @objc(SJFullscreenModeStatusBar) 暴露原 ObjC 名。
@available(iOS 11.0, *)
@objc(SJFullscreenModeStatusBar)
@MainActor
public protocol SJFullscreenModeStatusBar_Protocol: NSObjectProtocol {
    ///
    /// 网络连接类型(无网络, 蜂窝网络, Wi-Fi)
    ///
    @objc var networkStatus: SJNetworkStatus { get set }

    ///
    /// 系统当前时间
    ///
    @objc var date: Date? { get set }

    ///
    /// 电池状态
    ///
    @objc var batteryState: UIDevice.BatteryState { get set }

    ///
    /// 电量
    ///
    @objc var batteryLevel: Float { get set }
}
