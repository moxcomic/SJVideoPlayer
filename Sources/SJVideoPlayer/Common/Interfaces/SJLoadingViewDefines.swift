//
//  SJLoadingViewDefines.swift
//  Pods
//
//  Created by 畅三江 on 2019/11/27.
//

import UIKit

///
/// 加载指示视图协议
///
/// 对应原 `@protocol SJLoadingView`。
/// 撞名: Implements 区存在同名类 SJLoadingView, 故协议加 `_Protocol` 后缀, 但仍以 @objc(SJLoadingView) 暴露原 ObjC 名。
@objc(SJLoadingView)
@MainActor
public protocol SJLoadingView_Protocol: NSObjectProtocol {
    @objc(isAnimating) var animating: Bool { get }
    @objc var showsNetworkSpeed: Bool { get set }
    @objc var networkSpeedStr: NSAttributedString? { get set }

    @objc func start()
    @objc func stop()
}
