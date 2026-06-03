//
//  ContentView.swift
//  SJVideoPlayerDemo
//
//  演示首页:用 NavigationStack 列出三个演示入口。
//  - 基础播放:创建默认(边缘)控制层的播放器并播放示例视频。
//  - 切换控制层:演示在边缘控制层与更多设置控制层之间切换。
//  - 自定义按钮项:演示向顶栏适配器添加自定义 SJEdgeControlButtonItem。
//

import SwiftUI

struct ContentView: View {

    /// 三个演示入口的数据模型。
    private let demos: [DemoEntry] = [
        DemoEntry(
            title: "基础播放",
            subtitle: "默认边缘控制层 + 播放示例视频",
            mode: .basic
        ),
        DemoEntry(
            title: "切换控制层",
            subtitle: "边缘控制层 / 更多设置控制层 切换",
            mode: .switchControlLayer
        ),
        DemoEntry(
            title: "自定义按钮项",
            subtitle: "向顶栏添加自定义 SJEdgeControlButtonItem",
            mode: .customItem
        ),
    ]

    var body: some View {
        NavigationStack {
            List(demos) { demo in
                NavigationLink(value: demo) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(demo.title)
                            .font(.headline)
                        Text(demo.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("SJVideoPlayer 演示")
            .navigationDestination(for: DemoEntry.self) { demo in
                // 进入对应的播放器演示屏,标题用入口标题。
                VideoPlayerScreen(mode: demo.mode)
                    .navigationTitle(demo.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

/// 单个演示入口。遵循 Hashable 以便用作 navigationDestination 的路由值。
struct DemoEntry: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let mode: VideoPlayerScreen.DemoMode
}

#Preview {
    ContentView()
}
