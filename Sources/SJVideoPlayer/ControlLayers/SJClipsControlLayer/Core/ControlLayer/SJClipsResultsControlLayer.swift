//
//  SJClipsResultsControlLayer.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2019/1/20.
//  Copyright © 2019 畅三江. All rights reserved.
//

import UIKit

private let SJTopItem_Back: SJEdgeControlButtonItemTag = 1
import AVFoundation
import SJBaseVideoPlayer
import SJUIKit
import SnapKit

@objc(SJClipsResultsControlLayer)
@MainActor
public class SJClipsResultsControlLayer: SJEdgeControlLayerAdapters, SJControlLayer {

    @objc public var shareItems: [SJClipsResultShareItem]? {
        get { itemsContainerView.shareItems }
        set { itemsContainerView.shareItems = newValue }
    }
    @objc public var parameters: SJVideoPlayerClipsParameters_Protocol?

    @objc public var cancelledOperationExeBlock: ((SJClipsResultsControlLayer) -> Void)?
    @objc public var clickedResultShareItemExeBlock: ((_ player: SJBaseVideoPlayer, _ item: SJClipsResultShareItem, _ result: SJVideoPlayerClipsResult) -> Void)?

    private weak var player: SJBaseVideoPlayer?
    private lazy var saveHandler: SJClipsSaveResultToAlbumHandler = SJClipsSaveResultToAlbumHandler()
    private var backButtonContainerView: SJClipsButtonContainerView!
    private var itemsContainerView: SJClipsResultShareItemsContainerView!

    private var promptLabel: UILabel!
    private var coverImageView: UIImageView!

    private var result: SJVideoPlayerClipsGeneratedResult?
    private lazy var exportedVideoPlayer: SJBaseVideoPlayer = {
        let player = SJBaseVideoPlayer.player()
        player.pausedInBackground = true
        player.resumePlaybackWhenAppDidEnterForeground = true
        player.view.backgroundColor = .clear
        for view in player.view.subviews {
            view.backgroundColor = .clear
        }
        player.gestureController.supportedGestureTypes = SJPlayerGestureTypeMask.none.rawValue
        player.rotationManager?.disabledAutorotation = true
        player.playbackObserver.playbackDidFinishExeBlock = { player in
            player.replay()
        }
        return player
    }()
    private var flashingView: UIView!

    private var _needDelay: Bool = false

    // MARK: SJControlLayerRestartProtocol

    public private(set) var restarted: Bool = false

    public func restartControlLayer() {
        restarted = true
        flashingView.alpha = 0.001
        itemsContainerView.alpha = 0.001
        flashingView.backgroundColor = UIColor(white: 1, alpha: 0.8)
        coverImageView.alpha = 0.001
        sj_view_makeAppear(controlView(), true)
        _getScreenshot { [weak self] img in
            guard let self = self else { return }
            self.coverImageView.image = img
            UIView.animate(withDuration: 0, animations: {}) { _ in
                UIView.animate(withDuration: 0.2, animations: {
                    self.flashingView.alpha = 1
                }) { _ in
                    UIView.animate(withDuration: 0.3, animations: {
                        self.flashingView.alpha = 0.001
                        self.coverImageView.alpha = 1
                    }) { _ in
                        UIView.animate(withDuration: 0.3) {
                            self.itemsContainerView.alpha = 1
                        }

                        sj_view_makeAppear(self.topContainerView, true)
                        self.flashingView.removeFromSuperview()
                        let screenWidth = UIScreen.main.bounds.size.width
                        let screenHeight = UIScreen.main.bounds.size.height
                        let minValue = min(screenWidth, screenHeight)
                        let maxValue = max(screenWidth, screenHeight)

                        self.coverImageView.snp.remakeConstraints { make in
                            make.centerX.equalToSuperview().offset(0)
                            make.centerY.equalTo(self.snp.centerY).multipliedBy(0.82)
                            make.width.equalTo(self).multipliedBy(0.4)
                            make.height.equalTo(self.coverImageView.snp.width).multipliedBy(minValue / maxValue)
                        }

                        let imageSize = self.coverImageView.image?.size
                        let scale: CGFloat = (img != nil && imageSize != nil) ? (imageSize!.width / imageSize!.height) : 0
                        let maxW = self.bounds.size.width * 0.4
                        let showH = maxW * minValue / maxValue
                        let showW = showH * scale
                        let rightMargin = floor((maxW - showW) * 0.5)
                        self.promptLabel.snp.remakeConstraints { make in
                            make.bottom.equalToSuperview().offset(-8)
                            make.right.equalToSuperview().offset(-(rightMargin + 8))
                        }

                        UIView.animate(withDuration: 0.6, animations: {
                            self.layoutIfNeeded()
                        }) { _ in
                            self._results()
                        }
                    }
                }
            }
        }
    }

    private func _getScreenshot(_ block: @escaping (_ img: UIImage?) -> Void) {
        if player?.assetURL?.isFileURL == true {
            block(player?.screenshot())
        } else {
            player?.textPopupController.show(NSAttributedString.sj_UIKitText { make in
                make.append("处理中")
                make.textColor(UIColor.white)
            }, duration: -1)
            player?.screenshot(withTime: player?.currentTime ?? 0) { [weak self] videoPlayer, image, error in
                guard self != nil else { return }
                videoPlayer.textPopupController.hidden()
                block(image)
            }
        }
    }

    public func exitControlLayer() {
        restarted = false
        sj_view_makeDisappear(topContainerView, true)
        sj_view_makeDisappear(controlView(), true) { [weak self] in
            guard let self = self else { return }
            if !self.restarted {
                self.controlView().removeFromSuperview()
                self.coverImageView.snp.remakeConstraints { make in
                    make.edges.equalToSuperview().offset(0)
                }
            }
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        _setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func _results() {
        let result = SJVideoPlayerClipsGeneratedResult()
        self.result = result

        result.exportProgressDidChangeExeBlock = { [weak self] result in
            guard let self = self else { return }
            let strings = SJVideoPlayerConfigurations.shared.localizedStrings
            self._updatePromptLabelText(String(format: "%@ %.0f%%", strings.exportsExportingPrompt, result.exportProgress * 100))
        }

        result.exportStateDidChangeExeBlock = { [weak self] result in
            guard let self = self else { return }
            let strings = SJVideoPlayerConfigurations.shared.localizedStrings
            self._updateTopItemSettings()
            switch result.exportState {
            case .unknown, .cancelled, .exporting:
                break
            case .failed:
                self._updatePromptLabelText(strings.exportsExportFailedPrompt)
            case .success:
                if result.operation == .screenshot {
                    self._updatePromptLabelText(strings.screenshotSuccessfullyPrompt)
                } else {
                    self._updatePromptLabelText(strings.exportsExportSuccessfullyPrompt)
                }

                switch result.operation {
                case .unknown, .screenshot:
                    break
                case .export:
                    self.exportedVideoPlayer.assetURL = self.result?.fileURL
                    self.coverImageView.insertSubview(self.exportedVideoPlayer.view, belowSubview: self.promptLabel)
                    self.exportedVideoPlayer.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    self.exportedVideoPlayer.view.frame = self.coverImageView.bounds
                case .gif:
                    self.coverImageView.image = self.result?.image
                @unknown default:
                    break
                }

                self._uploadResultIfNeeded()

                if self.parameters?.saveResultToAlbum == true {
                    self.player?.textPopupController.show(NSAttributedString.sj_UIKitText { make in
                        make.append(strings.albumSavingScreenshotToAlbumPrompt)
                        make.textColor(UIColor.white)
                    }, duration: -1)
                    self.saveHandler.saveResult(result) { [weak self] r, failed in
                        guard let self = self else { return }
                        if r {
                            self.player?.textPopupController.show(NSAttributedString.sj_UIKitText { make in
                                make.append(strings.albumSavedToAlbumPrompt)
                                make.textColor(UIColor.white)
                            })
                            if self.parameters?.resultNeedUpload != true {
                                self._updatePromptLabelText(strings.albumSavedToAlbumPrompt)
                            }
                        } else {
                            self.player?.textPopupController.show(NSAttributedString.sj_UIKitText { make in
                                make.append(failed?.toString() ?? "")
                                make.textColor(UIColor.white)
                            })
                            if self.parameters?.resultNeedUpload != true {
                                self._updatePromptLabelText(strings.albumAuthDeniedPrompt)
                            }
                        }
                    }
                }
            @unknown default:
                break
            }
        }

        result.uploadProgressDidChangeExeBlock = { [weak self] result in
            guard let self = self else { return }
            let strings = SJVideoPlayerConfigurations.shared.localizedStrings
            self._updatePromptLabelText(String(format: "%@ %.0f%%", strings.uploadsUploadingPrompt, result.uploadProgress * 100))
        }

        result.uploadStateDidChangeExeBlock = { [weak self] result in
            guard let self = self else { return }
            let strings = SJVideoPlayerConfigurations.shared.localizedStrings
            switch result.uploadState {
            case .unknown, .uploading, .cancelled:
                break
            case .failed:
                self._updatePromptLabelText(strings.uploadsUploadFailedPrompt)
            case .successfully:
                self._updatePromptLabelText(strings.uploadsUploadSuccessfullyPrompt)
            @unknown default:
                break
            }
        }

        switch parameters?.operation {
        case .unknown, .none:
            return
        case .screenshot:
            _generateScreenshot()
        case .export:
            _generateVideo()
        case .gif:
            _generateGIF()
        @unknown default:
            break
        }
    }

    private func _generateScreenshot() {
        result?.operation = .screenshot
        result?.image = coverImageView.image
        result?.thumbnailImage = coverImageView.image
        result?.exportState = coverImageView.image != nil ? .success : .failed
    }

    private func _generateVideo() {
        result?.operation = .export
        result?.exportState = .exporting
        result?.exportProgress = 0.001

        let begin = CMTimeGetSeconds(parameters?.range.start ?? .zero)
        let duration = CMTimeGetSeconds(parameters?.range.duration ?? .zero)
        player?.export(withBeginTime: begin, duration: duration, presetName: nil, progress: { [weak self] videoPlayer, progress in
            guard let self = self else { return }
            self.result?.exportProgress = progress
        }, completion: { [weak self] videoPlayer, fileURL, thumbnailImage in
            guard let self = self else { return }
            self.result?.thumbnailImage = thumbnailImage
            self.result?.fileURL = fileURL
            self.result?.exportProgress = 1
            self.result?.exportState = .success
        }, failure: { [weak self] videoPlayer, error in
            guard let self = self else { return }
            self.result?.exportState = .failed
        })
    }

    private func _generateGIF() {
        result?.operation = .gif
        result?.exportState = .exporting
        result?.exportProgress = 0.001

        let begin = CMTimeGetSeconds(parameters?.range.start ?? .zero)
        let duration = CMTimeGetSeconds(parameters?.range.duration ?? .zero)
        player?.generateGIF(withBeginTime: begin, duration: duration, progress: { [weak self] videoPlayer, progress in
            guard let self = self else { return }
            self.result?.exportProgress = progress
        }, completion: { [weak self] videoPlayer, imageGIF, thumbnailImage, filePath in
            guard let self = self else { return }
            self.result?.image = imageGIF
            self.result?.thumbnailImage = thumbnailImage
            self.result?.fileURL = filePath
            self.result?.exportProgress = 1
            self.result?.exportState = .success
        }, failure: { [weak self] videoPlayer, error in
            guard let self = self else { return }
            self.result?.exportState = .failed
        })
    }

    private func _uploadResultIfNeeded() {
        guard parameters?.resultNeedUpload == true else {
            return
        }

        guard let uploader = parameters?.resultUploader, let result = result else {
            return
        }

        result.uploadState = .uploading

        uploader.upload(result, progress: { [weak self] progress in
            guard let self = self else { return }
            self.result?.uploadProgress = progress
        }, success: { [weak self] in
            guard let self = self else { return }
            self.result?.uploadState = .successfully
        }, failure: { [weak self] error in
            guard let self = self else { return }
            self.result?.uploadState = .failed
        })
    }

    private func _updatePromptLabelText(_ text: String) {
        promptLabel.attributedText = NSAttributedString.sj_UIKitText { make in
            make.font(UIFont.systemFont(ofSize: 12)).textColor(UIColor.white)
            make.append(text)
            make.shadow { make in
                make.shadowColor = UIColor.black
                make.shadowOffset = CGSize(width: 0, height: 0.5)
            }
        }
    }

    private func _cancel() {
        if result?.exportState == .exporting {
            player?.cancelExportOperation()
            player?.cancelGenerateGIFOperation()
        }

        if result?.uploadState == .uploading, let result = result {
            parameters?.resultUploader?.cancelUpload(result)
        }

        cancelledOperationExeBlock?(self)
    }

    private func _handleClickedShareItemEvent(_ item: SJClipsResultShareItem) {
        if _needDelay {
            return
        }
        _needDelay = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?._needDelay = false
        }

        guard let clickedResultShareItemExeBlock = clickedResultShareItemExeBlock else {
            return
        }

        let strings = SJVideoPlayerConfigurations.shared.localizedStrings

        // export
        switch result?.exportState {
        case .success:
            break
        case .unknown, .cancelled, .none:
            return
        case .failed:
            player?.textPopupController.show(NSAttributedString.sj_UIKitText { make in
                make.append(strings.exportsExportFailedPrompt)
                make.textColor(UIColor.white)
            })
            return
        case .exporting:
            player?.textPopupController.show(NSAttributedString.sj_UIKitText { make in
                make.append(strings.exportsExportingPrompt)
                make.textColor(UIColor.white)
            })
            return
        @unknown default:
            return
        }

        if parameters?.resultNeedUpload != true || item.canAlsoClickedWhenUploading {
            if let player = player, let result = result {
                clickedResultShareItemExeBlock(player, item, result)
            }
            return
        }

        // upload
        switch result?.uploadState {
        case .unknown, .none:
            break
        case .cancelled:
            break
        case .failed:
            player?.textPopupController.show(NSAttributedString.sj_UIKitText { make in
                make.append(strings.uploadsUploadFailedPrompt)
                make.textColor(UIColor.white)
            })
        case .successfully:
            if let player = player, let result = result {
                clickedResultShareItemExeBlock(player, item, result)
            }
        case .uploading:
            player?.textPopupController.show(NSAttributedString.sj_UIKitText { make in
                make.append(strings.uploadsUploadingPrompt)
                make.textColor(UIColor.white)
            })
        @unknown default:
            break
        }
    }

    // MARK: -

    private func _setupViews() {
        autoAdjustTopSpacing = false
        topMargin = 20
        topHeight = 35
        backgroundColor = UIColor(white: 0, alpha: 0.5)

        _addItemToTopAdapter()
        _updateTopItemSettings()

        let coverImageView = UIImageView(frame: .zero)
        self.coverImageView = coverImageView
        coverImageView.contentMode = .scaleAspectFit
        insertSubview(coverImageView, at: 0)
        coverImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().offset(0)
        }

        let itemsContainerView = SJClipsResultShareItemsContainerView(frame: .zero)
        self.itemsContainerView = itemsContainerView
        itemsContainerView.clickedShareItemExeBlock = { [weak self] view, item in
            guard let self = self else { return }
            self._handleClickedShareItemEvent(item)
        }
        addSubview(itemsContainerView)
        itemsContainerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(0)
            make.top.equalTo(coverImageView.snp.bottom)
            make.bottom.equalTo(self)
        }

        let promptLabel = UILabel(frame: .zero)
        self.promptLabel = promptLabel
        coverImageView.addSubview(promptLabel)
        promptLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(0)
            make.bottom.equalToSuperview().offset(-8)
        }

        let flashingView = UIView(frame: .zero)
        self.flashingView = flashingView
        addSubview(flashingView)
        flashingView.snp.makeConstraints { make in
            make.edges.equalToSuperview().offset(0)
        }
    }

    private func _addItemToTopAdapter() {
        topContainerView.sjv_disappearDirection = .top
        topContainerView.cleanColors()
        sj_view_initializes(topContainerView)
        let buttonH = topHeight
        let buttonW = ceil(buttonH * 2.8)
        let containerView = SJClipsButtonContainerView(frame: .zero, buttonSize: CGSize(width: buttonW, height: buttonH))
        backButtonContainerView = containerView
        containerView.frame = CGRect(x: 0, y: 0, width: buttonW, height: buttonH)
        containerView.clickedBackButtonExeBlock = { [weak self] _ in
            guard let self = self else { return }
            self._cancel()
        }

        let backItem = SJEdgeControlButtonItem(tag: SJTopItem_Back)
        backItem.insets = SJEdgeInsetsMake(topMargin, 0)
        backItem.customView = containerView
        topAdapter.addItem(backItem)
    }

    private func _updateTopItemSettings() {
        let strings = SJVideoPlayerConfigurations.shared.localizedStrings
        let backButton = backButtonContainerView.button
        if result?.exportState != .success {
            backButton?.setTitle(strings.cancel, for: .normal)
        } else {
            backButton?.setTitle(strings.done, for: .normal)
        }
        topAdapter.reload()
    }

    // MARK: -

    public func controlView() -> UIView {
        return self
    }

    public func installedControlView(toVideoPlayer videoPlayer: SJBaseVideoPlayer) {
        player = videoPlayer
        videoPlayer.needHiddenStatusBar()
        sj_view_makeDisappear(topContainerView, false)
    }

    public func canTriggerRotation(ofVideoPlayer videoPlayer: SJBaseVideoPlayer) -> Bool {
        return false
    }

    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, gestureRecognizerShouldTrigger type: SJPlayerGestureType, location: CGPoint) -> Bool {
        return false
    }

    public func canPerformPlay(forVideoPlayer videoPlayer: SJBaseVideoPlayer) -> Bool {
        return false
    }

    public func controlLayerNeedAppear(_ videoPlayer: SJBaseVideoPlayer) {}
    public func controlLayerNeedDisappear(_ videoPlayer: SJBaseVideoPlayer) {}
}
