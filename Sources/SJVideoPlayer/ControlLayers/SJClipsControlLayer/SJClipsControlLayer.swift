//
//  SJClipsControlLayer.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2019/1/19.
//  Copyright © 2019 畅三江. All rights reserved.
//

import UIKit
import AVFoundation
import SJBaseVideoPlayer
import SJUIKit

// MARK: - 剪辑(GIF, Export, Screenshot)控制层

// right items
private let SJClipsControlLayerRightItem_Screenshot: SJEdgeControlButtonItemTag = 10000
private let SJClipsControlLayerRightItem_ExportVideo: SJEdgeControlButtonItemTag = 10001
private let SJClipsControlLayerRightItem_ExportGIF: SJEdgeControlButtonItemTag = 10002

// control layer
private let SJClipsGIFRecordsControlLayerIdentifier: SJControlLayerIdentifier = 1
private let SJClipsVideoRecordsControlLayerIdentifier: SJControlLayerIdentifier = 2
private let SJClipsResultsControlLayerIdentifier: SJControlLayerIdentifier = 3

@objc(SJClipsControlLayer)
@MainActor
public class SJClipsControlLayer: SJEdgeControlLayerAdapters, SJControlLayer {

    /// 取消剪辑操作时回调
    @objc public var cancelledOperationExeBlock: ((SJClipsControlLayer) -> Void)?
    /// 剪辑配置
    @objc public var config: SJVideoPlayerClipsConfig? {
        didSet {
            _updateRightItemSettings()
        }
    }

    private var switcher: SJControlLayerSwitcher?
    private weak var player: SJBaseVideoPlayer?

    // MARK: SJControlLayerRestartProtocol

    public private(set) var restarted: Bool = false

    public func restartControlLayer() {
        restarted = true

        sj_view_makeAppear(controlView(), true)
        sj_view_makeAppear(rightContainerView, true)
    }

    public func exitControlLayer() {
        restarted = false

        sj_view_makeDisappear(controlView(), true)
        sj_view_makeDisappear(rightContainerView, true) { [weak self] in
            guard let self = self else { return }
            if !self.restarted { self.controlView().removeFromSuperview() }
        }
    }

    // MARK: Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        _setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Actions

    @objc private func screenshotItemWasTapped() {
        _start(.screenshot)
    }

    @objc private func exportVideoItemWasTapped() {
        _start(.export)
    }

    @objc private func exportGIFItemWasTapped() {
        _start(.gif)
    }

    private func _start(_ operation: SJVideoPlayerClipsOperation) {
        if player?.assetStatus != .readyToPlay {
            player?.textPopupController.show(NSAttributedString.sj_UIKitText { make in
                make.append(SJVideoPlayerConfigurations.shared.localizedStrings.operationFailedPrompt ?? "")
                make.textColor(UIColor.white)
            })
            return
        }

        if !_shouldStart(operation) {
            return
        }

        switch operation {
        case .unknown:
            break
        case .screenshot:
            _showResults(parameters: _parameters(operation: .screenshot, range: CMTimeRange.zero))
        case .export:
            switcher?.switchControlLayer(forIdentifier: SJClipsVideoRecordsControlLayerIdentifier)
        case .gif:
            switcher?.switchControlLayer(forIdentifier: SJClipsGIFRecordsControlLayerIdentifier)
        @unknown default:
            break
        }
    }

    private func cancel() {
//        [[self.switcher controlLayerForIdentifier:self.switcher.currentIdentifier] exitControlLayer];
        switcher = nil
        cancelledOperationExeBlock?(self)
    }

    private func _parameters(operation: SJVideoPlayerClipsOperation, range: CMTimeRange) -> SJVideoPlayerClipsParameters {
        let parameters = SJVideoPlayerClipsParameters(operation: operation, range: range)
        parameters.resultUploader = config?.resultUploader
        parameters.resultNeedUpload = config?.resultNeedUpload ?? false
        parameters.saveResultToAlbum = config?.saveResultToAlbum ?? false
        return parameters
    }

    private func _showResults(parameters: SJVideoPlayerClipsParameters_Protocol) {
        player?.pause()

        switcher?.switchControlLayer(forIdentifier: SJClipsResultsControlLayerIdentifier)
        let control = switcher?.controlLayer(forIdentifier: SJClipsResultsControlLayerIdentifier) as? SJClipsResultsControlLayer
        control?.parameters = parameters
        control?.shareItems = config?.resultShareItems
        control?.clickedResultShareItemExeBlock = config?.clickedResultShareItemExeBlock
    }

    // MARK: -

    private func _setupViews() {
        rightContainerView.sjv_disappearDirection = .right
        sj_view_initializes([rightContainerView])

        _addItemToRightAdapter()
        _updateRightItemSettings()
    }

    private func _addItemToRightAdapter() {
        let screenshotItem = SJEdgeControlButtonItem.placeholder(type: ._49x49, tag: SJClipsControlLayerRightItem_Screenshot)
        screenshotItem.addAction(SJEdgeControlButtonItemAction(target: self, action: #selector(screenshotItemWasTapped)))
        rightAdapter.addItem(screenshotItem)

        let exportVideoItem = SJEdgeControlButtonItem.placeholder(type: ._49x49, tag: SJClipsControlLayerRightItem_ExportVideo)
        exportVideoItem.addAction(SJEdgeControlButtonItemAction(target: self, action: #selector(exportVideoItemWasTapped)))
        rightAdapter.addItem(exportVideoItem)

        let exportGIFItem = SJEdgeControlButtonItem.placeholder(type: ._49x49, tag: SJClipsControlLayerRightItem_ExportGIF)
        exportGIFItem.addAction(SJEdgeControlButtonItemAction(target: self, action: #selector(exportGIFItemWasTapped)))
        rightAdapter.addItem(exportGIFItem)
    }

    private func _updateRightItemSettings() {
        let sources = SJVideoPlayerConfigurations.shared.resources
        let screenshotItem = rightAdapter.item(forTag: SJClipsControlLayerRightItem_Screenshot)
        screenshotItem?.image = sources.screenshotImage
        screenshotItem?.innerHidden = config?.disableScreenshot ?? false

        let exportVideoItem = rightAdapter.item(forTag: SJClipsControlLayerRightItem_ExportVideo)
        exportVideoItem?.image = sources.videoClipImage
        exportVideoItem?.innerHidden = config?.disableRecord ?? false

        let exportGIFItem = rightAdapter.item(forTag: SJClipsControlLayerRightItem_ExportGIF)
        exportGIFItem?.image = sources.GIFClipImage
        exportGIFItem?.innerHidden = config?.disableGIF ?? false

        rightAdapter.reload()
    }

    private func _initializeSwitcher(_ videoPlayer: SJBaseVideoPlayer) {
        let switcher = SJControlLayerSwitcher(player: videoPlayer)
        self.switcher = switcher
        switcher.resolveControlLayer = { [weak self] identifier -> (any SJControlLayer)? in
            guard let self = self else { return nil }
            if identifier == SJClipsGIFRecordsControlLayerIdentifier {
                let controlLayer = SJClipsGIFRecordsControlLayer()
                controlLayer.statusDidChangeExeBlock = { [weak self] control in
                    guard let self = self else { return }
                    switch control.status {
                    case .unknown, .recording, .paused:
                        break
                    case .cancelled:
                        self.cancel()
                    case .finished:
                        self._showResults(parameters: self._parameters(operation: .gif, range: control.range))
                    @unknown default:
                        break
                    }
                }
                return controlLayer
            } else if identifier == SJClipsVideoRecordsControlLayerIdentifier {
                let controlLayer = SJClipsVideoRecordsControlLayer()
                controlLayer.statusDidChangeExeBlock = { [weak self] control in
                    guard let self = self else { return }
                    switch control.status {
                    case .unknown, .recording, .paused:
                        break
                    case .cancelled:
                        self.cancel()
                    case .finished:
                        self._showResults(parameters: self._parameters(operation: .export, range: control.range))
                    @unknown default:
                        break
                    }
                }
                return controlLayer
            } else if identifier == SJClipsResultsControlLayerIdentifier {
                let controlLayer = SJClipsResultsControlLayer()
                controlLayer.cancelledOperationExeBlock = { [weak self] _ in
                    guard let self = self else { return }
                    self.cancel()
                }
                return controlLayer
            }
            return nil
        }
    }

    // MARK: -

    private func _shouldStart(_ operation: SJVideoPlayerClipsOperation) -> Bool {
        if let shouldStart = config?.shouldStart, let player = player {
            return shouldStart(player, operation)
        }
        return true
    }

    // MARK: SJVideoPlayerControlLayerDataSource / Delegate

    public func controlView() -> UIView {
        return self
    }

    public func installedControlView(toVideoPlayer videoPlayer: SJBaseVideoPlayer) {
        player = videoPlayer
        videoPlayer.needHiddenStatusBar()
        _initializeSwitcher(videoPlayer)
        sj_view_makeDisappear(rightContainerView, false)
    }

    public func canTriggerRotation(ofVideoPlayer videoPlayer: SJBaseVideoPlayer) -> Bool {
        return false
    }

    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, gestureRecognizerShouldTrigger type: SJPlayerGestureType, location: CGPoint) -> Bool {
        if type == .singleTap {
            if !rightAdapter.itemContains(location) {
                cancelledOperationExeBlock?(self)
            }
        }
        return false
    }

    public func controlLayerNeedAppear(_ videoPlayer: SJBaseVideoPlayer) {}
    public func controlLayerNeedDisappear(_ videoPlayer: SJBaseVideoPlayer) {}
}
