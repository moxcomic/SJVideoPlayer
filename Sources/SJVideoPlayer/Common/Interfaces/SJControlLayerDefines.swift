//
//  SJControlLayerDefines.swift
//  Pods
//
//  Created by 畅三江 on 2018/6/1.
//  Copyright © 2018年 畅三江. All rights reserved.
//

import Foundation
import SJBaseVideoPlayer

/// 控制层标识符
///
/// 对应原 `typedef long SJControlLayerIdentifier;`。
/// 这是开放扩展点(各控制层标识用 LONG_MAX-n 之类的值), 故用 typealias = Int 而非封闭枚举。
public typealias SJControlLayerIdentifier = Int

///
/// 控制层协议
///
/// 对应原 `@protocol SJControlLayer`。
/// 组合跨库的数据源 / 代理协议, 以及本库的 restart / exit 协议; 协议体为空。
/// 所有控制层均遵循该协议。
///
/// 注: 撞名规则下本协议无同名类, 但 SJControlLayer 已经是一个组合协议名, 这里保留原名 @objc(SJControlLayer)。
@objc(SJControlLayer)
@MainActor
public protocol SJControlLayer:
    SJVideoPlayerControlLayerDataSource,
    SJVideoPlayerControlLayerDelegate,
    SJControlLayerRestartProtocol,
    SJControlLayerExitProtocol
{
}

///
/// 启用控制层协议
///
///     切换器(switcher)切换控制层时, 该方法将会被调用
///
/// 注: 原名已带 Protocol 后缀, 不再追加 _Protocol。
@objc(SJControlLayerRestartProtocol)
@MainActor
public protocol SJControlLayerRestartProtocol: NSObjectProtocol {
    /// 是否已重新启用
    @objc var restarted: Bool { get }
    @objc func restartControlLayer()
}

///
/// 退出控制层
///
///     切换器(switcher)切换控制层时, 该方法将会被调用
///
/// 注: 原名已带 Protocol 后缀, 不再追加 _Protocol。
@objc(SJControlLayerExitProtocol)
@MainActor
public protocol SJControlLayerExitProtocol: NSObjectProtocol {
    @objc func exitControlLayer()
}
