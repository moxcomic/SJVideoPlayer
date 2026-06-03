//
//  SJVideoPlayerClipsGeneratedResult.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2019/1/20.
//  Copyright © 2019 畅三江. All rights reserved.
//

import UIKit
import Foundation
import SJBaseVideoPlayer

/// 剪辑生成结果。实现 SJVideoPlayerClipsResult; setter 触发回调(伪 KVO → didSet)。
///
/// 纯模型, 不标 @MainActor。
@objc(SJVideoPlayerClipsGeneratedResult)
public class SJVideoPlayerClipsGeneratedResult: NSObject, SJVideoPlayerClipsResult {

    @objc public var operation: SJVideoPlayerClipsOperation = .unknown

    @objc public var exportState: SJClipsExportState = .unknown {
        didSet {
            // 与原实现一致: 值未变化时不回调
            if exportState == oldValue { return }
            exportStateDidChangeExeBlock?(self)
        }
    }

    @objc public var exportProgress: Float = 0 {
        didSet {
            exportProgressDidChangeExeBlock?(self)
        }
    }

    @objc public var uploadState: SJClipsResultUploadState = .unknown {
        didSet {
            if uploadState == oldValue { return }
            uploadStateDidChangeExeBlock?(self)
        }
    }

    @objc public var uploadProgress: Float = 0 {
        didSet {
            uploadProgressDidChangeExeBlock?(self)
        }
    }

    // results
    @objc public var thumbnailImage: UIImage?
    @objc public var image: UIImage? // screenshot or GIF
    @objc public var fileURL: URL?
    @objc public var currentPlayAsset: SJVideoPlayerURLAsset?

    @objc public func data() -> Data? {
        if let fileURL = fileURL {
            return try? Data(contentsOf: fileURL)
        } else if let image = image {
            return image.pngData()
        }
        return nil
    }

    @objc public var exportProgressDidChangeExeBlock: ((SJVideoPlayerClipsGeneratedResult) -> Void)?
    @objc public var uploadProgressDidChangeExeBlock: ((SJVideoPlayerClipsGeneratedResult) -> Void)?

    @objc public var exportStateDidChangeExeBlock: ((SJVideoPlayerClipsGeneratedResult) -> Void)?
    @objc public var uploadStateDidChangeExeBlock: ((SJVideoPlayerClipsGeneratedResult) -> Void)?

    @objc public override init() {
        super.init()
    }
}
