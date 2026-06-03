//
//  SJVideoPlayerClipsParameters.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2019/1/20.
//  Copyright © 2019 畅三江. All rights reserved.
//

import Foundation
import AVFoundation
import CoreMedia

/// 剪辑参数。实现同名协议 SJVideoPlayerClipsParameters_Protocol(协议加 _Protocol 后缀, 类保原名)。
///
/// 纯模型, 不标 @MainActor。
@objc(SJVideoPlayerClipsParameters)
public class SJVideoPlayerClipsParameters: NSObject, SJVideoPlayerClipsParameters_Protocol {

    // operation
    @objc public private(set) var operation: SJVideoPlayerClipsOperation
    @objc public private(set) var range: CMTimeRange

    // upload
    @objc public var resultNeedUpload: Bool = false
    @objc public weak var resultUploader: (any SJVideoPlayerClipsResultUpload)?

    // album
    @objc public var saveResultToAlbum: Bool = false

    @objc(initWithOperation:range:)
    public init(operation: SJVideoPlayerClipsOperation, range: CMTimeRange) {
        self.operation = operation
        self.range = range
        super.init()
    }
}
