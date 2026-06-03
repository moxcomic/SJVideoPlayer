//
//  SJClipsResultShareItem.swift
//  SJVideoPlayerProject
//
//  Created by 畅三江 on 2018/4/12.
//  Copyright © 2018年 changsanjiang. All rights reserved.
//

import UIKit

/// 分享项(title / image / canAlsoClickedWhenUploading)。
///
/// 原头文件无 NS_ASSUME_NONNULL 包裹: title / image 为非空(init 必传)。
/// 纯模型, 不标 @MainActor。
@objc(SJClipsResultShareItem)
public class SJClipsResultShareItem: NSObject {

    @objc public var title: String
    @objc public var image: UIImage

    /// Whether can clicked When Uploading.
    /// 上传时, 是否可以点击
    ///
    /// default is NO.
    @objc public var canAlsoClickedWhenUploading: Bool = false

    @objc(initWithTitle:image:)
    public init(title: String, image: UIImage) {
        self.title = title
        self.image = image
        super.init()
    }
}
