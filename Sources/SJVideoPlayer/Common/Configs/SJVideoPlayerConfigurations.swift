//
//  SJVideoPlayerConfigurations.swift
//  SJVideoPlayerProject
//
//  Created by 畅三江 on 2017/9/25.
//  Copyright © 2017年 changsanjiang. All rights reserved.
//
//  Swift 6 迁移版本 (SJVideoPlayer module)
//  对应 ObjC: Common/Configs/SJVideoPlayerConfigurations.h / .m
//

import Foundation
import UIKit
import AVKit

/// 配置装载 / 更新完成后在主线程 post 的通知名.
/// (原 ObjC: SJVideoPlayerConfigurationsDidUpdateNotification, 字符串字面量保持不变.)
public let SJVideoPlayerConfigurationsDidUpdateNotification = Notification.Name("SJVideoPlayerConfigurationsDidUpdateNotification")

// MARK: - SJVideoPlayerControlLayerResources (协议)

/// 控制层外观资源协议.
///
/// 撞名说明: 该协议与 .m 内同名私有实现类撞名, 按全局规则协议加 `_Protocol` 后缀,
/// 但仍以 `@objc(SJVideoPlayerControlLayerResources)` 暴露原 ObjC 名; 实现类改名为
/// `SJVideoPlayerControlLayerResourcesImpl` 并保持私有.
@objc(SJVideoPlayerControlLayerResources)
public protocol SJVideoPlayerControlLayerResources_Protocol: NSObjectProtocol {

    @objc var placeholder: UIImage? { get set }

    // MARK: - SJEdgeControlLayer Resources

    // picture in picture
    @available(iOS 14.0, *)
    @objc var pictureInPictureItemStartImage: UIImage? { get set }
    @available(iOS 14.0, *)
    @objc var pictureInPictureItemStopImage: UIImage? { get set }

    // speedup playback popup view(长按快进时显示的视图)
    @objc var speedupPlaybackTriangleColor: UIColor? { get set }
    @objc var speedupPlaybackRateTextColor: UIColor? { get set }
    @objc var speedupPlaybackRateTextFont: UIFont? { get set }
    @objc var speedupPlaybackTextColor: UIColor? { get set }
    @objc var speedupPlaybackTextFont: UIFont? { get set }

    // loading view
    @objc var loadingNetworkSpeedTextColor: UIColor? { get set }
    @objc var loadingNetworkSpeedTextFont: UIFont? { get set }
    @objc var loadingLineColor: UIColor? { get set }

    // dragging view
    @objc var fastImage: UIImage? { get set }
    @objc var forwardImage: UIImage? { get set }

    // custom status bar
    @objc var batteryBorderImage: UIImage? { get set }
    @objc var batteryNubImage: UIImage? { get set }
    @objc var batteryLightningImage: UIImage? { get set }

    // top adapter items
    @objc var backImage: UIImage? { get set }
    @objc var moreImage: UIImage? { get set }
    @objc var titleLabelFont: UIFont? { get set }
    @objc var titleLabelColor: UIColor? { get set }

    // left adapter items
    @objc var lockImage: UIImage? { get set }
    @objc var unlockImage: UIImage? { get set }

    // bottom adapter items
    @objc var pauseImage: UIImage? { get set }
    @objc var playImage: UIImage? { get set }

    @objc var timeLabelFont: UIFont? { get set }
    @objc var timeLabelColor: UIColor? { get set }

    @objc var smallScreenImage: UIImage? { get set }                  // 缩回小屏的图片
    @objc var fullscreenImage: UIImage? { get set }                   // 全屏的图片

    @objc var progressTrackColor: UIColor? { get set }                // 轨道颜色
    @objc var progressTrackHeight: Float { get set }                  // 轨道高度
    @objc var progressTraceColor: UIColor? { get set }                // 轨迹颜色, 走过的痕迹
    @objc var progressBufferColor: UIColor? { get set }               // 缓冲颜色
    @objc var progressThumbColor: UIColor? { get set }                // 滑块颜色, 请设置滑块大小
    @objc var progressThumbImage: UIImage? { get set }                // 滑块图片, 优先使用, 为nil时将会使用滑块颜色
    @objc var progressThumbSize: Float { get set }                    // 滑块大小

    @objc var bottomIndicatorTrackColor: UIColor? { get set }         // 底部指示条轨道颜色
    @objc var bottomIndicatorTraceColor: UIColor? { get set }         // 底部指示条轨迹颜色
    @objc var bottomIndicatorHeight: Float { get set }               // 底部指示条高度

    // right adapter items
    @objc var clipsImage: UIImage? { get set }

    // center adapter items
    @objc var replayTitleColor: UIColor? { get set }
    @objc var replayTitleFont: UIFont? { get set }
    @objc var replayImage: UIImage? { get set }

    // MARK: - SJMoreSettingControlLayer Resources

    @objc var moreControlLayerBackgroundColor: UIColor? { get set }
    @objc var moreSliderTraceColor: UIColor? { get set }              // sider trace color of more view
    @objc var moreSliderTrackColor: UIColor? { get set }              // sider track color of more view
    @objc var moreSliderTrackHeight: Float { get set }               // sider track height of more view
    @objc var moreSliderThumbImage: UIImage? { get set }              // sider thumb image of more view
    @objc var moreSliderThumbSize: Float { get set }                 // sider thumb size of more view
    @objc var moreSliderMinRateValue: Float { get set }              // 最小播放倍速值
    @objc var moreSliderMaxRateValue: Float { get set }              // 最大播放倍速值
    @objc var moreSliderMinRateImage: UIImage? { get set }            // 最小播放倍速图标
    @objc var moreSliderMaxRateImage: UIImage? { get set }            // 最大播放倍速图标
    @objc var moreSliderMinVolumeImage: UIImage? { get set }
    @objc var moreSliderMaxVolumeImage: UIImage? { get set }
    @objc var moreSliderMinBrightnessImage: UIImage? { get set }
    @objc var moreSliderMaxBrightnessImage: UIImage? { get set }

    // MARK: - SJLoadFailedControlLayer Resources

    @objc var playFailedButtonBackgroundColor: UIColor? { get set }

    // MARK: - SJNotReachableControlLayer Resources

    @objc var noNetworkButtonBackgroundColor: UIColor? { get set }

    // MARK: - SJSmallViewControlLayer Resources

    @objc var floatSmallViewCloseImage: UIImage? { get set }

    // MARK: - SJClipsControlLayer Resources

    @objc var screenshotImage: UIImage? { get set }
    @objc var videoClipImage: UIImage? { get set }
    @objc var GIFClipImage: UIImage? { get set }

    @objc var recordsPreparingImage: UIImage? { get set }
    @objc var recordsToFinishRecordingImage: UIImage? { get set }
}

// MARK: - SJVideoPlayerLocalizedStrings (协议)

/// 本地化文案协议.
///
/// 撞名说明: 该协议与 .m 内同名私有实现类撞名, 协议加 `_Protocol` 后缀,
/// 仍以 `@objc(SJVideoPlayerLocalizedStrings)` 暴露原名; 实现类改名为
/// `SJVideoPlayerLocalizedStringsImpl` 并保持私有.
///
/// 注意拼写: `noNetWork`(大写 W)、`WiFiNetwork`, 与 ObjC 原属性名严格一致.
@objc(SJVideoPlayerLocalizedStrings)
public protocol SJVideoPlayerLocalizedStrings_Protocol: NSObjectProtocol {

    @objc(setFromBundle:)
    func setFromBundle(_ bundle: Bundle?)

    @objc var longPressSpeedupPlayback: String { get set }

    @objc var noNetWork: String { get set }
    @objc var WiFiNetwork: String { get set }
    @objc var cellularNetwork: String { get set }

    @objc var replay: String { get set }
    @objc var retry: String { get set }
    @objc var reload: String { get set }
    @objc var liveBroadcast: String { get set }
    @objc var cancel: String { get set }
    @objc var done: String { get set }

    @objc var unstableNetworkPrompt: String { get set }
    @objc var cellularNetworkPrompt: String { get set }
    @objc var noNetworkPrompt: String { get set }
    @objc var playbackFailedPrompt: String { get set }

    @objc var recordsPreparingPrompt: String { get set }
    @objc var recordsToFinishRecordingPrompt: String { get set }

    @objc var exportsExportingPrompt: String { get set }
    @objc var exportsExportFailedPrompt: String { get set }
    @objc var exportsExportSuccessfullyPrompt: String { get set }

    @objc var uploadsUploadingPrompt: String { get set }
    @objc var uploadsUploadFailedPrompt: String { get set }
    @objc var uploadsUploadSuccessfullyPrompt: String { get set }

    @objc var screenshotSuccessfullyPrompt: String { get set }

    @objc var albumAuthDeniedPrompt: String { get set }
    @objc var albumSavingScreenshotToAlbumPrompt: String { get set }
    @objc var albumSavedToAlbumPrompt: String { get set }

    @objc var operationFailedPrompt: String { get set }

    @objc var definitionSwitchingPrompt: String { get set }
    @objc var definitionSwitchSuccessfullyPrompt: String { get set }
    @objc var definitionSwitchFailedPrompt: String { get set }
}

// MARK: - SJVideoPlayerConfigurations

/// 全局配置单例.
///
/// 设计说明 (Swift6 严格并发):
/// - 该类为纯配置模型, 不标 `@MainActor`; 但需在多线程下安全读写 `localizedStrings` /
///   `resources` / `animationDuration`, 故内部用串行队列 + 屏障语义保护可变状态,
///   存储以 `nonisolated(unsafe)` 声明并自行加锁, 整体声明 `@unchecked Sendable`.
/// - 原 ObjC 版用 `dispatch_group` 在子线程分块装载资源后整体生效; 这里改为
///   **同步构造资源对象后整体赋值**(全局规则 §0.9 / §0.22 允许), 资源对象一旦返回即已装载完毕,
///   行为对消费方严格更优且兼容(装载完成后仍在主线程 post `...DidUpdateNotification`).
/// - `update(block:)` 的 "block 将在子线程执行" 语义与注释保留: block 投递到全局队列执行.
@objc(SJVideoPlayerConfigurations)
public final class SJVideoPlayerConfigurations: NSObject, @unchecked Sendable {

    // 保护可变状态的串行队列.
    private let lockQueue = DispatchQueue(label: "com.sjvideoplayer.configurations.lock")

    nonisolated(unsafe) private var _localizedStrings: (any SJVideoPlayerLocalizedStrings_Protocol)?
    nonisolated(unsafe) private var _resources: (any SJVideoPlayerControlLayerResources_Protocol)?
    nonisolated(unsafe) private var _animationDuration: TimeInterval = 0.4

    @objc(shared)
    public static let shared = SJVideoPlayerConfigurations()

    private override init() {
        super.init()
        // 触发懒加载, 与 ObjC init 中 [self localizedStrings] / [self resources] 行为一致.
        _ = self.localizedStrings
        _ = self.resources
    }

    ///
    /// 更新
    ///
    /// \code
    ///
    ///     SJVideoPlayerConfigurations.update { configs in
    ///         // 注意, 该block将在子线程执行
    ///         configs.resources.backImage = UIImage(named: "icon_back")
    ///     }
    ///
    /// \endcode
    ///
    @objc(update)
    public static var update: (@escaping (SJVideoPlayerConfigurations) -> Void) -> Void {
        return { block in
            let configs = SJVideoPlayerConfigurations.shared
            // 注意: block 将在子线程执行 (保留原 ObjC 语义).
            DispatchQueue.global().async {
                block(configs)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: SJVideoPlayerConfigurationsDidUpdateNotification, object: configs)
                }
            }
        }
    }

    @objc public var localizedStrings: any SJVideoPlayerLocalizedStrings_Protocol {
        get {
            lockQueue.sync {
                if _localizedStrings == nil {
                    let strings = SJVideoPlayerLocalizedStringsImpl()
                    // 同步装载: 资源对象返回时已就绪.
                    strings.setFromBundle(SJVideoPlayerResourceLoader.preferredLanguageBundle)
                    _localizedStrings = strings
                    // 装载完成后主线程 post 通知, 与原 ObjC 行为一致.
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        NotificationCenter.default.post(name: SJVideoPlayerConfigurationsDidUpdateNotification, object: self)
                    }
                }
                return _localizedStrings!
            }
        }
        set {
            // null_resettable: 置 nil 时下次读取重新懒加载.
            lockQueue.sync { _localizedStrings = newValue }
        }
    }

    @objc public var resources: any SJVideoPlayerControlLayerResources_Protocol {
        get {
            lockQueue.sync {
                if _resources == nil {
                    let resources = SJVideoPlayerControlLayerResourcesImpl()
                    // 同步分块装载 (对应原 6 个 dispatch_group_async 装载方法), 整体生效.
                    resources.loadSJEdgeControlLayerResources()
                    resources.loadSJMoreSettingControlLayerResources()
                    resources.loadSJLoadFailedControlLayerResources()
                    resources.loadSJNotReachableControlLayerResources()
                    resources.loadSJSmallViewControlLayerResources()
                    resources.loadSJClipsControlLayerResources()
                    _resources = resources
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        NotificationCenter.default.post(name: SJVideoPlayerConfigurationsDidUpdateNotification, object: self)
                    }
                }
                return _resources!
            }
        }
        set {
            lockQueue.sync { _resources = newValue }
        }
    }

    @objc public var animationDuration: TimeInterval { // default value is 0.4
        get { lockQueue.sync { _animationDuration } }
        set { lockQueue.sync { _animationDuration = newValue } }
    }
}

// MARK: - SJVideoPlayerControlLayerResourcesImpl (私有实现类)

/// `SJVideoPlayerControlLayerResources_Protocol` 的默认实现 (原 ObjC .m 内私有同名类).
private final class SJVideoPlayerControlLayerResourcesImpl: NSObject, SJVideoPlayerControlLayerResources_Protocol {

    var placeholder: UIImage?

    // picture in picture (iOS 14.0+; 用底层存储承载, 协议属性按可用性声明)
    private var _pictureInPictureItemStartImage: UIImage?
    private var _pictureInPictureItemStopImage: UIImage?
    @available(iOS 14.0, *)
    var pictureInPictureItemStartImage: UIImage? {
        get { _pictureInPictureItemStartImage }
        set { _pictureInPictureItemStartImage = newValue }
    }
    @available(iOS 14.0, *)
    var pictureInPictureItemStopImage: UIImage? {
        get { _pictureInPictureItemStopImage }
        set { _pictureInPictureItemStopImage = newValue }
    }

    var speedupPlaybackTriangleColor: UIColor?
    var speedupPlaybackRateTextColor: UIColor?
    var speedupPlaybackRateTextFont: UIFont?
    var speedupPlaybackTextColor: UIColor?
    var speedupPlaybackTextFont: UIFont?

    var loadingNetworkSpeedTextColor: UIColor?
    var loadingNetworkSpeedTextFont: UIFont?
    var loadingLineColor: UIColor?

    var fastImage: UIImage?
    var forwardImage: UIImage?

    var batteryBorderImage: UIImage?
    var batteryNubImage: UIImage?
    var batteryLightningImage: UIImage?

    var backImage: UIImage?
    var moreImage: UIImage?
    var titleLabelFont: UIFont?
    var titleLabelColor: UIColor?

    var lockImage: UIImage?
    var unlockImage: UIImage?

    var pauseImage: UIImage?
    var playImage: UIImage?

    var timeLabelFont: UIFont?
    var timeLabelColor: UIColor?

    var smallScreenImage: UIImage?
    var fullscreenImage: UIImage?

    var progressTrackColor: UIColor?
    var progressTrackHeight: Float = 0
    var progressTraceColor: UIColor?
    var progressBufferColor: UIColor?
    var progressThumbColor: UIColor?
    var progressThumbImage: UIImage?
    var progressThumbSize: Float = 0

    var bottomIndicatorTrackColor: UIColor?
    var bottomIndicatorTraceColor: UIColor?
    var bottomIndicatorHeight: Float = 0

    var clipsImage: UIImage?

    var replayTitleColor: UIColor?
    var replayTitleFont: UIFont?
    var replayImage: UIImage?

    var moreControlLayerBackgroundColor: UIColor?
    var moreSliderTraceColor: UIColor?
    var moreSliderTrackColor: UIColor?
    var moreSliderTrackHeight: Float = 0
    var moreSliderThumbImage: UIImage?
    var moreSliderThumbSize: Float = 0
    var moreSliderMinRateValue: Float = 0
    var moreSliderMaxRateValue: Float = 0
    var moreSliderMinRateImage: UIImage?
    var moreSliderMaxRateImage: UIImage?
    var moreSliderMinVolumeImage: UIImage?
    var moreSliderMaxVolumeImage: UIImage?
    var moreSliderMinBrightnessImage: UIImage?
    var moreSliderMaxBrightnessImage: UIImage?

    var playFailedButtonBackgroundColor: UIColor?

    var noNetworkButtonBackgroundColor: UIColor?

    var floatSmallViewCloseImage: UIImage?

    var screenshotImage: UIImage?
    var videoClipImage: UIImage?
    var GIFClipImage: UIImage?

    var recordsPreparingImage: UIImage?
    var recordsToFinishRecordingImage: UIImage?

    // MARK: 分块装载 (对应 ObjC 的 _loadSJ*Resources 方法)

    func loadSJEdgeControlLayerResources() {
        if #available(iOS 14.0, *) {
            _pictureInPictureItemStartImage = AVPictureInPictureController.pictureInPictureButtonStartImage
                .withTintColor(.white)
                .withRenderingMode(.alwaysOriginal)
            _pictureInPictureItemStopImage = AVPictureInPictureController.pictureInPictureButtonStopImage
                .withTintColor(.white)
                .withRenderingMode(.alwaysOriginal)
        }

        speedupPlaybackTriangleColor = .white
        speedupPlaybackRateTextColor = .white
        speedupPlaybackRateTextFont = UIFont.boldSystemFont(ofSize: 12)
        speedupPlaybackTextColor = .white
        speedupPlaybackTextFont = UIFont.boldSystemFont(ofSize: 12)

        loadingNetworkSpeedTextColor = .white
        loadingNetworkSpeedTextFont = UIFont.systemFont(ofSize: 11)
        loadingLineColor = .white

        fastImage = SJVideoPlayerResourceLoader.image(named: "sj_video_player_fast")
        forwardImage = SJVideoPlayerResourceLoader.image(named: "sj_video_player_forward")

        batteryBorderImage = SJVideoPlayerResourceLoader.image(named: "battery_border")
        batteryNubImage = SJVideoPlayerResourceLoader.image(named: "battery_nub")
        batteryLightningImage = SJVideoPlayerResourceLoader.image(named: "battery_lightning")

        backImage = SJVideoPlayerResourceLoader.image(named: "sj_video_player_back")
        moreImage = SJVideoPlayerResourceLoader.image(named: "sj_video_player_more")
        titleLabelFont = UIFont.boldSystemFont(ofSize: 14)
        titleLabelColor = .white

        lockImage = SJVideoPlayerResourceLoader.image(named: "sj_video_player_lock")
        unlockImage = SJVideoPlayerResourceLoader.image(named: "sj_video_player_unlock")

        pauseImage = SJVideoPlayerResourceLoader.image(named: "sj_video_player_pause")
        playImage = SJVideoPlayerResourceLoader.image(named: "sj_video_player_play")
        timeLabelFont = UIFont.systemFont(ofSize: 11)
        timeLabelColor = .white

        smallScreenImage = SJVideoPlayerResourceLoader.image(named: "sj_video_player_shrinkscreen")
        fullscreenImage = SJVideoPlayerResourceLoader.image(named: "sj_video_player_fullscreen")

        progressTrackColor = .white
        progressTrackHeight = 3
        progressTraceColor = UIColor(red: 2 / 256.0, green: 141 / 256.0, blue: 140 / 256.0, alpha: 1)
        progressBufferColor = UIColor(white: 0, alpha: 0.2)
        progressThumbColor = progressTraceColor

        bottomIndicatorTrackColor = progressTrackColor
        bottomIndicatorTraceColor = progressTraceColor
        bottomIndicatorHeight = 1

        clipsImage = SJVideoPlayerResourceLoader.image(named: "sj_video_player_clips")

        replayTitleColor = .white
        replayTitleFont = UIFont.boldSystemFont(ofSize: 12)
        replayImage = SJVideoPlayerResourceLoader.image(named: "sj_video_player_replay")
    }

    func loadSJMoreSettingControlLayerResources() {
        moreControlLayerBackgroundColor = UIColor(white: 0, alpha: 0.8)
        moreSliderTraceColor = UIColor(red: 2 / 256.0, green: 141 / 256.0, blue: 140 / 256.0, alpha: 1)
        moreSliderTrackColor = .white
        moreSliderTrackHeight = 4
        moreSliderMinRateValue = 0.5
        moreSliderMaxRateValue = 1.5
        moreSliderMinRateImage = SJVideoPlayerResourceLoader.image(named: "sj_video_player_minRate")
        moreSliderMaxRateImage = SJVideoPlayerResourceLoader.image(named: "sj_video_player_maxRate")
        moreSliderMinVolumeImage = SJVideoPlayerResourceLoader.image(named: "sj_video_player_minVolume")
        moreSliderMaxVolumeImage = SJVideoPlayerResourceLoader.image(named: "sj_video_player_maxVolume")
        moreSliderMinBrightnessImage = SJVideoPlayerResourceLoader.image(named: "sj_video_player_minBrightness")
        moreSliderMaxBrightnessImage = SJVideoPlayerResourceLoader.image(named: "sj_video_player_maxBrightness")
    }

    func loadSJLoadFailedControlLayerResources() {
        playFailedButtonBackgroundColor = UIColor(red: 36 / 255.0, green: 171 / 255.0, blue: 1, alpha: 1)
    }

    func loadSJNotReachableControlLayerResources() {
        noNetworkButtonBackgroundColor = UIColor(red: 36 / 255.0, green: 171 / 255.0, blue: 1, alpha: 1)
    }

    func loadSJSmallViewControlLayerResources() {
        floatSmallViewCloseImage = SJVideoPlayerResourceLoader.image(named: "close")
    }

    func loadSJClipsControlLayerResources() {
        screenshotImage = SJVideoPlayerResourceLoader.image(named: "screenshot")
        videoClipImage = SJVideoPlayerResourceLoader.image(named: "video_clip")
        GIFClipImage = SJVideoPlayerResourceLoader.image(named: "gif_clip")

        recordsPreparingImage = SJVideoPlayerResourceLoader.image(named: "records_preparing")
        recordsToFinishRecordingImage = SJVideoPlayerResourceLoader.image(named: "records_finish")
    }
}

// MARK: - SJVideoPlayerLocalizedStringsImpl (私有实现类)

/// `SJVideoPlayerLocalizedStrings_Protocol` 的默认实现 (原 ObjC .m 内私有同名类).
private final class SJVideoPlayerLocalizedStringsImpl: NSObject, SJVideoPlayerLocalizedStrings_Protocol {

    private var _bundle: Bundle?

    var longPressSpeedupPlayback: String = ""

    var noNetWork: String = ""
    var WiFiNetwork: String = ""
    var cellularNetwork: String = ""

    var replay: String = ""
    var retry: String = ""
    var reload: String = ""
    var liveBroadcast: String = ""
    var cancel: String = ""
    var done: String = ""

    var unstableNetworkPrompt: String = ""
    var cellularNetworkPrompt: String = ""
    var noNetworkPrompt: String = ""
    var playbackFailedPrompt: String = ""

    var recordsPreparingPrompt: String = ""
    var recordsToFinishRecordingPrompt: String = ""

    var exportsExportingPrompt: String = ""
    var exportsExportFailedPrompt: String = ""
    var exportsExportSuccessfullyPrompt: String = ""

    var uploadsUploadingPrompt: String = ""
    var uploadsUploadFailedPrompt: String = ""
    var uploadsUploadSuccessfullyPrompt: String = ""

    var screenshotSuccessfullyPrompt: String = ""

    var albumAuthDeniedPrompt: String = ""
    var albumSavingScreenshotToAlbumPrompt: String = ""
    var albumSavedToAlbumPrompt: String = ""

    var operationFailedPrompt: String = ""

    var definitionSwitchingPrompt: String = ""
    var definitionSwitchSuccessfullyPrompt: String = ""
    var definitionSwitchFailedPrompt: String = ""

    func setFromBundle(_ bundle: Bundle?) {
        _bundle = bundle
        longPressSpeedupPlayback = localizedString(forKey: SJVideoPlayerLocalizedStringKeyLongPressSpeedupPlayback)
        noNetWork = localizedString(forKey: SJVideoPlayerLocalizedStringKeyNoNetwork)
        WiFiNetwork = localizedString(forKey: SJVideoPlayerLocalizedStringKeyWiFiNetWork)
        cellularNetwork = localizedString(forKey: SJVideoPlayerLocalizedStringKeyCellularNetwork)
        replay = localizedString(forKey: SJVideoPlayerLocalizedStringKeyReplay)
        retry = localizedString(forKey: SJVideoPlayerLocalizedStringKeyRetry)
        reload = localizedString(forKey: SJVideoPlayerLocalizedStringKeyReload)
        liveBroadcast = localizedString(forKey: SJVideoPlayerLocalizedStringKeyLiveBroadcast)
        cancel = localizedString(forKey: SJVideoPlayerLocalizedStringKeyCancel)
        done = localizedString(forKey: SJVideoPlayerLocalizedStringKeyDone)
        unstableNetworkPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyUnstableNetworkPrompt)
        cellularNetworkPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyCellularNetworkPrompt)
        noNetworkPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyNoNetworkPrompt)
        playbackFailedPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyPlaybackFailedPrompt)
        recordsPreparingPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyRecordsPreparingPrompt)
        recordsToFinishRecordingPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyRecordsToFinishRecordingPrompt)
        exportsExportingPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyExportsExportingPrompt)
        exportsExportFailedPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyExportsExportFailedPrompt)
        exportsExportSuccessfullyPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyExportsExportSuccessfullyPrompt)
        uploadsUploadingPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyUploadsUploadingPrompt)
        uploadsUploadFailedPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyUploadsUploadFailedPrompt)
        uploadsUploadSuccessfullyPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyUploadsUploadSuccessfullyPrompt)
        screenshotSuccessfullyPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyScreenshotSuccessfullyPrompt)
        albumAuthDeniedPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyAlbumAuthDeniedPrompt)
        albumSavingScreenshotToAlbumPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyAlbumSavingScreenshotToAlbumPrompt)
        albumSavedToAlbumPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyAlbumSavedToAlbumPrompt)
        operationFailedPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyOperationFailedPrompt)
        definitionSwitchingPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyDefinitionSwitchingPrompt)
        definitionSwitchSuccessfullyPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyDefinitionSwitchSuccessfullyPrompt)
        definitionSwitchFailedPrompt = localizedString(forKey: SJVideoPlayerLocalizedStringKeyDefinitionSwitchFailedPrompt)
    }

    /// 与原 ObjC 行为一致: 先尝试从给定 bundle 取值 (当其非 mainBundle 时),
    /// 再以该值为 fallback 从 mainBundle 取值, 允许宿主 App 覆盖文案.
    private func localizedString(forKey key: String) -> String {
        let mainBundle = Bundle.main
        let value: String? = (_bundle != nil && _bundle != mainBundle)
            ? _bundle?.localizedString(forKey: key, value: nil, table: nil)
            : nil
        return mainBundle.localizedString(forKey: key, value: value, table: nil)
    }
}
