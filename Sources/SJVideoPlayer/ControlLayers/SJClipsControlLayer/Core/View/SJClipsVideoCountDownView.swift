//
//  SJClipsVideoCountDownView.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2019/1/20.
//  Copyright © 2019 畅三江. All rights reserved.
//

import UIKit
import SnapKit

/// 视频片段录制倒计时视图: 时间标签 + 提示标签 + 底部进度条.
@objc(SJClipsVideoCountDownView)
@MainActor
public class SJClipsVideoCountDownView: UIView {

    @objc public private(set) var timeLabel: UILabel!
    @objc public private(set) var promptLabel: UILabel!
    @objc public private(set) var progressSlider: SJProgressSlider!

    public override class var layerClass: AnyClass {
        return SJClipsCommonViewLayer.self
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        _setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func _setupViews() {
        let timeLabel = UILabel(frame: .zero)
        timeLabel.font = UIFont.systemFont(ofSize: 11)
        timeLabel.textColor = .white
        self.timeLabel = timeLabel

        let promptLabel = UILabel(frame: .zero)
        promptLabel.font = UIFont.systemFont(ofSize: 11)
        promptLabel.textColor = .white
        self.promptLabel = promptLabel

        let progressSlider = SJProgressSlider(frame: .zero)
        progressSlider.trackHeight = 2
        progressSlider.isUserInteractionEnabled = false
        self.progressSlider = progressSlider

        addSubview(timeLabel)
        addSubview(promptLabel)
        addSubview(progressSlider)

        timeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(5)
            make.left.equalToSuperview().offset(24)
            make.width.equalToSuperview().offset(90)
        }

        promptLabel.snp.makeConstraints { make in
            make.left.equalTo(timeLabel.snp.right).offset(40)
            make.top.bottom.equalTo(timeLabel)
            make.right.equalToSuperview().offset(-24)
        }

        progressSlider.snp.makeConstraints { make in
            make.top.equalTo(timeLabel.snp.bottom).offset(5)
            make.left.equalTo(timeLabel)
            make.right.equalTo(promptLabel)
            make.bottom.greaterThanOrEqualTo(-8)
            make.height.equalToSuperview().offset(2)
        }
    }
}
