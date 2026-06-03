//
//  SJLoadFailedControlLayer.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2018/10/27.
//  Copyright © 2018 畅三江. All rights reserved.
//

import UIKit

// MARK: - 加载失败或播放出错时显示的控制层

/// 加载失败或播放出错时显示的控制层
@objc(SJLoadFailedControlLayer)
@MainActor
public class SJLoadFailedControlLayer: SJNotReachableControlLayer {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _updateSettings()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func _updateSettings() {
        let resources = SJVideoPlayerConfigurations.shared.resources
        let strings = SJVideoPlayerConfigurations.shared.localizedStrings
        reloadView.button.setTitle(strings.reload, for: .normal)
        reloadView.backgroundColor = resources.playFailedButtonBackgroundColor
        promptLabel.text = strings.playbackFailedPrompt
    }
}
