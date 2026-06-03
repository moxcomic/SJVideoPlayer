//
//  SJVideoPlayerClipsConfig.swift
//  SJVideoPlayerProject
//
//  Created by 畅三江 on 2018/4/12.
//  Copyright © 2018年 changsanjiang. All rights reserved.
//

import Foundation
import SJBaseVideoPlayer

/// 剪辑配置(开关 / 分享项 / 回调 / 上传器)。
///
/// 纯模型, 不标 @MainActor。
@objc(SJVideoPlayerClipsConfig)
public class SJVideoPlayerClipsConfig: NSObject {

    /// If return YES, Start operation [GIF/Export/Screenshot]
    /// The default is YES if this block is nil.
    ///
    /// 返回YES, 则开始操作[GIF/Export/Screenshot]
    /// 如果这个block为空, 将默认为YES
    @objc public var shouldStart: ((_ videoPlayer: SJBaseVideoPlayer, _ selectedOperation: SJVideoPlayerClipsOperation) -> Bool)?

    /// result View showed share items.
    @objc public var resultShareItems: [SJClipsResultShareItem]?

    /// clicked share item call it.
    @objc public var clickedResultShareItemExeBlock: ((_ player: SJBaseVideoPlayer, _ item: SJClipsResultShareItem, _ result: any SJVideoPlayerClipsResult) -> Void)?

    /// Exported video or whether the image needs to be uploaded.
    ///
    /// 导出来的视频或图片是否需要上传
    /// default is NO
    @objc public var resultNeedUpload: Bool = false

    @objc public weak var resultUploader: (any SJVideoPlayerClipsResultUpload)?

    @objc public var disableScreenshot: Bool = false   // default is NO
    @objc public var disableRecord: Bool = false       // default is NO
    @objc public var disableGIF: Bool = false          // default is NO

    /// 导出成功后, 保存到相册
    @objc public var saveResultToAlbum: Bool = false   // default is NO

    @objc public override init() {
        super.init()
    }

    /// 逐字段拷贝其它配置。
    @objc(config:)
    public func config(_ otherConfig: SJVideoPlayerClipsConfig) {
        self.shouldStart = otherConfig.shouldStart
        self.resultShareItems = otherConfig.resultShareItems
        self.clickedResultShareItemExeBlock = otherConfig.clickedResultShareItemExeBlock
        self.resultNeedUpload = otherConfig.resultNeedUpload
        self.resultUploader = otherConfig.resultUploader
        self.disableScreenshot = otherConfig.disableScreenshot
        self.disableRecord = otherConfig.disableRecord
        self.disableGIF = otherConfig.disableGIF
        self.saveResultToAlbum = otherConfig.saveResultToAlbum
    }
}
