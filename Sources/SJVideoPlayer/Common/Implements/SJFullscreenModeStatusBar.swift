//
//  SJFullscreenModeStatusBar.swift
//  Pods
//
//  Created by 畅三江 on 2019/12/11.
//
//  Swift 6.3 转换: SJFullscreenModeStatusBar.h / .m 合并.
//  撞名(协议 + 同名类): 协议加 _Protocol 后缀, 类保持原名.
//  私有 _SJBatteryView(UIImageView 子类)随实现一并产出.
//  布局 Masonry → SnapKit; 去掉 __has_include 防御式双写.
//

import UIKit
import SnapKit
import SJBaseVideoPlayer

// MARK: - 私有电池视图

/// 充电中电量条颜色.
private let _SJBatteryChargingColor = UIColor(red: 67 / 255.0, green: 205 / 255.0, blue: 90 / 255.0, alpha: 1)
/// 未充电电量条颜色.
private let _SJBatteryUnpluggedColor = UIColor.white

/// 电池视图(库内私有, 不进公共表).
@MainActor
private final class _SJBatteryView: UIImageView {
    var batteryState: UIDevice.BatteryState = .unknown {
        didSet {
            if batteryState != oldValue {
                _reload()
            }
        }
    }

    var batteryLevel: Float = 0 {
        didSet {
            if batteryLevel != oldValue {
                _reload()
            }
        }
    }

    let chargeView = UIView(frame: .zero)
    let lightningImageView = UIImageView(frame: .zero)

    override init(frame: CGRect) {
        super.init(frame: frame)
        chargeView.layer.cornerRadius = 1
        addSubview(chargeView)

        lightningImageView.contentMode = .center
        addSubview(lightningImageView)
        lightningImageView.snp.makeConstraints { make in
            make.center.equalToSuperview().offset(0)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        _reload()
    }

    private func _reload() {
        let bounds = self.bounds
        let padding: CGFloat = 2

        var charge = (bounds.size.width - padding * 2) * CGFloat(batteryLevel)
        if charge < 1 { charge = 1 }
        chargeView.frame = CGRect(x: padding, y: padding, width: charge, height: bounds.size.height - padding * 2)

        switch batteryState {
        case .unknown, .unplugged:
            chargeView.backgroundColor = _SJBatteryUnpluggedColor
            lightningImageView.isHidden = true
        case .charging, .full:
            chargeView.backgroundColor = _SJBatteryChargingColor
            lightningImageView.isHidden = false
        @unknown default:
            chargeView.backgroundColor = _SJBatteryUnpluggedColor
            lightningImageView.isHidden = true
        }
    }
}

// MARK: - 全屏模式状态栏

/// 全屏模式下模拟的系统状态栏.
///
/// 展示网络连接类型 / 系统时间(HH:mm) / 电量, 监听配置更新通知刷新外观.
@available(iOS 11.0, *)
@objc(SJFullscreenModeStatusBar)
@MainActor
public final class SJFullscreenModeStatusBar: UIView, SJFullscreenModeStatusBar_Protocol {

    // MARK: - 子视图

    private let networkStatusLabel = UILabel(frame: .zero)
    private let timeLabel = UILabel(frame: .zero)

    private let batteryNubImageView = UIImageView(frame: .zero)
    private let batteryView = _SJBatteryView(frame: .zero)
    private let chargeLabel = UILabel(frame: .zero)

    private let dateFormatter = DateFormatter()

    // MARK: - 协议属性存储

    private var _networkStatus: SJNetworkStatus = .notReachable
    private var _date: Date?
    private var _batteryState: UIDevice.BatteryState = .unknown
    private var _batteryLevel: Float = 0

    // MARK: - 初始化

    @objc public override init(frame: CGRect) {
        super.init(frame: frame)
        dateFormatter.dateFormat = "HH:mm"

        _setupViews()
        NotificationCenter.default.addObserver(self, selector: #selector(_updateSettings), name: SJVideoPlayerConfigurationsDidUpdateNotification, object: nil)
        _updateSettings()
        _reload()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - SJFullscreenModeStatusBar_Protocol

    ///
    /// 网络连接类型(无网络, 蜂窝网络, Wi-Fi)
    ///
    @objc public var networkStatus: SJNetworkStatus {
        get { _networkStatus }
        set {
            if newValue != _networkStatus {
                _networkStatus = newValue
                _reload()
            }
        }
    }

    ///
    /// 系统当前时间
    ///
    @objc public var date: Date? {
        get { _date }
        set {
            _date = newValue
            _reload()
        }
    }

    ///
    /// 电池状态
    ///
    @objc public var batteryState: UIDevice.BatteryState {
        get { _batteryState }
        set {
            if newValue != _batteryState {
                _batteryState = newValue
                _reload()
            }
        }
    }

    ///
    /// 电量
    ///
    @objc public var batteryLevel: Float {
        get { _batteryLevel }
        set {
            if newValue != _batteryLevel {
                _batteryLevel = newValue
                _reload()
            }
        }
    }

    // MARK: - 刷新

    private func _reload() {
        let strings = SJVideoPlayerConfigurations.shared.localizedStrings
        switch _networkStatus {
        case .notReachable:
            networkStatusLabel.text = strings.noNetWork
        case .reachableViaWWAN:
            networkStatusLabel.text = strings.cellularNetwork
        case .reachableViaWiFi:
            networkStatusLabel.text = strings.WiFiNetwork
        }

        timeLabel.text = _date.map { dateFormatter.string(from: $0) }
        chargeLabel.text = String(format: "%d%%", Int(_batteryLevel * 100))
        batteryView.batteryLevel = _batteryLevel
        batteryView.batteryState = _batteryState
    }

    // MARK: - 视图搭建

    private func _setupViews() {
        let textColor = UIColor.white
        let font = UIFont.boldSystemFont(ofSize: 12)

        networkStatusLabel.textColor = textColor
        networkStatusLabel.font = font
        addSubview(networkStatusLabel)

        timeLabel.textColor = textColor
        timeLabel.font = font
        addSubview(timeLabel)

        chargeLabel.textColor = textColor
        chargeLabel.font = font
        addSubview(chargeLabel)

        batteryView.contentMode = .center
        addSubview(batteryView)

        batteryNubImageView.contentMode = .center
        addSubview(batteryNubImageView)

        networkStatusLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.centerY.equalToSuperview().offset(0)
        }

        timeLabel.snp.makeConstraints { make in
            make.center.equalToSuperview().offset(0)
        }

        chargeLabel.snp.makeConstraints { make in
            make.right.equalTo(self.batteryView.snp.left).offset(-5)
            make.centerY.equalToSuperview().offset(0)
        }

        batteryView.snp.makeConstraints { make in
            make.right.equalTo(self.batteryNubImageView.snp.left).offset(-1)
            make.centerY.equalToSuperview().offset(0)
        }

        batteryNubImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview().offset(0)
        }
    }

    // MARK: - 外观更新

    @objc private func _updateSettings() {
        let sources = SJVideoPlayerConfigurations.shared.resources
        batteryNubImageView.image = sources.batteryNubImage
        batteryView.image = sources.batteryBorderImage
        batteryView.lightningImageView.image = sources.batteryLightningImage
    }
}
