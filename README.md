# SJVideoPlayer

[![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg?style=flat)](https://swift.org)
[![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)
[![Platform](https://img.shields.io/badge/platform-iOS%2015%2B-blue.svg?style=flat)](https://developer.apple.com)
[![License](https://img.shields.io/github/license/moxcomic/SJVideoPlayer.svg)](LICENSE.md)

SJVideoPlayer 是一个功能完整的 iOS 视频播放器 **UI 层**，提供一套可自由切换的「控制层（Control Layer）」体系；核心播放能力来自依赖库 [SJBaseVideoPlayer](https://github.com/moxcomic/SJBaseVideoPlayer)。本库现已全面迁移为 **Swift 6**（Swift 6 语言模式）并通过 **Swift Package Manager** 分发。

> 这是原 [changsanjiang/SJVideoPlayer](https://github.com/changsanjiang/SJVideoPlayer)（Objective-C + CocoaPods）的 Swift 6 + SPM 重写版本。原 CocoaPods / Carthage 安装方式及示例工程已移除。

## 功能特性

- **控制层体系**：UI 由一组可热切换的控制层组成，由内置切换器 `SJControlLayerSwitcher` 统一管理：
  - `SJEdgeControlLayer` —— 主（边缘）控制层：顶/底/左/右四向容器，承载播放、进度、全屏、更多等按钮项。
  - `SJSmallViewControlLayer` —— 小浮窗（画中画式小窗）控制层。
  - `SJClipsControlLayer` —— 剪辑控制层：截图、录制 GIF、导出片段及结果展示。
  - `SJVideoDefinitionSwitchingControlLayer` —— 清晰度切换控制层，带切换中/成功/失败提示。
  - `SJMoreSettingControlLayer` —— 更多设置控制层：音量 / 亮度 / 播放速率调节。
  - `SJLoadFailedControlLayer` —— 加载失败 / 播放出错控制层。
  - `SJNotReachableControlLayer` —— 无网络（断网）控制层，网络恢复后自动续播。
- **手势交互**：单击 / 双击 / 拖拽进度 / 长按倍速等手势能力（由播放内核提供）。
- **画中画 (PiP)**：iOS 14+ 系统画中画支持。
- **全屏与小窗**：自动横屏旋转或竖屏撑满全屏（`automaticallyPerformRotationOrFitOnScreen`），以及小浮窗模式。
- **清晰度切换**：传入清晰度资源数组即自动挂载清晰度按钮与切换提示。
- **本地化**：内置 `zh-Hans` / `zh-Hant` / `en` 三语言，可覆盖或替换本地化文案。
- **资源可定制**：占位图、进度条颜色、各类图标等通过资源 bundle 与配置统一管理。

## 环境要求

- iOS 15.0+
- Swift 6（Swift 6 语言模式）
- 较新版本的 Xcode（支持 swift-tools-version 6.0 与 Swift 6 语言模式）

## 安装

仅支持 **Swift Package Manager**。

### 方式一：Xcode 添加

在 Xcode 中选择 `File` → `Add Package Dependencies…`，输入仓库地址：

```
https://github.com/moxcomic/SJVideoPlayer.git
```

依赖规则选择 **Branch → `main`**。

### 方式二：Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/moxcomic/SJVideoPlayer.git", branch: "main"),
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "SJVideoPlayer", package: "SJVideoPlayer"),
        ]
    )
]
```

## 依赖说明

SJVideoPlayer 通过 SPM 自动解析以下依赖：

| 依赖 | 地址 | 版本 | 说明 |
| --- | --- | --- | --- |
| SJBaseVideoPlayer | https://github.com/moxcomic/SJBaseVideoPlayer.git | `main` | 核心播放内核（默认 AVPlayer，可切换其他引擎） |
| SJUIKit | https://github.com/moxcomic/SJUIKit.git | `main` | 通用 UI 与富文本等基础设施 |
| SnapKit | https://github.com/SnapKit/SnapKit.git | `5.7.0+` | 自动布局（替代原 Masonry） |

## 快速开始

```swift
import UIKit
import SJVideoPlayer
import SnapKit

class ViewController: UIViewController {

    private var player: SJVideoPlayer!

    override func viewDidLoad() {
        super.viewDidLoad()

        // 创建带默认控制层（边缘控制层）的播放器
        player = SJVideoPlayer.player()
        view.addSubview(player.view)
        player.view.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.height.equalTo(player.view.snp.width).multipliedBy(9.0 / 16.0)
        }

        // 通过 URL 播放
        let asset = SJVideoPlayerURLAsset(url: URL(string: "https://example.com/sample.mp4")!)
        player.urlAsset = asset
    }
}
```

> 关于旋转/全屏：横竖屏方向控制由播放内核的旋转管理器（`SJRotationManager`）负责，具体在 AppDelegate / 视图控制器中的接入方式请参考 [SJBaseVideoPlayer](https://github.com/moxcomic/SJBaseVideoPlayer) 的说明。

## 进阶用法

### 切换控制层

所有控制层标识符常量定义在 `SJControlLayerIdentifiers`，通过门面直接切换：

```swift
// 切回主（边缘）控制层
player.switchControlLayer(forIdentifier: SJControlLayer_Edge)

// 切换到更多设置控制层（音量/亮度/速率）
player.switchControlLayer(forIdentifier: SJControlLayer_More)

// 也可直接访问切换器
player.switcher.switchControlLayer(forIdentifier: SJControlLayer_Edge)
_ = player.switcher.switchToPreviousControlLayer()
```

可用标识符：`SJControlLayer_Edge`、`SJControlLayer_More`、`SJControlLayer_Clips`、`SJControlLayer_LoadFailed`、`SJControlLayer_NotReachableAndPlaybackStalled`、`SJControlLayer_FloatSmallView`、`SJControlLayer_SwitchVideoDefinition`。

### 开启更多按钮 / 剪辑功能

```swift
let edge = player.defaultEdgeControlLayer

// 顶栏「更多」按钮（三个点），默认开启
edge.showsMoreItem = true

// 开启剪辑功能（注意：暂不支持剪辑 m3u8）
edge.enabledClips = true
```

### 清晰度切换

为播放器设置一组清晰度资源，框架会自动在底栏挂载清晰度按钮并接管切换流程：

```swift
player.definitionURLAssets = [
    SJVideoPlayerURLAsset(url: sdURL),
    SJVideoPlayerURLAsset(url: hdURL),
    SJVideoPlayerURLAsset(url: fhdURL),
]

// 如需关闭切换过程中的文字提示
player.disabledDefinitionSwitchingPrompt = true
```

### 自定义按钮项（SJEdgeControlButtonItem）

控制层的四向容器各自由一个适配器（`SJEdgeControlButtonItemAdapter`）管理按钮项。通过占位类型创建 item、绑定 action，再加入对应适配器并 `reload`：

```swift
let edge = player.defaultEdgeControlLayer

let item = SJEdgeControlButtonItem.placeholder(type: ._49x49, tag: 10086)
item.image = UIImage(named: "icon_custom")
item.addAction(SJEdgeControlButtonItemAction.action { action in
    print("自定义按钮被点击：tag = \(action.item?.tag ?? 0)")
})

edge.topAdapter.addItem(item)
edge.topAdapter.reload()
```

### 配置（SJVideoPlayerConfigurations）

全局配置入口为 `SJVideoPlayerConfigurations`，资源与本地化文案均可定制。更新闭包在子线程执行：

```swift
// 更新资源（占位图、进度条样式、图标等）
SJVideoPlayer.updateResources { resources in
    resources.placeholder = UIImage(named: "placeholder")
    resources.progressTrackColor = UIColor(white: 0.4, alpha: 1)
}

// 更新本地化文案
SJVideoPlayer.updateLocalizedStrings { strings in
    // 覆盖需要自定义的文案 key
}

// 用自定义 bundle 替换整套本地化文案
SJVideoPlayer.setLocalizedStrings(yourBundle)

// 一次性更新全部配置
SJVideoPlayer.update { configs in
    configs.resources.placeholder = UIImage(named: "placeholder")
    configs.resources.progressTrackColor = UIColor(white: 0.4, alpha: 1)
}
```

## 示例工程

原 Objective-C 时代的 Example 演示工程已随迁移移除；后续将基于 Swift Package Manager 重建一个新的示例工程。

## 致谢

本库源自 [畅三江（changsanjiang）](https://github.com/changsanjiang) 的原创作品 [SJVideoPlayer](https://github.com/changsanjiang/SJVideoPlayer) 与 [SJBaseVideoPlayer](https://github.com/changsanjiang/SJBaseVideoPlayer)，在此向原作者致以诚挚感谢。本仓库为其 Swift 6 + SPM 重写版本。

- 原作者邮箱：changsanjiang@gmail.com

## License

SJVideoPlayer 基于 MIT 协议开源，详见 [LICENSE.md](LICENSE.md)。
