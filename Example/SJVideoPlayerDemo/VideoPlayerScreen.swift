//
//  VideoPlayerScreen.swift
//  SJVideoPlayerDemo
//
//  SJVideoPlayer 是基于 UIKit 的播放器(player.view 需挂到 UIViewController 上),
//  因此用 UIViewControllerRepresentable 在 SwiftUI 中承载一个自定义 UIViewController。
//
//  通过 DemoMode 参数化三种演示:
//  - .basic            基础播放
//  - .switchControlLayer 顶部叠加按钮,在边缘控制层 / 更多设置控制层间切换
//  - .customItem       向顶栏适配器添加一个自定义按钮项
//

import SwiftUI
import UIKit
import SnapKit
import SJVideoPlayer
// SJVideoPlayerURLAsset 定义在播放内核库 SJBaseVideoPlayer 中。
import SJBaseVideoPlayer

// MARK: - SwiftUI 包装层

/// 用 UIViewControllerRepresentable 承载 UIKit 的播放器控制器。
struct VideoPlayerScreen: UIViewControllerRepresentable {

    /// 演示模式。
    enum DemoMode: Hashable {
        /// 基础播放。
        case basic
        /// 切换控制层演示。
        case switchControlLayer
        /// 自定义按钮项演示。
        case customItem
    }

    let mode: DemoMode

    func makeUIViewController(context: Context) -> PlayerViewController {
        PlayerViewController(mode: mode)
    }

    func updateUIViewController(_ uiViewController: PlayerViewController, context: Context) {
        // 演示无需在更新阶段做额外处理。
    }
}

// MARK: - 承载播放器的 UIViewController

/// 真正创建并持有 SJVideoPlayer 的控制器。
final class PlayerViewController: UIViewController {

    private let mode: VideoPlayerScreen.DemoMode

    /// 持有播放器实例,避免被释放。
    private var player: SJVideoPlayer!

    /// 切换控制层演示用的开关按钮(仅 .switchControlLayer 模式下创建)。
    private var isShowingMoreLayer = false
    private weak var switchButton: UIButton?

    init(mode: VideoPlayerScreen.DemoMode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupPlayer()
        setupAsset()

        switch mode {
        case .basic:
            break
        case .switchControlLayer:
            setupSwitchControlLayerDemo()
        case .customItem:
            setupCustomItemDemo()
        }
    }

    // MARK: 创建播放器

    private func setupPlayer() {
        // 创建带默认控制层(边缘控制层)的播放器。
        player = SJVideoPlayer.player()
        view.addSubview(player.view)

        // 用 SnapKit 布局:顶部贴安全区,左右撑满,高度按 16:9。
        player.view.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.height.equalTo(player.view.snp.width).multipliedBy(9.0 / 16.0)
        }

        // 点击全屏按钮时,根据视频宽高自动旋转或竖屏撑满。
        player.automaticallyPerformRotationOrFitOnScreen = true
    }

    // MARK: 设置播放资源

    private func setupAsset() {
        // 通过 URL 播放一个公开可用的示例视频。
        guard let asset = SJVideoPlayerURLAsset(url: DemoSamples.sampleMP4URL) else { return }
        player.urlAsset = asset
    }

    // MARK: 演示:切换控制层

    private func setupSwitchControlLayerDemo() {
        // 在播放器下方放一个普通 UIButton,点击在两种控制层之间切换。
        let button = UIButton(type: .system)
        button.setTitle("切换到更多设置控制层", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(toggleControlLayer), for: .touchUpInside)
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.top.equalTo(player.view.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
        }
        switchButton = button
    }

    @objc private func toggleControlLayer() {
        isShowingMoreLayer.toggle()
        if isShowingMoreLayer {
            // 切换到更多设置控制层(音量 / 亮度 / 播放速率)。
            player.switchControlLayer(forIdentifier: SJControlLayer_More)
            switchButton?.setTitle("切回边缘控制层", for: .normal)
        } else {
            // 切回主(边缘)控制层。
            player.switchControlLayer(forIdentifier: SJControlLayer_Edge)
            switchButton?.setTitle("切换到更多设置控制层", for: .normal)
        }
    }

    // MARK: 演示:自定义按钮项

    private func setupCustomItemDemo() {
        let edge = player.defaultEdgeControlLayer

        // 用占位类型创建一个 49x49 的按钮项,自定义 tag。
        let item = SJEdgeControlButtonItem.placeholder(type: ._49x49, tag: DemoSamples.customItemTag)
        item.image = UIImage(systemName: "heart.fill")

        // 绑定 action:点击时弹出提示。闭包内捕获 item 以读取其 tag
        // (SJEdgeControlButtonItemAction 自身不携带 item 引用)。
        item.addAction(SJEdgeControlButtonItemAction.action { [weak self, weak item] _ in
            let tag = item?.tag ?? 0
            self?.presentCustomItemTappedAlert(tag: tag)
        })

        // 加入顶栏适配器并 reload 使其生效。
        edge.topAdapter.addItem(item)
        edge.topAdapter.reload()
    }

    private func presentCustomItemTappedAlert(tag: Int) {
        let alert = UIAlertController(
            title: "自定义按钮被点击",
            message: "tag = \(tag)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        present(alert, animated: true)
    }
}
