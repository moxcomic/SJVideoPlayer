//
//  SJClipsGIFCountDownView.swift
//  SJVideoPlayer
//
//  Created by 畅三江 on 2019/1/20.
//  Copyright © 2019 畅三江. All rights reserved.
//

import UIKit
import SnapKit

/// GIF 录制倒计时视图: 左侧时间标签 + 右侧提示标签.
@objc(SJClipsGIFCountDownView)
@MainActor
public class SJClipsGIFCountDownView: UIView {

    @objc public private(set) var timeLabel: UILabel!
    @objc public private(set) var promptLabel: UILabel!

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
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = .white
        self.timeLabel = timeLabel

        let promptLabel = UILabel(frame: .zero)
        promptLabel.font = UIFont.systemFont(ofSize: 12)
        promptLabel.textColor = .white
        self.promptLabel = promptLabel

        addSubview(timeLabel)
        addSubview(promptLabel)

        timeLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(24)
            make.top.bottom.equalToSuperview().offset(0)
            make.width.equalToSuperview().offset(20)
        }

        promptLabel.snp.makeConstraints { make in
            make.left.equalTo(timeLabel.snp.right).offset(40)
            make.top.bottom.equalTo(timeLabel)
            make.right.equalToSuperview().offset(-24)
        }
    }
}
