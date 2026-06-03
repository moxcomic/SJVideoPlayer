//
//  SJVideoPlayerClipsDefines.swift
//  SJVideoPlayerProject
//
//  Created by 畅三江 on 2018/4/12.
//  Copyright © 2018年 changsanjiang. All rights reserved.
//

import UIKit
import AVFoundation
import SJBaseVideoPlayer

/// 剪辑状态
///
/// 对应原 `NS_ENUM(NSUInteger, SJClipsStatus)`(下划线命名)。
@objc(SJClipsStatus)
public enum SJClipsStatus: UInt, Sendable {
    case unknown
    case recording
    case cancelled
    case paused
    case finished
}

/// 剪辑操作类型
///
/// 对应原 `NS_ENUM(NSUInteger, SJVideoPlayerClipsOperation)`(下划线命名)。
@objc(SJVideoPlayerClipsOperation)
public enum SJVideoPlayerClipsOperation: UInt, Sendable {
    case unknown
    case screenshot
    case export
    case gif
}

/// 剪辑结果上传状态
///
/// 对应原 `NS_ENUM(NSUInteger, SJClipsResultUploadState)`(无下划线命名)。
@objc(SJClipsResultUploadState)
public enum SJClipsResultUploadState: UInt, Sendable {
    case unknown
    case uploading
    case failed
    case successfully
    case cancelled
}

/// 剪辑导出状态
///
/// 对应原 `NS_ENUM(NSUInteger, SJClipsExportState)`(无下划线命名)。
@objc(SJClipsExportState)
public enum SJClipsExportState: UInt, Sendable {
    case unknown
    case exporting
    case failed
    case success
    case cancelled
}

///
/// 剪辑参数协议
///
/// 对应原 `@protocol SJVideoPlayerClipsParameters`。
/// 撞名: Clips/Core/Model 区存在同名类 SJVideoPlayerClipsParameters, 故协议加 `_Protocol` 后缀, 但仍以 @objc(SJVideoPlayerClipsParameters) 暴露原 ObjC 名。
@objc(SJVideoPlayerClipsParameters)
public protocol SJVideoPlayerClipsParameters_Protocol: NSObjectProtocol {
    // operation
    @objc var operation: SJVideoPlayerClipsOperation { get }
    @objc var range: CMTimeRange { get }

    // upload
    @objc var resultNeedUpload: Bool { get set }
    @objc weak var resultUploader: SJVideoPlayerClipsResultUpload? { get set }

    // album
    @objc var saveResultToAlbum: Bool { get set }
}

///
/// 剪辑结果协议
///
/// 对应原 `@protocol SJVideoPlayerClipsResult`(无同名类, 不加后缀)。
@objc(SJVideoPlayerClipsResult)
public protocol SJVideoPlayerClipsResult: NSObjectProtocol {
    @objc var operation: SJVideoPlayerClipsOperation { get }
    @objc var exportState: SJClipsExportState { get }
    @objc var uploadState: SJClipsResultUploadState { get }

    /// results
    @objc var thumbnailImage: UIImage? { get }
    /// screenshot or GIF
    @objc var image: UIImage? { get }
    @objc var fileURL: URL? { get }
    @objc var currentPlayAsset: SJVideoPlayerURLAsset? { get }
    @objc func data() -> Data?
}

///
/// 剪辑结果上传协议
///
/// 对应原 `@protocol SJVideoPlayerClipsResultUpload`(无同名类, 不加后缀)。
@objc(SJVideoPlayerClipsResultUpload)
public protocol SJVideoPlayerClipsResultUpload: NSObjectProtocol {
    @objc(upload:progress:success:failure:)
    func upload(_ result: SJVideoPlayerClipsResult,
                progress progressBlock: ((_ progress: Float) -> Void)?,
                success: (() -> Void)?,
                failure: ((_ error: Error) -> Void)?)

    @objc(cancelUpload:)
    func cancelUpload(_ result: SJVideoPlayerClipsResult)
}
