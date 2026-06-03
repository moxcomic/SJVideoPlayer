// swift-tools-version:6.0
import PackageDescription

// 主库 SJVideoPlayer 转 Swift 6 + SPM。
// 仅提供「控制层 UI」, 核心播放能力来自 SJBaseVideoPlayer。
// 布局 Masonry -> SnapKit; 文案/图片走 ResourceLoader/SJVideoPlayer.bundle。
let package = Package(
    name: "SJVideoPlayer",
    defaultLocalization: "en",
    platforms: [.iOS(.v15)],
    products: [.library(name: "SJVideoPlayer", targets: ["SJVideoPlayer"])],
    dependencies: [
        .package(url: "https://github.com/moxcomic/SJBaseVideoPlayer.git", branch: "main"),
        .package(url: "https://github.com/moxcomic/SJUIKit.git", branch: "main"),
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.0"),
    ],
    targets: [
        .target(
            name: "SJVideoPlayer",
            dependencies: [
                .product(name: "SJBaseVideoPlayer", package: "SJBaseVideoPlayer"),
                .product(name: "SJUIKit", package: "SJUIKit"),
                .product(name: "SnapKit", package: "SnapKit"),
            ],
            path: "Sources/SJVideoPlayer",
            resources: [.copy("ResourceLoader/SJVideoPlayer.bundle")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
