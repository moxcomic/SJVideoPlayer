//
//  SJVideoPlayerURLAsset+SJControlAdd.swift
//  SJVideoPlayerProject
//
//  Created by 畅三江 on 2018/2/4.
//  Copyright © 2018年 changsanjiang. All rights reserved.
//
//  由 SJVideoPlayerURLAsset+SJControlAdd.h / .m 合并转换为 Swift。
//
//  给跨库 Swift 类 SJVideoPlayerURLAsset 增加 title / attributedTitle(关联对象存储,
//  attributedTitle getter 在缺省时基于 title 懒构建富文本) 及多个便捷 init。
//  扩展外部 Swift 类无存储属性, 故用 objc 关联对象; key 使用静态稳定地址, 不用 _cmd。
//

import Foundation
import UIKit
import ObjectiveC.runtime
import SJUIKit
import SJBaseVideoPlayer

extension SJVideoPlayerURLAsset {

    // MARK: - 关联对象 key(静态稳定地址)

    private enum AssociatedKeys {
        // 用静态变量地址作为稳定 key。
        @MainActor static var title: UInt8 = 0
        @MainActor static var attributedTitle: UInt8 = 0
    }

    // MARK: - 便捷构造

    @objc(initWithTitle:URL:playModel:)
    public convenience init?(title: String, url URL: URL, playModel: SJPlayModel) {
        self.init(title: title, url: URL, startPosition: 0, playModel: playModel)
    }

    @objc(initWithTitle:URL:startPosition:playModel:)
    public convenience init?(title: String, url URL: URL, startPosition: TimeInterval, playModel: SJPlayModel) {
        self.init(url: URL, startPosition: startPosition, playModel: playModel)
        self.title = title
    }

    ///
    /// v3.0.3 新增富文本标题
    ///
    @objc(initWithAttributedTitle:URL:playModel:)
    public convenience init?(attributedTitle title: NSAttributedString, url URL: URL, playModel: SJPlayModel) {
        self.init(attributedTitle: title, url: URL, startPosition: 0, playModel: playModel)
    }

    @objc(initWithAttributedTitle:URL:startPosition:playModel:)
    public convenience init?(attributedTitle title: NSAttributedString, url URL: URL, startPosition: TimeInterval, playModel: SJPlayModel) {
        self.init(url: URL, startPosition: startPosition, playModel: playModel)
        self.attributedTitle = title
    }

    // MARK: - 关联属性

    @objc public var title: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.title) as? String
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.title, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    @objc public var attributedTitle: NSAttributedString? {
        get {
            var astr = objc_getAssociatedObject(self, &AssociatedKeys.attributedTitle) as? NSAttributedString
            if astr == nil, let title = self.title {
                let sources = SJVideoPlayerConfigurations.shared.resources
                astr = (NSAttributedString.sj_UIKitText { make in
                    _ = make.append(title)
                    _ = make.font(sources.titleLabelFont ?? .systemFont(ofSize: 14))
                    _ = make.textColor(sources.titleLabelColor ?? .white)
                    _ = make.lineBreakMode(.byTruncatingTail)
                    _ = make.shadow { shadow in
                        shadow.shadowOffset = CGSize(width: 0, height: 0.5)
                        shadow.shadowColor = UIColor.black
                    }
                }).copy() as? NSAttributedString
                self.attributedTitle = astr
            }
            return astr
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.attributedTitle, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
}
