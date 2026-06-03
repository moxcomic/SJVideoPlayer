//
//  SJItemTags.swift
//  SJVideoPlayer
//
//  Created by BlueDancer on 2020/12/31.
//

// 同模块内 SJEdgeControlButtonItemTag 的 typealias 定义在
// Common/Utils/Adapters/Core/SJEdgeControlButtonItem.swift
// (typealias SJEdgeControlButtonItemTag = Int)，此处直接按名引用。
// 数值契约原样保留 (top 1000x / left-right 2000x / bottom 3000x / center 4000x)。

import Foundation

// MARK: - SJEdgeControlLayer

// top adapter items

/// 返回按钮
public let SJEdgeControlLayerTopItem_Back: SJEdgeControlButtonItemTag = 10000
/// 标题
public let SJEdgeControlLayerTopItem_Title: SJEdgeControlButtonItemTag = 10001
/// 画中画item
public let SJEdgeControlLayerTopItem_PictureInPicture: SJEdgeControlButtonItemTag = 10003
/// More
public let SJEdgeControlLayerTopItem_More: SJEdgeControlButtonItemTag = 10004

// left adapter items

/// 锁屏按钮
public let SJEdgeControlLayerLeftItem_Lock: SJEdgeControlButtonItemTag = 20000

// right adapter items

/// GIF/导出/截屏
public let SJEdgeControlLayerRightItem_Clips: SJEdgeControlButtonItemTag = 20001

// bottom adapter items

/// 播放按钮
public let SJEdgeControlLayerBottomItem_Play: SJEdgeControlButtonItemTag = 30000
/// 当前时间
public let SJEdgeControlLayerBottomItem_CurrentTime: SJEdgeControlButtonItemTag = 30001
/// 全部时长
public let SJEdgeControlLayerBottomItem_DurationTime: SJEdgeControlButtonItemTag = 30002
/// 时间分隔符(斜杠/)
public let SJEdgeControlLayerBottomItem_Separator: SJEdgeControlButtonItemTag = 30003
/// 播放进度条
public let SJEdgeControlLayerBottomItem_Progress: SJEdgeControlButtonItemTag = 30004
/// 全屏按钮
public let SJEdgeControlLayerBottomItem_Full: SJEdgeControlButtonItemTag = 30005
/// 实时直播
public let SJEdgeControlLayerBottomItem_LIVEText: SJEdgeControlButtonItemTag = 30006
/// 清晰度
public let SJEdgeControlLayerBottomItem_Definition: SJEdgeControlButtonItemTag = 30007

// center adapter items

/// 重播按钮
public let SJEdgeControlLayerCenterItem_Replay: SJEdgeControlButtonItemTag = 40000
