//
//  SJClipsGIFRecordsControlLayer.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2019/1/20.
//  Copyright © 2019 畅三江. All rights reserved.
//

import UIKit
import AVFoundation
import SJBaseVideoPlayer

//SJClipsStatus_Unknown,
//SJClipsStatus_Recording,
//SJClipsStatus_Cancelled,
//SJClipsStatus_Paused,
//SJClipsStatus_Finished,

private let SJTopItem_Back: SJEdgeControlButtonItemTag = 1
private let SJRightItem_Done: SJEdgeControlButtonItemTag = 2
private let SJBottomItem_CountDown: SJEdgeControlButtonItemTag = 3
private let SJBottomItem_LeftFill: SJEdgeControlButtonItemTag = 4
private let SJBottomItem_RightFill: SJEdgeControlButtonItemTag = 5

@objc(SJClipsGIFRecordsControlLayer)
@MainActor
public class SJClipsGIFRecordsControlLayer: SJEdgeControlLayerAdapters, SJControlLayer {

    @objc public private(set) var status: SJClipsStatus = .unknown {
        didSet {
            if status == oldValue { return }
            statusDidChangeExeBlock?(self)
        }
    }
    @objc public var statusDidChangeExeBlock: ((SJClipsGIFRecordsControlLayer) -> Void)?

    @objc public var range: CMTimeRange {
        return CMTimeRangeMake(start: start, duration: duration)
    }

    private weak var player: SJBaseVideoPlayer?
    private var backButtonContainerView: SJClipsButtonContainerView!
    private var countDownView: SJClipsGIFCountDownView!
    private var countDownTimer: Timer?
    private var countDownNum: Int = 8 {
        didSet {
            if countDownNum == oldValue { return }
            _updateBottomItemSettings()
        }
    }
    private let maxCountDownNum: Int = 8

    private var start: CMTime = .zero
    private var duration: CMTime {
        return CMTimeMakeWithSeconds(Float64(maxCountDownNum - countDownNum), preferredTimescale: 1)
    }

    // MARK: SJControlLayerRestartProtocol

    public private(set) var restarted: Bool = false

    #if DEBUG
    deinit {
        print("\(#line) - -[SJClipsGIFRecordsControlLayer dealloc]")
    }
    #endif

    public func restartControlLayer() {
        restarted = true

        sj_view_makeAppear(topContainerView, true)
        sj_view_makeAppear(rightContainerView, true)
        sj_view_makeAppear(bottomContainerView, true)
        sj_view_makeAppear(controlView(), true)
        status = .unknown
        countDownNum = maxCountDownNum
        if player?.isPlaybackFinished == true {
            start = .zero
        } else {
            start = CMTimeMake(value: Int64((player?.currentTime ?? 0) * 1000), timescale: 1000)
        }
        resume()
    }

    public func exitControlLayer() {
        restarted = false
        player = nil
        _cleanTimer()
        sj_view_makeDisappear(topContainerView, true)
        sj_view_makeDisappear(rightContainerView, true)
        sj_view_makeDisappear(bottomContainerView, true)

        sj_view_makeDisappear(controlView(), true) { [weak self] in
            guard let self = self else { return }
            if !self.restarted { self.controlView().removeFromSuperview() }
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        start = .zero
        countDownNum = maxCountDownNum
        _setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func resume() {
        if countDownTimer != nil { return }

        status = .recording

        let timer = Timer.assetAdd_timer(withTimeInterval: 1, block: { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            self.countDownNum -= 1
            if self.countDownNum == 0 {
                self.finished()
            }
            self._updateRightItemSettings()
        }, repeats: true)
        countDownTimer = timer
        timer.assetAdd_fire()
        RunLoop.main.add(timer, forMode: .common)

        player?.play()
    }

    private func pause() {
        _cleanTimer()
        status = .paused
    }

    private func cancel() {
        _cleanTimer()
        status = .cancelled
    }

    private func finished() {
        _cleanTimer()
        status = .finished
    }

    private func _cleanTimer() {
        countDownTimer?.invalidate()
        countDownTimer = nil
    }

    // MARK: actions

    @objc private func clickedDoneItem(_ item: SJEdgeControlButtonItem) {
        if CMTimeGetSeconds(duration) < 2 {
            return
        }
        finished()
    }

    // MARK: -

    private func _setupViews() {
        backgroundColor = .clear
        autoAdjustTopSpacing = false
        topMargin = 20
        bottomMargin = 20
        rightMargin = 20
        topHeight = 35
        bottomHeight = 35

        topContainerView.sjv_disappearDirection = .top
        rightContainerView.sjv_disappearDirection = .right
        bottomContainerView.sjv_disappearDirection = .bottom
        sj_view_initializes([topContainerView, rightContainerView, bottomContainerView])
        topContainerView.cleanColors()
        bottomContainerView.cleanColors()

        _addItemToTopAdapter()
        _addItemToRightAdapter()
        _addItemToBottomAdapter()

        _updateTopItemSettings()
        _updateRightItemSettings()
        _updateBottomItemSettings()
    }

    private func _addItemToTopAdapter() {
        let buttonH = topHeight
        let buttonW = ceil(buttonH * 2.8)
        let containerView = SJClipsButtonContainerView(frame: .zero, buttonSize: CGSize(width: buttonW, height: buttonH))
        backButtonContainerView = containerView
        containerView.frame = CGRect(x: 0, y: 0, width: buttonW, height: buttonH)
        containerView.clickedBackButtonExeBlock = { [weak self] _ in
            guard let self = self else { return }
            self.cancel()
        }

        let backItem = SJEdgeControlButtonItem(tag: SJTopItem_Back)
        backItem.insets = SJEdgeInsetsMake(topMargin, 0)
        backItem.customView = containerView
        topAdapter.addItem(backItem)
    }

    private func _addItemToRightAdapter() {
        let doneItem = SJEdgeControlButtonItem.placeholder(type: ._49x49, tag: SJRightItem_Done)
        doneItem.addAction(SJEdgeControlButtonItemAction(target: self, action: #selector(clickedDoneItem(_:))))
        rightAdapter.addItem(doneItem)
    }

    private func _addItemToBottomAdapter() {
        let left = SJEdgeControlButtonItem(customView: nil, tag: SJBottomItem_LeftFill)
        left.fill = true
        bottomAdapter.addItem(left)

        let view = SJClipsGIFCountDownView(frame: .zero)
        countDownView = view
        let countDownItem = SJEdgeControlButtonItem.placeholder(type: ._49xAutoresizing, tag: SJBottomItem_CountDown)
        countDownItem.customView = view
        bottomAdapter.addItem(countDownItem)

        let right = SJEdgeControlButtonItem(customView: nil, tag: SJBottomItem_RightFill)
        right.fill = true
        bottomAdapter.addItem(right)
    }

    private func _updateTopItemSettings() {
        let strings = SJVideoPlayerConfigurations.shared.localizedStrings
        let backButton = backButtonContainerView.button
        backButton?.setTitle(strings.cancel, for: .normal)
        topAdapter.reload()
    }

    private func _updateRightItemSettings() {
        let resources = SJVideoPlayerConfigurations.shared.resources
        let doneItem = rightAdapter.item(forTag: SJRightItem_Done)
        let image = CMTimeGetSeconds(duration) < 2 ? resources.recordsPreparingImage : resources.recordsToFinishRecordingImage
        if image != doneItem?.image {
            doneItem?.image = image
            rightAdapter.reload()
        }
    }

    private func _updateBottomItemSettings() {
        let strings = SJVideoPlayerConfigurations.shared.localizedStrings
        countDownView.timeLabel.text = "\(countDownNum)s"
        countDownView.promptLabel.text = CMTimeGetSeconds(duration) < 2 ? strings.recordsPreparingPrompt : strings.recordsToFinishRecordingPrompt
        bottomAdapter.reload()
    }

    // MARK: -

    public func controlView() -> UIView {
        return self
    }

    public func installedControlView(toVideoPlayer videoPlayer: SJBaseVideoPlayer) {
        player = videoPlayer
        videoPlayer.needHiddenStatusBar()
        sj_view_makeDisappear(topContainerView, false)
        sj_view_makeDisappear(rightContainerView, false)
        sj_view_makeDisappear(bottomContainerView, false)
    }

    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer, gestureRecognizerShouldTrigger type: SJPlayerGestureType, location: CGPoint) -> Bool {
        return false
    }

    public func canTriggerRotation(ofVideoPlayer videoPlayer: SJBaseVideoPlayer) -> Bool {
        return false
    }

    public func videoPlayerPlaybackStatusDidChange(_ videoPlayer: SJBaseVideoPlayer) {
        if videoPlayer.isPlaybackFinished {
            finished()
        } else if videoPlayer.assetStatus == .failed {
            cancel()
        } else if videoPlayer.timeControlStatus == .paused {
            pause()
        } else if status != .recording {
            resume()
        }
    }

    public func controlLayerNeedAppear(_ videoPlayer: SJBaseVideoPlayer) { /* nothing */ }
    public func controlLayerNeedDisappear(_ videoPlayer: SJBaseVideoPlayer) { /* nothing */ }

    public func applicationDidBecomeActive(withVideoPlayer videoPlayer: SJBaseVideoPlayer) {
        if status == .paused {
            videoPlayer.play()
        }
    }

    // MARK: -

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let currentContext = UIGraphicsGetCurrentContext() else { return }
        currentContext.setStrokeColor(UIColor.white.cgColor)
        currentContext.setLineWidth(1)
        let arr: [CGFloat] = [6, 3]

        // 0,0 -> W,0
        currentContext.move(to: CGPoint(x: 1, y: 1))
        currentContext.addLine(to: CGPoint(x: bounds.size.width, y: 1))
        currentContext.setLineDash(phase: 0, lengths: arr)
        currentContext.drawPath(using: .stroke)

        // 0,0 -> 0,H
        currentContext.move(to: CGPoint(x: 1, y: 1))
        currentContext.addLine(to: CGPoint(x: 1, y: bounds.size.height))
        currentContext.setLineDash(phase: 0, lengths: arr)
        currentContext.drawPath(using: .stroke)

        // 0,H -> W,H
        currentContext.move(to: CGPoint(x: 1, y: bounds.size.height - 1))
        currentContext.addLine(to: CGPoint(x: bounds.size.width, y: bounds.size.height - 1))
        currentContext.setLineDash(phase: 0, lengths: arr)
        currentContext.drawPath(using: .stroke)

        // W,0 -> W,H
        currentContext.move(to: CGPoint(x: bounds.size.width - 1, y: 1))
        currentContext.addLine(to: CGPoint(x: bounds.size.width - 1, y: bounds.size.height))
        currentContext.setLineDash(phase: 0, lengths: arr)
        currentContext.drawPath(using: .stroke)
    }
}
