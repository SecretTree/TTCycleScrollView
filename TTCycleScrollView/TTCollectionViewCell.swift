//
//  TTCollectionViewCell.swift
//  TTCycleScrollView
//
//  Created by Wang Shuqing on 16/10/12.
//  Copyright © 2016年 Wang Shuqing. All rights reserved.
//

import UIKit

class TTCollectionViewCell: UICollectionViewCell {
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.isHidden = false
        return titleLabel
    } ()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: self.bounds)
        return imageView
    }()
    
    var titleLabelTextColor: UIColor = .black {
        didSet {
            titleLabel.textColor = titleLabelTextColor
        }
    }
    
    var titleLabelTextFont: UIFont = .systemFont(ofSize: 14) {
        didSet {
            titleLabel.font = titleLabelTextFont
        }
    }
    
    var titleLabelBackgroungColor: UIColor = .white {
        didSet {
            titleLabel.backgroundColor = titleLabelBackgroungColor
        }
    }
    
    var titleLabelHeight: CGFloat = 30.0 {
        didSet {
            titleLabel.height = titleLabelHeight
        }
    }
    
    var hasConfigred: Bool = true
    
    var onlyDisplayText: Bool = false
    
    var title: String? {
        didSet {
            self.titleLabel.text = title
            titleLabel.isHidden = false
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    private func setupUI() {
        self.contentView.addSubview(imageView)
        print("print titleLabel")
        self.contentView.addSubview(titleLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if (self.onlyDisplayText) {
            titleLabel.frame = self.bounds
        } else {
            imageView.frame = self.bounds
            let titleLabelW = self.bounds.size.width
            let titleLabelH = titleLabelHeight
            let titleLabelX = 0
            let titleLabelY = self.bounds.size.height - titleLabelH
            titleLabel.frame = CGRect(x: CGFloat(titleLabelX), y: titleLabelY, width: titleLabelW, height: titleLabelH)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
