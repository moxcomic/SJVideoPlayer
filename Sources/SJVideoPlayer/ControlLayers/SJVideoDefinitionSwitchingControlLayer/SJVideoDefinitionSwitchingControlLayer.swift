//
//  SJVideoDefinitionSwitchingControlLayer.swift
//  Pods
//
//  Created by 畅三江 on 2019/7/12.
//

import UIKit
import SJBaseVideoPlayer
import SJUIKit

// MARK: - 切换清晰度时的控制层

/// 清晰度切换控制层(由 assets 数组驱动 item)。
@MainActor
@objc(SJVideoDefinitionSwitchingControlLayer)
open class SJVideoDefinitionSwitchingControlLayer: SJEdgeControlLayerAdapters, SJControlLayer {
    
    @objc public var assets: [SJVideoPlayerURLAsset]? {
        get { _assets }
        set { _setAssets(newValue) }
    }
    private var _assets: [SJVideoPlayerURLAsset]?
    
    @objc public weak var delegate: (any SJVideoDefinitionSwitchingControlLayerDelegate_Protocol)?
    
    private var _selectedTextColor: UIColor?
    @objc public var selectedTextColor: UIColor! {
        get { _selectedTextColor ?? UIColor.orange }
        set { _selectedTextColor = newValue }
    }
    
    private weak var videoPlayer: SJBaseVideoPlayer?
    private var items: [SJEdgeControlButtonItem]?
    
    private var _restarted: Bool = false
    @objc public var restarted: Bool { _restarted }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        rightWidth = 140
        rightContainerView.sjv_disappearDirection = .right
        rightContainerView.backgroundColor = UIColor(white: 0, alpha: 0.8)
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
        self.videoPlayer = videoPlayer
        
        sj_view_initializes(rightContainerView)
        
        layoutIfNeeded()
        
        sj_view_makeDisappear(rightContainerView, false)
    }
    
    // MARK: - SJControlLayerExitProtocol
    
    @objc public func exitControlLayer() {
        _restarted = false
        
        sj_view_makeDisappear(rightContainerView, true)
        sj_view_makeDisappear(controlView(), true) { [weak self] in
            guard let self = self else { return }
            if !self._restarted { self.controlView().removeFromSuperview() }
        }
    }
    
    // MARK: - SJControlLayerRestartProtocol
    
    @objc public func restartControlLayer() {
        _restarted = true
        
        if videoPlayer?.isFullscreen == true {
            videoPlayer?.needHiddenStatusBar()
        }
        _refreshItems()
        rightAdapter.reload()
        sj_view_makeAppear(controlView(), true)
        sj_view_makeAppear(rightContainerView, true)
    }
    
    // MARK: - SJVideoPlayerControlLayerDelegate
    
    @objc public func controlLayerNeedAppear(_ videoPlayer: SJBaseVideoPlayer) { }
    
    @objc public func controlLayerNeedDisappear(_ videoPlayer: SJBaseVideoPlayer) { }
    
    @objc public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, gestureRecognizerShouldTrigger type: SJPlayerGestureType, location: CGPoint) -> Bool {
        if type == .singleTap {
            if !rightContainerView.frame.contains(location) {
                delegate?.tappedBlankAreaOnTheControlLayer(self)
            }
        }
        return false
    }
    
    @objc public func canTriggerRotation(ofVideoPlayer videoPlayer: SJBaseVideoPlayer) -> Bool {
        return false
    }
    
    @objc private func _clickedItem(_ item: SJEdgeControlButtonItem) {
        if let assets = assets {
            delegate?.controlLayer(self, didSelectAsset: assets[item.tag])
        }
    }
    
    // MARK: -
    
    private func _setAssets(_ assets: [SJVideoPlayerURLAsset]?) {
        _assets = assets
        rightAdapter.removeAllItems()
        var m = [SJEdgeControlButtonItem]()
        if let assets = _assets {
            for idx in 0..<assets.count {
                let item = SJEdgeControlButtonItem.placeholder(size: 38, tag: idx)
                item.addAction(SJEdgeControlButtonItemAction(target: self, action: #selector(_clickedItem(_:))))
                m.append(item)
            }
        }
        items = m
        _refreshItems()
        rightAdapter.addItems(from: items ?? [])
        rightAdapter.reload()
    }
    
    private func _refreshItems() {
        guard let cur = videoPlayer?.urlAsset else { return }
        let info = videoPlayer?.definitionSwitchingInfo
        var selected: SJVideoPlayerURLAsset = cur
        if let switchingAsset = info?.switchingAsset,
           info?.status != .failed {
            selected = switchingAsset
        }
        
        guard let items = items, let assets = assets else { return }
        for item in items {
            let asset = assets[item.tag]
            item.title = NSAttributedString.sj_UIKitText { make in
                make.append(String(format: "%@", asset.definition_fullName ?? ""))
                make.font(UIFont.systemFont(ofSize: 14))
                make.alignment(.center)
                
                let textColor: UIColor = (asset == selected) ? self.selectedTextColor : UIColor.white
                make.textColor(textColor)
            }
        }
    }
}

// MARK: - SJVideoDefinitionSwitchingControlLayerDelegate

@MainActor
@objc(SJVideoDefinitionSwitchingControlLayerDelegate)
public protocol SJVideoDefinitionSwitchingControlLayerDelegate_Protocol: NSObjectProtocol {
    
    @objc func controlLayer(_ controlLayer: SJVideoDefinitionSwitchingControlLayer, didSelectAsset asset: SJVideoPlayerURLAsset)
    
    @objc func tappedBlankAreaOnTheControlLayer(_ controlLayer: any SJControlLayer)
}
