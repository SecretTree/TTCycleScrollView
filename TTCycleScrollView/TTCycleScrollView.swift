//
//  TTCollectionView.swift
//  TTCycleScrollView
//
//  Created by Wang Shuqing on 16/10/12.
//  Copyright © 2016年 Wang Shuqing. All rights reserved.
//

import UIKit
import Kingfisher

//The position of PageControl, support CenterAlignment and RightAlignment
enum TTCycleScrollViewPageControlAlignment {
    case TTCycleScrollViewPageControlAlignRight
    case TTCycleScrollViewPageControlAlignCenter
}
//Delegate for selecting Image
protocol TTCycleScrollViewDelegate: class {
    func didSelectItemAtIndex(index: Int) -> Void
    func didScrollToIndex(index: Int) -> Void
}

//Main View
class TTCycleScrollView: UIView, UICollectionViewDelegate, UICollectionViewDataSource {
    //collectionView that holds scroll elements
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
    
    //the default image
    lazy var placeholderImage : UIImage = {
        let placeholderImage = UIImage()
        return placeholderImage
    }()
    
    //flowLayout for layout the scrollview
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.scrollDirection = .horizontal
        return flowLayout
    }()
    
    //pageControl
    lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
       
        pageControl.isUserInteractionEnabled = false
        pageControl.isHidden = !self.showPageControl
        if self.totalItemsCount > 1 {
            pageControl.numberOfPages = self.totalItemsCount - 2
            pageControl.currentPage = self.totalItemsCount - 2
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
        } else {
            pageControl.isHidden = true
        }
        
        return pageControl
    }()
    
    //the image souces
    //for implementing scroll view , if image array is [1,2,3],we change it to [3,1,2,3,1]
    //reason : since we scroll to 3 in [1,2,3], there is nothing when we continue scroll right,
    //so we add the 1st element of the array to right to make a visual effect that still have a image in the right,
    //then relocate to array[1],the collection view will continue to scroll
    var imagePathsGroup: [String]? {
        didSet {
            if autoScroll {
                stopTimer()
            }
            if totalItemsCount > 1 {
                imagePathsGroup?.insert((imagePathsGroup?[totalItemsCount - 1])!, at: 0)
                imagePathsGroup?.append((imagePathsGroup?[1])!)
                self.collectionView.isScrollEnabled = true
            } else {
                self.collectionView.isScrollEnabled = false
                self.autoScroll = false
                self.hideForSinglePage = true
                self.infiniteLoop = false
                self.showPageControl = false
            }
            self.collectionView.reloadData()
            updateView()
        }
    }
    
    //Label titles sources is accordance to imagePathGroups
    var titlesGroup: [String]? {
        didSet {
            if autoScroll {
                stopTimer()
            }
            if totalItemsCount > 1 {
                titlesGroup?.insert((titlesGroup?[(titlesGroup?.endIndex)! - 1])!, at: 0)
                titlesGroup?.append((titlesGroup?[1])!)
            }
            self.collectionView.reloadData()
            updateView()
            print(titlesGroup)
        }
    }
    // timer for autoScroll
    var timer: Timer?
    
    //image counts
    private var totalItemsCount: Int {
        get {
            if imagePathsGroup != nil {
                return imagePathsGroup!.count
            }
            return 0
        }
    }
    
    //get currentIndex accordingto current offset
    private var currentIndex: Int {
        get {
            if (collectionView.width == 0 || collectionView.height == 0) {
                return 0
            }
            var index: Int = 0
            if (flowLayout.scrollDirection == .horizontal) {
                index = Int(collectionView.contentOffset.x / flowLayout.itemSize.width)
                print("collectionViewOffsetX:\(collectionView.contentOffset.x)itemWidth:\(flowLayout.itemSize.width)")
            } else {
                index = Int(collectionView.contentOffset.y / flowLayout.itemSize.height)
            }
            return max(0, index)
        }
    }
    //page control aliment: Center , Right
    var pageControlAlignment: TTCycleScrollViewPageControlAlignment = .TTCycleScrollViewPageControlAlignCenter
    //time imterval for scrolling
    var autoScrollTimeInterval: CGFloat = 3.0
    //title label text color
    var titleLabelTextColor: UIColor = .white
    //title label text font
    var titleLabelTextFont : UIFont = .systemFont(ofSize: 14)
    //title label background
    var titleLabelBackGroundColor: UIColor = .init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.5)
    //title label height
    var titleLabelHeight:CGFloat = 30.0
    
    //if collectionView autoScroll
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
    //if scroll loop infinite
    var infiniteLoop = true
    //scroll direction: hovizontal , vertical
    var scrollDirection:UICollectionViewScrollDirection = .horizontal
    //delegate
    var delegate: TTCycleScrollViewDelegate?
    
    //if show pagecontrol
    var showPageControl = true {
        didSet {
            self.pageControl.isHidden = !showPageControl
        }
    }
    
    // pageControlBottomOffset
    var pageControlBottomOffset: CGFloat = 0.0 {
        didSet {
            let size = self.pageControl.size(forNumberOfPages: totalItemsCount)
            let x = self.pageControl.frame.origin.x
            let y = self.pageControl.frame.origin.y - pageControlBottomOffset
            self.pageControl.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
        }
    }
    
    //pageControlRightOffset
    var pageControlRightOffset: CGFloat = 0.0 {
        didSet {
            let size = self.pageControl.size(forNumberOfPages: totalItemsCount)
            let x = self.pageControl.frame.origin.x - pageControlRightOffset
            let y = self.pageControl.frame.origin.y
            self.pageControl.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
        }
    }
    
    // hide pageControl if imageArray has only 1 elemnet
    var hideForSinglePage = true
    
    // only display text if set true
    var onlyDisplayText: Bool = false
    // bannerImageViewContentMode
    var bannerImageViewContentMode = UIViewContentMode.scaleToFill
    ///监听点击
    var clickItemClosure: ((_ currentIndex: Int) ->())?
    ///监听滚动
    var itemDidScrollClosure: ((_ currentIndex: Int) -> ())?
    
    // init
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
    
    //update view after set image sources
    private func updateView() {
        if totalItemsCount > 1 && !self.onlyDisplayText {
            addSubview(pageControl)
        }
        if autoScroll {
            startTimer()
        } else {
            stopTimer()
        }
    }
    
    //set pagecontrol state
    private func setImages(images: [String]) {
        imagePathsGroup = images
            if totalItemsCount > 1 {
                let indexPath = IndexPath(row: 1, section: 0)
                collectionView.scrollToItem(at: indexPath, at: .right, animated: false)
                pageControl.currentPage = 0
            }
    }
    
    //start timer
    private func startTimer() {
        let timer = Timer.scheduledTimer(timeInterval: TimeInterval(autoScrollTimeInterval), target: self, selector: #selector(automaticScroll), userInfo: nil, repeats: true)
        self.timer = timer
        RunLoop.main.add(self.timer!, forMode: RunLoopMode.commonModes)
    }
    //stop timer
    private func stopTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    //sutoScroll function
    func automaticScroll() {
        let nextIndex = self.currentIndex + 1
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
                cell.title = titlesGroup?[index]
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
        guard totalItemsCount > 1 else {
            return index
        }
        if index == 0 {
            return totalItemsCount - 2
        } else if index == totalItemsCount - 1 {
            return 1
        } else {
            return index
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
