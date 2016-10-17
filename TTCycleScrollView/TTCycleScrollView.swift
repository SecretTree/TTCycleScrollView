//
//  TTCollectionView.swift
//  TTCycleScrollView
//
//  Created by Wang Shuqing on 16/10/12.
//  Copyright © 2016年 Wang Shuqing. All rights reserved.
//

import UIKit
import Kingfisher

enum TTCycleScrollViewPageControlAlignment {
    case TTCycleScrollViewPageControlAlignRight
    case TTCycleScrollViewPageControlAlignCenter
}

protocol TTCycleScrollViewDelegate: class {
    func didSelectItemAtIndex(index: Int) -> Void
    func didScrollToIndex(index: Int) -> Void
}

class TTCycleScrollView: UIView, UICollectionViewDelegate, UICollectionViewDataSource {
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: self.bounds, collectionViewLayout: self.flowLayout)
        self.flowLayout.itemSize = CGSize(width: collectionView.width, height: collectionView.height)
        self.flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: self.bounds.size.width * CGFloat(self.totalItemsCount))
        collectionView.backgroundColor = .gray
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(TTCollectionViewCell.self, forCellWithReuseIdentifier: "cycleCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.scrollsToTop = false
        return collectionView
    }()
    
    lazy var placeholderImage: UIImage = {
        let placeholderImage = UIImage()
        return placeholderImage
    }()

    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.scrollDirection = .horizontal
        return flowLayout
    }()
    
    lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = self.totalItemsCount - 2
        pageControl.isUserInteractionEnabled = false
        pageControl.isHidden = !self.showPageControl
        if self.totalItemsCount > 1 {
            pageControl.currentPage = 0
        } else {
            pageControl.isHidden = true
        }
        let size = pageControl.size(forNumberOfPages: self.totalItemsCount - 2)
        var x = (self.collectionView.width - size.width) / 2.0
        //if pageControlAlignment == .TTCycleScrollViewPageControlAlignRight {
        //    x = self.collectionView.width - size.width - 10
        //}
        let y = self.collectionView.height - size.height - 10
        var pageControlFrame = CGRect(x: x, y: y, width: size.width, height: size.height)
        pageControlFrame.origin.y -= self.pageControlBottomOffset
        pageControlFrame.origin.x -= self.pageControlRightOffset
        pageControl.frame = pageControlFrame
        return pageControl
    }()
    
    var imagePathsGroup: [String]? {
        didSet {
            if autoScroll {
                stopTimer()
            }
            if totalItemsCount > 1 {
                imagePathsGroup?.insert((imagePathsGroup?[totalItemsCount - 1])!, at: 0)
                imagePathsGroup?.append((imagePathsGroup?[1])!)
            }
            if totalItemsCount > 1 {
                self.collectionView.isScrollEnabled = true
            } else {
                self.collectionView.isScrollEnabled = false
            }
            self.collectionView.reloadData()
            print("didSetImagePath")
            print(imagePathsGroup)
            updateView()
        }
    }
    var titlesGroup: [String]?
    var timer: Timer?
    
    private var totalItemsCount: Int {
        get {
            if imagePathsGroup != nil {
                return imagePathsGroup!.count
            }
            return 0
        }
    }
    
    private var currentIndex: Int {
        get {
            if (collectionView.width == 0 || collectionView.height == 0) {
                return 0
            }
            var index: Int = 0
            if (flowLayout.scrollDirection == .horizontal) {
                index = Int(collectionView.contentOffset.x / flowLayout.itemSize.width)
            } else {
                index = Int(collectionView.contentOffset.y / flowLayout.itemSize.height)
            }
            return max(0, index)
        }
    }
    var pageControlAlignment: TTCycleScrollViewPageControlAlignment = .TTCycleScrollViewPageControlAlignCenter
    var autoScrollTimeInterval: CGFloat = 3.0
    var titleLabelTextColor: UIColor = .white
    var titleLabelTextFont : UIFont = .systemFont(ofSize: 14)
    var titleLabelBackGroundColor: UIColor = .init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.5)
    var titleLabelHeight:CGFloat = 30.0
    var autoScroll = true {
        didSet {
            if autoScroll {
                stopTimer()
                startTimer()
            } else {
                stopTimer()
            }
        }
    }
    var infiniteLoop = true
    var scrollDirection:UICollectionViewScrollDirection = .horizontal
    var delegate: TTCycleScrollViewDelegate?
    
    var showPageControl = true {
        didSet {
            self.pageControl.isHidden = !showPageControl
        }
    }
    var pageControlBottomOffset: CGFloat = 0.0 {
        didSet {
            let size = self.pageControl.size(forNumberOfPages: totalItemsCount)
            let x = self.pageControl.frame.origin.x
            let y = self.pageControl.frame.origin.y - pageControlBottomOffset
            self.pageControl.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
        }
    }
    var pageControlRightOffset: CGFloat = 0.0 {
        didSet {
            let size = self.pageControl.size(forNumberOfPages: totalItemsCount)
            let x = self.pageControl.frame.origin.x - pageControlRightOffset
            let y = self.pageControl.frame.origin.y
            self.pageControl.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
        }
    }
    var hideForSinglePage = true
    
    var onlyDisplayText: Bool = false
    var bannerImageViewContentMode = UIViewContentMode.scaleToFill
    ///监听点击
    var clickItemClosure: ((_ currentIndex: Int) ->())?
    ///监听滚动
    var itemDidScrollClosure: ((_ currentIndex: Int) -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(collectionView)
        self.backgroundColor = .black
        
    }
    
    convenience init(frame: CGRect, imageNamesGroup: [String]) {
        self.init(frame: frame)
        setImages(images: imageNamesGroup)
    }
    
    convenience init(frame: CGRect, shouldInifiniteLoop infiniteLoop: Bool, imageNamesGroup: [String]) {
        self.init(frame: frame)
        self.infiniteLoop = infiniteLoop
        setImages(images: imageNamesGroup)
    }
    
    convenience init(frame: CGRect, delegate: TTCycleScrollViewDelegate, placeholderImage: UIImage) {
        self.init(frame: frame)
        self.delegate = delegate
        self.placeholderImage = placeholderImage
    }
    
    private func updateView() {
        print("199 updateSubView")
        print(totalItemsCount)
        if totalItemsCount > 1 && !self.onlyDisplayText {
            addSubview(pageControl)
        }
        if autoScroll {
            startTimer()
        } else {
            stopTimer()
        }
    }
    
    private func setImages(images: [String]) {
        imagePathsGroup = images
        collectionView.scrollToItem(at: IndexPath(row: 1, section: 0), at: .centeredHorizontally, animated: false)
    }
    
    private func startTimer() {
        let timer = Timer.scheduledTimer(timeInterval: TimeInterval(autoScrollTimeInterval), target: self, selector: #selector(automaticScroll), userInfo: nil, repeats: true)
        self.timer = timer
        RunLoop.main.add(self.timer!, forMode: RunLoopMode.commonModes)
    }
    
    private func stopTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }
    func automaticScroll() {
        let nextIndex = self.currentIndex + 1
        print(nextIndex)
        print("======")
        let path = IndexPath(row: nextIndex, section: 0)
        collectionView.scrollToItem(at: path, at: .right, animated: true)
    }
    /// Data Source
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalItemsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = getIndexWithIndexPath(indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cycleCell", for: indexPath) as! TTCollectionViewCell
        
        let imagePath: String? = self.imagePathsGroup?[index]
        
        if (!onlyDisplayText) && (imagePath != nil) {
            if (imagePath?.hasPrefix("http"))! {
                let url = URL(string: imagePath!)
                cell.imageView.kf.setImage(with: url, placeholder: self.placeholderImage, options: nil, progressBlock: nil, completionHandler: nil)
            } else {
                let image = UIImage(contentsOfFile: imagePath!)
                cell.imageView.image = image
            }
        }
        if (titlesGroup != nil) {
            if (titlesGroup?.count)! > 0 && index < (titlesGroup?.count)! {
                cell.title = titlesGroup?[index]
            }
        }
        
        if !cell.hasConfigred {
            cell.titleLabelBackgroungColor = self.titleLabelBackGroundColor
            cell.titleLabelHeight = self.titleLabelHeight
            cell.titleLabelTextColor = self.titleLabelTextColor
            cell.titleLabelTextFont = self.titleLabelTextFont
            cell.hasConfigred = true
            cell.imageView.contentMode = self.bannerImageViewContentMode
            cell.clipsToBounds = true
            cell.onlyDisplayText = self.onlyDisplayText
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectItemAtIndex(index: indexPath.item)
    }
    
    private func getIndexWithIndexPath(_ indexPath: IndexPath) -> Int {
        let index = (indexPath as NSIndexPath).row
        if index < 1 {
            return totalItemsCount - 1
        } else if index > totalItemsCount {
            return 0
        } else {
            return index - 1
        }
    }
    
    /// View delegate
    override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil && autoScroll {
            stopTimer()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if autoScroll {
            stopTimer()
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if autoScroll {
            startTimer()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        resetCurrentPage()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        resetCurrentPage()
    }
    
    func resetCurrentPage()
    {
        if currentIndex < 1 {
            pageControl.currentPage = totalItemsCount - 3
            let path = IndexPath(row: totalItemsCount - 2, section: 0)
            collectionView.scrollToItem(at: path, at: .right, animated: false)
        } else if currentIndex == totalItemsCount - 1 {
            pageControl.currentPage = 0
            let path = IndexPath(row: 1, section: 0)
            collectionView.scrollToItem(at: path, at: .left, animated: false)
        } else {
            pageControl.currentPage = currentIndex - 1
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
