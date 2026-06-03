//
//  SJClipsCommonViewLayer.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2019/1/20.
//  Copyright © 2019 畅三江. All rights reserved.
//

import QuartzCore
import UIKit

/// 剪辑模块通用图层: 半透明黑底 + 高度一半的圆角.
@objc(SJClipsCommonViewLayer)
@MainActor
public class SJClipsCommonViewLayer: CALayer {

    public override func layoutSublayers() {
        super.layoutSublayers()
        backgroundColor = UIColor(white: 0, alpha: 0.8).cgColor
        cornerRadius = bounds.size.height * 0.5
    }
}
