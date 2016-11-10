//
//  PhotoBrowser.swift
//  PhotoBrowser
//
//  Created by Matthew on 09/11/2016.
//  Copyright © 2016年 Matthew. All rights reserved.
//

import UIKit
import Photos

class PhotoBrowser: UIViewController {
    
    // Constants
    private let padding: CGFloat = 10.0
    private let screenSize: CGSize = UIScreen.main.bounds.size
    
    fileprivate let cellReuseIdentifier = "PhotoCellReuseIdentifier"
    
    // Set page that photo browser starts on.
    var currentPhotoIndex: Int
    
    var photos: [PHAsset]
    var displayTitle: Bool
    var enableScrollToDismissTopBars: Bool
    var enableInteractivePopGestureRecognizer: Bool
    var rightBarButtonItem: UIBarButtonItem?
    
    fileprivate var targetSize: CGSize!
    fileprivate var statusBarPresented: Bool
    fileprivate var previousPreheatRect: CGRect
    fileprivate var pagingCollectionViewHasScrolled: Bool
    fileprivate var pagingCollectionView: UICollectionView
    fileprivate var imageManager: PHCachingImageManager
    
    init() {
        self.currentPhotoIndex = 0
        self.photos = []
        self.previousPreheatRect = CGRect.zero
        
        let scale = UIScreen.main.scale
        self.targetSize = CGSize(
            width: screenSize.width * scale,
            height: screenSize.width * scale
        )
        
        self.pagingCollectionView = UICollectionView(
            frame: CGRect(
                origin: CGPoint.zero,
                size: CGSize(
                    width: screenSize.width + padding * 2.0,
                    height: screenSize.width
                )
            ),
            collectionViewLayout: UICollectionViewFlowLayout()
        )
        self.displayTitle = false
        self.enableScrollToDismissTopBars = false
        self.enableInteractivePopGestureRecognizer = true
        self.statusBarPresented = true
        self.pagingCollectionViewHasScrolled = false
        self.imageManager = PHCachingImageManager()
        
        super.init(nibName: nil, bundle: nil)
        
        self.hidesBottomBarWhenPushed = true
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var prefersStatusBarHidden : Bool {
        return !statusBarPresented
    }
    
    override var preferredStatusBarUpdateAnimation : UIStatusBarAnimation {
        return .slide
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if displayTitle {
            title = "\(currentPhotoIndex + 1)/\(photos.count)"
        }
        
        if let navigationController = navigationController {
            // Disable the interactivePopGestureRecognizer
            navigationController.interactivePopGestureRecognizer?.isEnabled = enableInteractivePopGestureRecognizer
            navigationController.delegate = self
            
            if rightBarButtonItem != nil {
                navigationItem.rightBarButtonItem = rightBarButtonItem
            }
        }
        
        // Register photo cell class
        pagingCollectionView.register(
            PhotoCell.self,
            forCellWithReuseIdentifier: cellReuseIdentifier
        )
        
        pagingCollectionView.dataSource = self
        pagingCollectionView.delegate = self
        pagingCollectionView.showsVerticalScrollIndicator = false
        pagingCollectionView.showsHorizontalScrollIndicator = false
        pagingCollectionView.isPagingEnabled = true
        pagingCollectionView.alwaysBounceHorizontal = true
        pagingCollectionView.backgroundColor = UIColor.black
        
        let pagingCollectionViewWidth = screenSize.width + padding * 2.0
        
        // The pagingCollectionView is about to scroll
        pagingCollectionView.contentOffset = CGPoint(
            x: pagingCollectionViewWidth * CGFloat(currentPhotoIndex),
            y: 0.0
        )
        
        pagingCollectionViewHasScrolled = true
        
        // Configure flow layout
        let flowLayout = pagingCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
        
        flowLayout.itemSize = CGSize(
            width: pagingCollectionViewWidth,
            height: screenSize.width
        )
        flowLayout.scrollDirection = .horizontal
        
        // The width of item is 20 points wider than the width of screen, so it's not nesseary to have redundant spacing between items
        flowLayout.minimumLineSpacing = 0.0
        
        view.addSubview(pagingCollectionView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Begin caching assets in and around collection view's visible rect
        updateCachedAssets()
    }
    
    // MARK: - Internal Methods
    func removeCurrentPage() {
        // If it's about to remove the last photo, so don't hide the top bars because it may pop self which will cause the navigation bar hidden
        if photos.count != 1 {
            hideTopBars()
        }
        
        // First disable the right bar button item
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        // Remove the corresponding asset and the cached image if possible
        photos.remove(at: currentPhotoIndex)
        
        // Remove the item at specified index path
        pagingCollectionView.performBatchUpdates({
            let currentPageIndexPath = IndexPath(item: self.currentPhotoIndex, section: 0)
            
            self.pagingCollectionView.deleteItems(at: [currentPageIndexPath])
        }) {
            _ in
            
            self.updateCurrentPhotoIndex()
            
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    // MARK: - Callback Methods
    @objc fileprivate func hideTopBars() {
        statusBarPresented = !statusBarPresented
        
        // Put the setNeedsStatusBarAppearanceUpdate into block, otherwise, the status bar animation won't show up
        UIView.animate(withDuration: 0.4, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        }) 
        
        // Display or hide navigation bar
        if navigationController != nil {
            navigationController!.setNavigationBarHidden(true, animated: true)
        }
    }
    
    @objc fileprivate func displayTopBars() {
        statusBarPresented = !statusBarPresented
        
        // Display or hide navigation bar
        if navigationController != nil {
            navigationController!.setNavigationBarHidden(false, animated: true)
        }
        
        // Put the setNeedsStatusBarAppearanceUpdate into block, otherwise, the status bar animation won't show up
        UIView.animate(withDuration: 0.4, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        }) 
    }
    
    // MARK: - Private Methods
    fileprivate func updateCurrentPhotoIndex() {
        currentPhotoIndex = Int(pagingCollectionView.contentOffset.x / pagingCollectionView.bounds.width)
        
        if displayTitle {
            title = "\(currentPhotoIndex + 1)/\(photos.count)"
        }
    }
    
    private func assets(atIndexPaths indexPaths: [IndexPath]) -> [PHAsset]? {
        if indexPaths.count == 0 {
            return nil
        }
        
        return indexPaths.map {
            self.photos[$0.item]
        }
    }
    
    private func computeDifferenceBetween(oldRect: CGRect, andNewRect newRect: CGRect, removedHandler: (_ removedRect: CGRect) -> Void, addedHandler: (_ addedRect: CGRect) -> Void) {
        let oldMinX = oldRect.minX
        let oldMaxX = oldRect.maxX
        let newMinX = newRect.minX
        let newMaxX = newRect.maxX
        
        if newRect.intersects(oldRect) {
            if newMaxX > oldMaxX {
                let rectToAdd = CGRect(
                    x: oldMaxX,
                    y: newRect.minY,
                    width: newMaxX - oldMaxX,
                    height: newRect.height
                )
                addedHandler(rectToAdd)
            }
            
            if oldMinX > newMinX {
                let rectToAdd = CGRect(
                    x: newMinX,
                    y: newRect.minY,
                    width: oldMinX - newMinX,
                    height: newRect.height
                )
                addedHandler(rectToAdd)
            }
            
            if newMaxX < oldMaxX {
                let rectToRemove = CGRect(
                    x: newMaxX,
                    y: newRect.minY,
                    width: oldMaxX - newMaxX,
                    height: newRect.height
                )
                removedHandler(rectToRemove)
            }
            
            if oldMinX < newMinX {
                let rectToRemove = CGRect(
                    x: oldMinX,
                    y: newRect.minY,
                    width: newMinX - oldMinX,
                    height: newRect.height
                )
                removedHandler(rectToRemove)
            }
        } else {
            addedHandler(newRect)
            removedHandler(oldRect)
        }
    }
    
    fileprivate func updateCachedAssets() {
        guard isViewLoaded && view.window != nil else {
            return
        }
        
        // The preheat window is twice the width of the visible rect
        var preheatRect = pagingCollectionView.bounds
        preheatRect = preheatRect.insetBy(dx: -preheatRect.width, dy: 0.0)
        
        /*
            Check if the collection view is showing an area that is significantly
            different to the last preheated area
         */
        let delta = abs(preheatRect.midX - previousPreheatRect.midX)
        
        if delta >= pagingCollectionView.bounds.size.width / 2.0 {
            // Compute the assets to start caching and to stop caching
            var addedIndexPaths: [IndexPath] = []
            var removedIndexPaths: [IndexPath] = []
            
            computeDifferenceBetween(oldRect: previousPreheatRect, andNewRect: preheatRect, removedHandler: {
                removedRect in
                
                let indexPaths = self.pagingCollectionView.indexPaths(forElementsInRect: removedRect)
                
                if indexPaths != nil {
                    removedIndexPaths.append(contentsOf: indexPaths!)
                }
                }, addedHandler: {
                    addedRect in
                    
                    let indexPaths = self.pagingCollectionView.indexPaths(forElementsInRect: addedRect)
                    
                    if indexPaths != nil {
                        addedIndexPaths.append(contentsOf: indexPaths!)
                    }
            })
            
            let assetsToStartCaching = assets(atIndexPaths: addedIndexPaths)
            let assetsToStopCaching = assets(atIndexPaths: removedIndexPaths)
            
            // Update the assets the PHCachingImageManager is caching.
            let options: PHImageRequestOptions = {
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.resizeMode = .fast
                options.isSynchronous = false
                
                return options
            }()
            
            if assetsToStartCaching != nil {
                imageManager.startCachingImages(for: assetsToStartCaching!,
                                                         targetSize: targetSize,
                                                         contentMode: .aspectFill,
                                                         options: options)
            }
            
            if assetsToStopCaching != nil {
                imageManager.stopCachingImages(for: assetsToStopCaching!,
                                                        targetSize: targetSize,
                                                        contentMode: .aspectFill,
                                                        options: nil)
            }
            
            // Store the preheat rect to compare against in the future.
            previousPreheatRect = preheatRect
        }
    }
}

// MARK: UICollection View Data Source
extension PhotoBrowser: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photoCell = collectionView.dequeueReusableCell(
            withReuseIdentifier: cellReuseIdentifier,
            for: indexPath
        ) as! PhotoCell
        
        let asset = photos[indexPath.item]
        photoCell.representedAssetIdentifier = asset.localIdentifier
        
        photoCell.page.tapView.delegate = self
        photoCell.page.photoImageView.delegate = self
        
        // Request an image for the asset from the PHCachingImageManager.
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isSynchronous = false
        
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) {
            (image: UIImage?, info: [AnyHashable: Any]?) in
            
            // Set the cell's thumbnail image if it's still showing the same asset.
            if photoCell.representedAssetIdentifier == asset.localIdentifier {
                photoCell.page.image = image
            }
        }
        
        return photoCell
    }
}

// MARK: - UICollection View Delegate
extension PhotoBrowser: UICollectionViewDelegate {
    
}

// MARK: - Tap Detecting Image View Delegate
extension PhotoBrowser: TapDetectingImageViewDelegate {
    func singleTapDetected(_ touch: UITouch) {
        // Display or hide status bar
        if statusBarPresented {
            perform(#selector(PhotoBrowser.hideTopBars), with: nil, afterDelay: 0.2)
        } else {
            perform(#selector(PhotoBrowser.displayTopBars), with: nil, afterDelay: 0.2)
        }
    }
    
    func doubleTapDetected(_ touch: UITouch) {
        // Cancel any single tap handling.
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
}

// MARK: - Tap Detecting View Delegate
extension PhotoBrowser: TapDetectingViewDelegate {
    func singleTapDetectedFromTapView(_ touch: UITouch) {
        singleTapDetected(touch)
    }
    
    func doubleTapDetectedFromTapView(_ touch: UITouch) {
        doubleTapDetected(touch)
    }
}

// MARK: - UIScroll View Delegate
extension PhotoBrowser {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if enableScrollToDismissTopBars && pagingCollectionViewHasScrolled && statusBarPresented {
            hideTopBars()
        }
        
        // Update cached assets for the new visible area.
        updateCachedAssets()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentPhotoIndex()
    }
}

// MARK: - UINavigation Controller Delegate
extension PhotoBrowser: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // Enable the interactivePopGestureRecognizer when navigationController pop self.
        if viewController !== self && enableInteractivePopGestureRecognizer == false {
            navigationController.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
}
