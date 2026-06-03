//
//  DemoSamples.swift
//  SJVideoPlayerDemo
//
//  集中放置演示所用的示例媒体 URL 与常量。
//

import Foundation

/// 演示示例数据。
enum DemoSamples {

    /// 公开可用的示例 MP4(Big Buck Bunny 短片)。
    static let sampleMP4URL = URL(string: "https://www.w3schools.com/html/mov_bbb.mp4")!

    /// Apple 公开的示例 HLS(m3u8)流,可按需替换上面的 MP4 使用。
    static let sampleHLSURL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8")!

    /// 自定义按钮项演示使用的 tag(避开内置按钮项的 tag 取值)。
    static let customItemTag: Int = 10086
}
