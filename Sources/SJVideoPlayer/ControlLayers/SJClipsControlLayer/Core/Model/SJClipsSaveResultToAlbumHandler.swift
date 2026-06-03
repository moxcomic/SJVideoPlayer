//
//  SJClipsSaveResultToAlbumHandler.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2019/1/20.
//  Copyright © 2019 畅三江. All rights reserved.
//

import Foundation
import UIKit
import Photos

/// 保存结果到相册失败原因。
@objc(SJClipsSaveResultToAlbumFailedReason)
public enum SJClipsSaveResultToAlbumFailedReason: UInt {
    case authDenied
}

/// 保存失败信息协议(撞名: .m 内有私有实现类 → 协议加 _Protocol, 类保原名)。
@objc(SJClipsSaveResultFailed)
public protocol SJClipsSaveResultFailed_Protocol: NSObjectProtocol {
    @objc var reason: SJClipsSaveResultToAlbumFailedReason { get }
    @objc func toString() -> String
}

/// 保存结果到相册处理协议(撞名: 同名实现类 → 协议加 _Protocol, 类保原名)。
@objc(SJClipsSaveResultToAlbumHandler)
public protocol SJClipsSaveResultToAlbumHandler_Protocol: NSObjectProtocol {
    @objc(saveResult:completionHandler:)
    func saveResult(_ result: any SJVideoPlayerClipsResult,
                    completionHandler: @escaping (_ r: Bool, _ failed: (any SJClipsSaveResultFailed_Protocol)?) -> Void)
}

/// 保存失败信息私有实现。toString 返回本地化 albumAuthDeniedPrompt。
private final class SJClipsSaveResultFailed: NSObject, SJClipsSaveResultFailed_Protocol {
    let reason: SJClipsSaveResultToAlbumFailedReason

    init(reason: SJClipsSaveResultToAlbumFailedReason) {
        self.reason = reason
        super.init()
    }

    func toString() -> String {
        switch reason {
        case .authDenied:
            return SJVideoPlayerConfigurations.shared.localizedStrings.albumAuthDeniedPrompt ?? ""
        }
    }
}

/// 保存结果到相册: 截图 / 视频 / GIF 存相册。
///
/// iOS15: 已删除原 ALAssetsLibrary 旧分支, 统一走 PHPhotoLibrary。
/// 纯模型(无视图操作), 不标 @MainActor。
@objc(SJClipsSaveResultToAlbumHandler)
public class SJClipsSaveResultToAlbumHandler: NSObject, SJClipsSaveResultToAlbumHandler_Protocol, @unchecked Sendable {

    private var completionHandler: ((_ r: Bool, _ failed: (any SJClipsSaveResultFailed_Protocol)?) -> Void)?

    @objc public override init() {
        super.init()
    }

    @objc(saveResult:completionHandler:)
    public func saveResult(_ result: any SJVideoPlayerClipsResult,
                           completionHandler: @escaping (_ r: Bool, _ failed: (any SJClipsSaveResultFailed_Protocol)?) -> Void) {
        self.completionHandler = completionHandler

        switch result.operation {
        case .unknown:
            break
        case .screenshot:
            _saveScreenshot(result)
        case .export:
            _saveVideo(result)
        case .gif:
            _saveGIF(result)
        @unknown default:
            break
        }
    }

    private func _saveScreenshot(_ result: any SJVideoPlayerClipsResult) {
        guard let image = result.image else {
            // 与原实现一致, 原 ObjC 直接传 result.image(可能为 nil), 此处保护避免崩溃
            if let completionHandler = completionHandler {
                completionHandler(false, SJClipsSaveResultFailed(reason: .authDenied))
            }
            return
        }
        UIImageWriteToSavedPhotosAlbum(image, self,
                                       #selector(image(_:didFinishSavingWithError:contextInfo:)),
                                       nil)
    }

    private func _saveGIF(_ result: any SJVideoPlayerClipsResult) {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            switch status {
            case .notDetermined, .restricted, .denied:
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if let completionHandler = self.completionHandler {
                        completionHandler(false, SJClipsSaveResultFailed(reason: .authDenied))
                    }
                }
            case .limited, .authorized:
                let fileURL = result.fileURL
                PHPhotoLibrary.shared().performChanges {
                    if let fileURL = fileURL {
                        PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
                    }
                } completionHandler: { success, error in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        if let completionHandler = self.completionHandler {
                            completionHandler(error == nil,
                                              error != nil ? SJClipsSaveResultFailed(reason: .authDenied) : nil)
                        }
                    }
                }
            @unknown default:
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if let completionHandler = self.completionHandler {
                        completionHandler(false, SJClipsSaveResultFailed(reason: .authDenied))
                    }
                }
            }
        }
    }

    private func _saveVideo(_ result: any SJVideoPlayerClipsResult) {
        guard let path = result.fileURL?.path else {
            if let completionHandler = completionHandler {
                completionHandler(false, SJClipsSaveResultFailed(reason: .authDenied))
            }
            return
        }
        UISaveVideoAtPathToSavedPhotosAlbum(path, self,
                                            #selector(video(_:didFinishSavingWithError:contextInfo:)),
                                            nil)
    }

    @objc(video:didFinishSavingWithError:contextInfo:)
    private func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer?) {
        if let completionHandler = completionHandler {
            completionHandler(error == nil,
                              error != nil ? SJClipsSaveResultFailed(reason: .authDenied) : nil)
        }
    }

    @objc(image:didFinishSavingWithError:contextInfo:)
    private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer?) {
        if let completionHandler = completionHandler {
            completionHandler(error == nil,
                              error != nil ? SJClipsSaveResultFailed(reason: .authDenied) : nil)
        }
    }
}
