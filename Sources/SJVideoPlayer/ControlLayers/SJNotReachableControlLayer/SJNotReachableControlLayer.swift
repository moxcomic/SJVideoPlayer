//
//  SJNotReachableControlLayer.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2019/1/15.
//  Copyright © 2019 畅三江. All rights reserved.
//

import UIKit
import SJBaseVideoPlayer
import SnapKit

// MARK: - 无网状态下显示的控制层

/// 顶部返回按钮的 item tag (数值契约: 10000)
public let SJNotReachableControlLayerTopItem_Back: SJEdgeControlButtonItemTag = 10000

/// 无网状态下显示的控制层
@objc(SJNotReachableControlLayer)
@MainActor
public class SJNotReachableControlLayer: SJEdgeControlLayerAdapters, SJControlLayer {
    
    @objc public weak var delegate: (any SJNotReachableControlLayerDelegate_Protocol)?
    
    @objc public private(set) lazy var promptLabel: UILabel = UILabel(frame: .zero)
    
    @objc public private(set) lazy var reloadView: SJButtonContainerView = SJButtonContainerView(edgeInsets: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
    
    @objc public var hiddenBackButtonWhenOrientationIsPortrait: Bool = false
    
    // MARK: - SJControlLayerRestartProtocol
    
    /// 是否已重新启用
    @objc public private(set) var restarted: Bool = false
    
    // MARK: - init
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _setupView()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - actions
    
    @objc(backItemWasTapped:)
    func backItemWasTapped(_ item: SJEdgeControlButtonItem) {
        delegate?.backItemWasTapped?(forControlLayer: self)
    }
    
    @objc func reloadButtonWasTapped() {
        delegate?.reloadItemWasTapped?(forControlLayer: self)
    }
    
    // MARK: - SJControlLayerRestartProtocol / SJControlLayerExitProtocol
    
    @objc public func restartControlLayer() {
        restarted = true
        sj_view_makeAppear(controlView(), true)
    }
    
    @objc public func exitControlLayer() {
        restarted = false
        sj_view_makeDisappear(controlView(), true) { [weak self] in
            guard let self = self else { return }
            if !self.restarted { self.controlView().removeFromSuperview() }
        }
    }
    
    // MARK: - SJVideoPlayerControlLayerDataSource / Delegate
    
    @objc public func controlView() -> UIView {
        return self
    }
    
    @objc public func installedControlView(toVideoPlayer videoPlayer: SJBaseVideoPlayer) {
        _updateItems(videoPlayer)
    }
    
    @objc public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, gestureRecognizerShouldTrigger type: SJPlayerGestureType, location: CGPoint) -> Bool {
        return false
    }
    
    @objc public func controlLayerNeedAppear(_ videoPlayer: SJBaseVideoPlayer) {}
    @objc public func controlLayerNeedDisappear(_ videoPlayer: SJBaseVideoPlayer) {}
    
    @objc public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, onRotationTransitioningChanged isTransitioning: Bool) {
        if isTransitioning { _updateItems(videoPlayer) }
    }
    
    @objc public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, willFitOnScreen isFitOnScreen: Bool) {
        _updateItems(videoPlayer)
    }
    
    func _updateItems(_ videoPlayer: SJBaseVideoPlayer) {
        let backItem = _topAdapter?.item(forTag: SJNotReachableControlLayerTopItem_Back)
        let isFitOnScreen = videoPlayer.fitOnScreen
        let isFull = videoPlayer.isFullscreen
        
        if let backItem = backItem {
            if isFull || isFitOnScreen {
                backItem.innerHidden = false
            } else {
                if hiddenBackButtonWhenOrientationIsPortrait {
                    backItem.innerHidden = true
                } else {
                    backItem.innerHidden = videoPlayer.isPlayOnScrollView
                }
            }
        }
        _topAdapter?.reload()
    }
    
    // MARK: - setup
    
    func _setupView() {
        backgroundColor = .black
        
        let sources = SJVideoPlayerConfigurations.shared.resources
        let strings = SJVideoPlayerConfigurations.shared.localizedStrings
        
        let backItem = SJEdgeControlButtonItem.placeholder(type: ._49x49, tag: SJNotReachableControlLayerTopItem_Back)
        backItem.addAction(SJEdgeControlButtonItemAction(target: self, action: #selector(backItemWasTapped(_:))))
        backItem.image = sources.backImage
        topAdapter.addItem(backItem)
        topAdapter.reload()
        
        promptLabel.text = strings.noNetworkPrompt
        promptLabel.font = .systemFont(ofSize: 14)
        promptLabel.textColor = .white
        promptLabel.textAlignment = .center
        promptLabel.numberOfLines = 0
        addSubview(promptLabel)
        promptLabel.snp.makeConstraints { make in
            make.left.greaterThanOrEqualTo(20)
            make.right.lessThanOrEqualTo(-20)
            make.centerX.equalToSuperview().offset(0)
            make.bottom.equalTo(self.snp.centerY)
        }
        
        reloadView.button.addTarget(self, action: #selector(reloadButtonWasTapped), for: .touchUpInside)
        reloadView.roundedRect = true
        reloadView.button.setTitle(strings.reload, for: .normal)
        reloadView.button.titleLabel?.font = .systemFont(ofSize: 14)
        reloadView.backgroundColor = .red
        reloadView.backgroundColor = sources.noNetworkButtonBackgroundColor
        addSubview(reloadView)
        reloadView.snp.makeConstraints { make in
            make.top.equalTo(self.promptLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview().offset(0)
        }
    }
}

// MARK: - SJButtonContainerView

/// 通用按钮容器 (内边距 / 圆角 / UIButton)
@objc(SJButtonContainerView)
@MainActor
public class SJButtonContainerView: UIView {
    
    @objc public var insets: UIEdgeInsets {
        didSet {
            button.snp.remakeConstraints { make in
                make.edges.equalTo(self).inset(insets)
            }
        }
    }
    
    @objc(isRoundedRect) public var roundedRect: Bool = false
    
    @objc public private(set) lazy var button: UIButton = UIButton(type: .custom)
    
    @objc(initWithEdgeInsets:)
    public init(edgeInsets insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: .zero)
        addSubview(button)
        button.snp.makeConstraints { make in
            make.edges.equalTo(self).inset(insets)
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if roundedRect { layer.cornerRadius = bounds.size.height * 0.5 }
    }
}

// MARK: - SJNotReachableControlLayerDelegate

@objc(SJNotReachableControlLayerDelegate)
@MainActor
public protocol SJNotReachableControlLayerDelegate_Protocol: NSObjectProtocol {
    @objc(backItemWasTappedForControlLayer:)
    optional func backItemWasTapped(forControlLayer controlLayer: any SJControlLayer)
    @objc(reloadItemWasTappedForControlLayer:)
    optional func reloadItemWasTapped(forControlLayer controlLayer: any SJControlLayer)
}
