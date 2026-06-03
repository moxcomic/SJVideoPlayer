//
//  SJControlLayerIdentifiers.swift
//  SJVideoPlayer
//
//  Created by BlueDancer on 2020/12/31.
//

// 同模块内 SJControlLayerIdentifier 的 typealias 定义在
// Common/Interfaces/SJControlLayerDefines.swift (typealias SJControlLayerIdentifier = Int)，
// 此处直接按名引用。

import Foundation

/// 以下标识是默认存在的控制层标识
/// - 可以像下面这样扩展您的标识, 将相应的控制层加入到switcher(切换器)中, 通过switcher进行切换.
/// - SJControlLayerIdentifier YourControlLayerIdentifier;
/// - 当然, 也可以直接将已存在控制层, 替换成您的控制层.

/// 默认的边缘控制层
public let SJControlLayer_Edge: SJControlLayerIdentifier = Int.max - 1
/// 默认的剪辑层
public let SJControlLayer_Clips: SJControlLayerIdentifier = Int.max - 2
/// 默认的更多设置控制层
public let SJControlLayer_More: SJControlLayerIdentifier = Int.max - 3
/// 默认加载失败时显示的控制层
public let SJControlLayer_LoadFailed: SJControlLayerIdentifier = Int.max - 4
/// 默认加载失败时显示的控制层
public let SJControlLayer_NotReachableAndPlaybackStalled: SJControlLayerIdentifier = Int.max - 5
/// 默认的小浮窗控制层
public let SJControlLayer_FloatSmallView: SJControlLayerIdentifier = Int.max - 6
/// 默认的切换视频清晰度控制层
public let SJControlLayer_SwitchVideoDefinition: SJControlLayerIdentifier = Int.max - 7
