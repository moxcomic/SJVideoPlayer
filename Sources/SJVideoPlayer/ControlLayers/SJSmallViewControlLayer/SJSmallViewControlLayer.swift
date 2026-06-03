//
//  SJSmallViewControlLayer.swift
//  Pods
//
//  Created by 畅三江 on 2019/6/6.
//
//  浮窗小视图的控制层
//

import UIKit
import SJBaseVideoPlayer

// MARK: - 小浮窗模式下的控制层

/// item tag (数值契约原样保留)
public let SJSmallViewControlLayerTopItem_Close: SJEdgeControlButtonItemTag = 10000

/// 浮窗小视图的控制层(填充项 + 关闭按钮)。
@MainActor
@objc(SJSmallViewControlLayer)
open class SJSmallViewControlLayer: SJEdgeControlLayerAdapters, SJControlLayer {
    
    private weak var player: SJBaseVideoPlayer?
    
    private var _restarted: Bool = false
    @objc public var restarted: Bool { _restarted }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _setupView()
    }
    
    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - SJVideoPlayerControlLayerDataSource
    
    @objc public func controlView() -> UIView {
        return self
    }
    
    @objc public func installedControlView(toVideoPlayer videoPlayer: SJBaseVideoPlayer) {
        player = videoPlayer
    }
    
    // MARK: - SJControlLayerRestartProtocol
    
    @objc public func restartControlLayer() {
        _restarted = true
        sj_view_makeAppear(controlView(), true)
    }
    
    // MARK: - SJControlLayerExitProtocol
    
    @objc public func exitControlLayer() {
        _restarted = false
        sj_view_makeDisappear(controlView(), true) { [weak self] in
            guard let self = self else { return }
            if !self._restarted { self.controlView().removeFromSuperview() }
        }
    }
    
    @objc private func tappedCloseItem(_ item: SJEdgeControlButtonItem) {
        player?.pauseForUser()
        player?.smallViewFloatingController.dismiss()
    }
    
    private func _setupView() {
        topMargin = 0
        topHeight = 35
        
        let fillItem = SJEdgeControlButtonItem(tag: 0)
        fillItem.fill = true
        topAdapter.addItem(fillItem)
        
        let closeItem = SJEdgeControlButtonItem.placeholder(type: ._49x49, tag: SJSmallViewControlLayerTopItem_Close)
        closeItem.addAction(SJEdgeControlButtonItemAction(target: self, action: #selector(tappedCloseItem(_:))))
        closeItem.image = SJVideoPlayerConfigurations.shared.resources.floatSmallViewCloseImage
        topAdapter.addItem(closeItem)
        
        topAdapter.reload()
    }
    
    // MARK: - SJVideoPlayerControlLayerDelegate
    
    @objc public func controlLayerNeedAppear(_ videoPlayer: SJBaseVideoPlayer) { }
    
    @objc public func controlLayerNeedDisappear(_ videoPlayer: SJBaseVideoPlayer) { }
    
    @objc public func canTriggerRotation(ofVideoPlayer videoPlayer: SJBaseVideoPlayer) -> Bool {
        return false
    }
}
