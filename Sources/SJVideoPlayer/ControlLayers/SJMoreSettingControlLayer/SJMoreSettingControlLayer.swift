//
//  SJMoreSettingControlLayer.swift
//  SJVideoPlayer_Example
//
//  Created by 畅三江 on 2019/7/19.
//  Copyright © 2019 changsanjiang. All rights reserved.
//

import UIKit
import SJBaseVideoPlayer
import SJUIKit

// MARK: - item tags (数值契约原样保留)

public let SJMoreSettingControlLayerItem_Volume: SJEdgeControlButtonItemTag = 10000
public let SJMoreSettingControlLayerItem_Brightness: SJEdgeControlButtonItemTag = 10001
public let SJMoreSettingControlLayerItem_Rate: SJEdgeControlButtonItemTag = 10002

/// 右侧抽屉式的更多设置控制层(音量/亮度/倍速三个滑条)。
@MainActor
@objc(SJMoreSettingControlLayer)
open class SJMoreSettingControlLayer: SJEdgeControlLayerAdapters, SJControlLayer, SJProgressSliderDelegate_Protocol {
    
    @objc public weak var delegate: (any SJMoreSettingControlLayerDelegate_Protocol)?
    
    private weak var videoPlayer: SJBaseVideoPlayer?
    
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
        _refreshValueForSliderItems()
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
        else if type == .pan && !rightContainerView.frame.contains(location) {
            return videoPlayer.gestureController.movingDirection == .V
        }
        else if type == .doubleTap {
            return true
        }
        
        return false
    }
    
    @objc public func canTriggerRotation(ofVideoPlayer videoPlayer: SJBaseVideoPlayer) -> Bool {
        return false
    }
    
    @objc public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, volumeChanged volume: Float) {
        _setSliderValue(forItemTag: SJMoreSettingControlLayerItem_Volume, value: volume)
    }
    
    @objc public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, brightnessChanged brightness: Float) {
        _setSliderValue(forItemTag: SJMoreSettingControlLayerItem_Brightness, value: brightness)
    }
    
    @objc public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, rateChanged rate: Float) {
        videoPlayer.textPopupController.show(NSAttributedString.sj_UIKitText { make in
            make.append(String(format: "%.0f %%", rate * 100))
            make.textColor(UIColor.white)
        })
        _setSliderValue(forItemTag: SJMoreSettingControlLayerItem_Rate, value: rate)
    }
    
    // MARK: - SJProgressSliderDelegate
    
    @objc public func sliderWillBeginDragging(_ slider: SJProgressSlider) { }
    
    @objc public func slider(_ slider: SJProgressSlider, valueDidChange value: CGFloat) {
        if slider.isDragging {
            if slider.tag == SJMoreSettingControlLayerItem_Volume {
                videoPlayer?.deviceVolumeAndBrightnessController.volume = Float(slider.value)
            }
            else if slider.tag == SJMoreSettingControlLayerItem_Brightness {
                videoPlayer?.deviceVolumeAndBrightnessController.brightness = Float(slider.value)
            }
            else {
                videoPlayer?.rate = Float(slider.value)
            }
        }
    }
    
    @objc public func sliderDidEndDragging(_ slider: SJProgressSlider) { }
    
    // MARK: -
    
    private func _setupView() {
        rightContainerView.sjv_disappearDirection = .right
        
        let max = Swift.max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
        rightWidth = floor(max * 0.382)
        
        let height: CGFloat = 60
        
        do {
            let volumeItem = SJEdgeControlButtonItem.placeholder(size: height, tag: SJMoreSettingControlLayerItem_Volume)
            let progressView = SJButtonProgressSlider()
            progressView.slider.delegate = self
            progressView.slider.tag = volumeItem.tag
            volumeItem.customView = progressView
            rightAdapter.addItem(volumeItem)
        }
        
        do {
            let brightnessItem = SJEdgeControlButtonItem.placeholder(size: height, tag: SJMoreSettingControlLayerItem_Brightness)
            let progressView = SJButtonProgressSlider()
            progressView.slider.delegate = self
            progressView.slider.tag = brightnessItem.tag
            brightnessItem.customView = progressView
            rightAdapter.addItem(brightnessItem)
        }
        
        do {
            let rateItem = SJEdgeControlButtonItem.placeholder(size: height, tag: SJMoreSettingControlLayerItem_Rate)
            let progressView = SJButtonProgressSlider()
            progressView.slider.delegate = self
            progressView.slider.tag = rateItem.tag
            progressView.slider.maxValue = CGFloat(SJVideoPlayerConfigurations.shared.resources.moreSliderMaxRateValue)
            progressView.slider.minValue = CGFloat(SJVideoPlayerConfigurations.shared.resources.moreSliderMinRateValue)
            rateItem.customView = progressView
            rightAdapter.addItem(rateItem)
        }
        
        _refreshSettings()
        rightAdapter.reload()
    }
    
    private func _refreshValueForSliderItems() {
        _setSliderValue(forItemTag: SJMoreSettingControlLayerItem_Volume,
                        value: videoPlayer?.deviceVolumeAndBrightnessController.volume ?? 0)
        _setSliderValue(forItemTag: SJMoreSettingControlLayerItem_Brightness,
                        value: videoPlayer?.deviceVolumeAndBrightnessController.brightness ?? 0)
        _setSliderValue(forItemTag: SJMoreSettingControlLayerItem_Rate,
                        value: videoPlayer?.rate ?? 0)
    }
    
    private func _setSliderValue(forItemTag itemTag: SJEdgeControlButtonItemTag, value: Float) {
        guard let item = rightAdapter.item(forTag: itemTag),
              let progressView = item.customView as? SJButtonProgressSlider else { return }
        if !progressView.slider.isDragging {
            progressView.slider.value = CGFloat(value)
        }
    }
    
    private func _refreshSettings() {
        let sources = SJVideoPlayerConfigurations.shared.resources
        rightContainerView.backgroundColor = sources.moreControlLayerBackgroundColor
        
        let configProgressView: (SJButtonProgressSlider, UIImage?, UIImage?) -> Void = { progressView, left, right in
            progressView.rightBtn.setImage(right, for: .normal)
            progressView.leftBtn.setImage(left, for: .normal)
            
            progressView.slider.traceImageView.backgroundColor = sources.moreSliderTraceColor
            progressView.slider.trackImageView.backgroundColor = sources.moreSliderTrackColor
            progressView.slider.trackHeight = CGFloat(sources.moreSliderTrackHeight)
            
            if sources.moreSliderThumbImage == nil {
                let size = CGSize(width: CGFloat(sources.moreSliderThumbSize), height: CGFloat(sources.moreSliderThumbSize))
                let radius = CGFloat(sources.moreSliderThumbSize) * 0.5
                progressView.slider.setThumbCornerRadius(radius, size: size, thumbBackgroundColor: sources.moreSliderTraceColor ?? .clear)
            }
            else {
                progressView.slider.thumbImageView.image = sources.moreSliderThumbImage
            }
        }
        
        if let volumeItem = rightAdapter.item(forTag: SJMoreSettingControlLayerItem_Volume),
           let progressView = volumeItem.customView as? SJButtonProgressSlider {
            configProgressView(progressView, sources.moreSliderMinVolumeImage, sources.moreSliderMaxVolumeImage)
        }
        
        if let brightnessItem = rightAdapter.item(forTag: SJMoreSettingControlLayerItem_Brightness),
           let progressView = brightnessItem.customView as? SJButtonProgressSlider {
            configProgressView(progressView, sources.moreSliderMinBrightnessImage, sources.moreSliderMaxBrightnessImage)
        }
        
        if let rateItem = rightAdapter.item(forTag: SJMoreSettingControlLayerItem_Rate),
           let progressView = rateItem.customView as? SJButtonProgressSlider {
            configProgressView(progressView, sources.moreSliderMinRateImage, sources.moreSliderMaxRateImage)
        }
    }
}

// MARK: - SJMoreSettingControlLayerDelegate

@MainActor
@objc(SJMoreSettingControlLayerDelegate)
public protocol SJMoreSettingControlLayerDelegate_Protocol: NSObjectProtocol {
    @objc func tappedBlankAreaOnTheControlLayer(_ controlLayer: any SJControlLayer)
}
