//
//  SJVideoPlayerResourceLoader.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2019/11/27.
//
//  Swift 6 迁移版本 (SJVideoPlayer module)
//

import UIKit

/// 资源加载器: 从 SJVideoPlayer.bundle 中按名加载 png 图片, 并按系统首选语言定位 lproj.
///
/// - 行为与 ObjC 版严格等价: 优先在类所在容器内定位 `SJVideoPlayer.bundle`,
///   图片以 scale=3.0 读取.
/// - SwiftPM 集成时, 资源由 `Bundle.module` 容器承载, 仍以 bundle 形式定位 `SJVideoPlayer.bundle`.
/// - 首选语言映射: en* → en; zh* 含 "Hans" → zh-Hans, 其余 zh → zh-Hant; 其它一律回落 en.
@objc(SJVideoPlayerResourceLoader)
public final class SJVideoPlayerResourceLoader: NSObject {

    /// 资源容器 bundle: SwiftPM 用 Bundle.module 内的 SJVideoPlayer.bundle, 其它集成方式用类所在 bundle.
    /// (懒加载且只解析一次, 等价于 ObjC 的 +initialize + dispatch_once)
    private static let _bundle: Bundle? = {
        #if SWIFT_PACKAGE
        let container = Bundle.module
        #else
        let container = Bundle(for: SJVideoPlayerResourceLoader.self)
        #endif
        guard let path = container.path(forResource: "SJVideoPlayer", ofType: "bundle") else {
            return nil
        }
        return Bundle(path: path)
    }()

    /// 按系统首选语言定位的 lproj bundle (懒加载且只解析一次)
    private static let _preferredLanguageBundle: Bundle? = {
        var preferredLanguage = Locale.preferredLanguages.first ?? "en"
        if preferredLanguage.hasPrefix("en") {
            preferredLanguage = "en"
        } else if preferredLanguage.hasPrefix("zh") {
            preferredLanguage = preferredLanguage.range(of: "Hans") != nil ? "zh-Hans" : "zh-Hant"
        } else {
            preferredLanguage = "en"
        }
        guard let path = _bundle?.path(forResource: preferredLanguage, ofType: "lproj") else {
            return nil
        }
        return Bundle(path: path)
    }()

    /// en.lproj bundle
    private static let _enBundle: Bundle? = {
        guard let path = _bundle?.path(forResource: "en", ofType: "lproj") else {
            return nil
        }
        return Bundle(path: path)
    }()

    /// zh-Hans.lproj bundle (简体中文)
    private static let _zhHansBundle: Bundle? = {
        guard let path = _bundle?.path(forResource: "zh-Hans", ofType: "lproj") else {
            return nil
        }
        return Bundle(path: path)
    }()

    /// zh-Hant.lproj bundle (繁體中文)
    private static let _zhHantBundle: Bundle? = {
        guard let path = _bundle?.path(forResource: "zh-Hant", ofType: "lproj") else {
            return nil
        }
        return Bundle(path: path)
    }()

    /// 资源容器 bundle (库内访问)
    static var bundle: Bundle? {
        return _bundle
    }

    @objc public class var preferredLanguageBundle: Bundle? {
        return _preferredLanguageBundle
    }

    @objc public class var enBundle: Bundle? {
        return _enBundle
    }

    /// 简体中文
    @objc public class var zhHansBundle: Bundle? {
        return _zhHansBundle
    }

    /// 繁體中文
    @objc public class var zhHantBundle: Bundle? {
        return _zhHantBundle
    }

    @objc(imageNamed:)
    public class func image(named name: String) -> UIImage? {
        if name.isEmpty { return nil }
        guard let path = bundle?.path(forResource: name, ofType: "png"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        return UIImage(data: data, scale: 3.0)
    }
}
