//
//  SJDraggingProgressPopupView.swift
//  Pods
//
//  Created by 畅三江 on 2019/11/27.
//
//  Swift 6.3 转换: SJDraggingProgressPopupView.h / .m 合并.
//  撞名(协议 + 同名类): 协议加 _Protocol 后缀, 类保持原名.
//  布局 Masonry → SnapKit; 去掉 __has_include 防御式双写.
//

import UIKit
import SnapKit
import SJBaseVideoPlayer

/// 拖动进度预览弹窗.
///
/// 内嵌 `SJProgressSlider`, 支持三种样式(普通 / 全屏 / 适配屏幕), 监听配置更新通知刷新外观.
@objc(SJDraggingProgressPopupView)
@MainActor
public final class SJDraggingProgressPopupView: UIView, SJDraggingProgressPopupView_Protocol {

    // MARK: - 子视图

    private let contentView = UIView()
    private let progressSlider = SJProgressSlider()
    private let directionImageView = UIImageView(frame: .zero)
    private let previewImageView = UIImageView(frame: .zero)

    private let dragTimeLabel = UILabel(frame: .zero)
    private let separatorLabel = UILabel(frame: .zero) // `/`
    private let durationLabel = UILabel(frame: .zero)

    // MARK: - 协议属性存储

    private var _style: SJDraggingProgressPopupViewStyle = .normal
    private var _dragTime: TimeInterval = 0
    private var _currentTime: TimeInterval = 0
    private var _duration: TimeInterval = 0

    // MARK: - 初始化

    @objc public override init(frame: CGRect) {
        super.init(frame: frame)
        _setupViews()
        _updateSettings()
        NotificationCenter.default.addObserver(self, selector: #selector(_updateSettings), name: SJVideoPlayerConfigurationsDidUpdateNotification, object: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - SJDraggingProgressPopupView_Protocol

    @objc public var style: SJDraggingProgressPopupViewStyle {
        get { _style }
        set {
            if newValue != _style {
                _style = newValue
                _resetLayout()
            }
        }
    }

    @objc public var dragTime: TimeInterval {
        get { _dragTime }
        set {
            let sources = SJVideoPlayerConfigurations.shared.resources
            if newValue > _dragTime {
                directionImageView.image = sources.fastImage
            } else if newValue < _dragTime {
                directionImageView.image = sources.forwardImage
            }
            progressSlider.value = newValue
            dragTimeLabel.text = NSString.string(withCurrentTime: newValue, duration: _duration) as String
            _dragTime = newValue
        }
    }

    @objc public var currentTime: TimeInterval {
        get { _currentTime }
        set {
            if _currentTime != newValue {
                _currentTime = newValue
                progressSlider.bufferProgress = newValue / progressSlider.maxValue
            }
        }
    }

    @objc public var duration: TimeInterval {
        get { _duration }
        set {
            if _duration != newValue {
                _duration = newValue
                progressSlider.maxValue = newValue != 0 ? newValue : 1
                durationLabel.text = NSString.string(withCurrentTime: newValue, duration: newValue) as String
            }
        }
    }

    @objc public var previewImage: UIImage? {
        get { previewImageView.image }
        set { previewImageView.image = newValue }
    }

    ///
    /// 当需要显示预览时, 可以返回 NO(false), 管理类将会设置 previewImage.
    ///
    @objc(isPreviewImageHidden)
    public var previewImageHidden: Bool {
        _style != .fullscreen
    }

    // MARK: - 视图搭建

    private func _setupViews() {
        contentView.layer.cornerRadius = 8
        contentView.backgroundColor = UIColor(white: 0, alpha: 0.8)
        addSubview(contentView)

        progressSlider.trackHeight = 3
        progressSlider.showsBufferProgress = true
        progressSlider.pan.isEnabled = false
        contentView.addSubview(progressSlider)

        directionImageView.contentMode = .scaleAspectFit
        contentView.addSubview(directionImageView)

        dragTimeLabel.font = .systemFont(ofSize: 13)
        dragTimeLabel.textColor = .white
        dragTimeLabel.textAlignment = .right
        contentView.addSubview(dragTimeLabel)

        separatorLabel.font = .systemFont(ofSize: 13)
        separatorLabel.textColor = .white
        separatorLabel.text = "/"
        contentView.addSubview(separatorLabel)

        durationLabel.font = .systemFont(ofSize: 13)
        durationLabel.textColor = .white
        durationLabel.textAlignment = .left
        contentView.addSubview(durationLabel)

        previewImageView.contentMode = .scaleAspectFit
        previewImageView.layer.cornerRadius = 8
        previewImageView.layer.masksToBounds = true
        contentView.addSubview(previewImageView)

        _resetLayout()

        dragTimeLabel.snp.makeConstraints { make in
            make.right.equalTo(self.separatorLabel.snp.left)
            make.centerY.equalTo(self.separatorLabel)
            make.left.equalToSuperview().offset(0)
        }

        durationLabel.snp.makeConstraints { make in
            make.left.equalTo(self.separatorLabel.snp.right)
            make.centerY.equalTo(self.separatorLabel)
            make.right.equalToSuperview().offset(0)
        }
    }

    // MARK: - 布局

    private func _resetLayout() {
        switch _style {
        case .normal, .fitOnScreen:
            _resetLayout_normalStyle()
        case .fullscreen:
            _resetLayout_fullscreenStyle()
        }
    }

    private func _resetLayout_normalStyle() {
        previewImageView.isHidden = true
        progressSlider.trackHeight = 3

        contentView.snp.remakeConstraints { make in
            make.edges.equalToSuperview().offset(0)
            let width: CGFloat = 150
            let height = width * 8 / 15
            make.size.equalTo(CGSize(width: width, height: ceil(height)))
        }

        previewImageView.snp.remakeConstraints { _ in }

        directionImageView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(0)
            make.bottom.equalTo(self.snp.centerY)
            make.centerX.equalToSuperview().offset(0)
        }

        progressSlider.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.top.equalTo(self.snp.centerY).offset(8)
            make.height.equalToSuperview().offset(3)
        }

        separatorLabel.snp.remakeConstraints { make in
            make.centerX.equalToSuperview().offset(0)
            make.top.equalTo(self.progressSlider.snp.bottom)
            make.bottom.equalToSuperview().offset(0)
            make.width.equalToSuperview().offset(5)
        }
    }

    private func _resetLayout_fullscreenStyle() {
        contentView.snp.remakeConstraints { make in
            make.edges.equalToSuperview().offset(0)
        }

        previewImageView.isHidden = false
        progressSlider.trackHeight = 2

        directionImageView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalTo(self.previewImageView.snp.top).offset(-8)
            make.height.equalToSuperview().offset(20)
            make.centerX.equalTo(self).multipliedBy(0.25)
        }

        separatorLabel.snp.remakeConstraints { make in
            make.centerX.equalToSuperview().offset(0)
            make.centerY.equalTo(self.directionImageView)
            make.width.equalToSuperview().offset(4)
        }

        previewImageView.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.bottom.right.equalToSuperview().offset(-8)
            make.width.equalToSuperview().offset(180)
            make.height.equalTo(self.previewImageView.snp.width).multipliedBy(9.0 / 16)
        }

        progressSlider.snp.remakeConstraints { make in
            make.centerX.equalToSuperview().offset(0)
            make.top.equalTo(self.separatorLabel.snp.bottom)
            make.bottom.equalTo(self.previewImageView.snp.top)
            make.width.equalToSuperview().offset(68)
        }
    }

    // MARK: - 外观更新

    @objc private func _updateSettings() {
        let resources = SJVideoPlayerConfigurations.shared.resources
        dragTimeLabel.textColor = resources.progressTraceColor
        progressSlider.traceImageView.backgroundColor = resources.progressTraceColor
        progressSlider.trackImageView.backgroundColor = resources.progressTrackColor
        progressSlider.bufferProgressColor = resources.progressBufferColor
        previewImageView.image = resources.placeholder
    }
}
