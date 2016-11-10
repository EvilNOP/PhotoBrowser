//
//  ZoomingScrollView.swift
//  PhotoBrowser
//
//  Created by Matthew on 09/11/2016.
//  Copyright © 2016年 Matthew. All rights reserved.
//

import UIKit
import Photos

class ZoomingScrollView: UIScrollView {
    
    var index: Int?
    
    var image: UIImage? {
        didSet {
            displayImage()
        }
    }
    
    fileprivate(set) var tapView: TapDetectingView!
    fileprivate(set) var photoImageView: TapDetectingImageView!
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Tap view for background.
        self.tapView = TapDetectingView(frame: self.bounds)
        self.tapView.backgroundColor = UIColor.black
        
        self.addSubview(self.tapView)
        
        self.photoImageView = TapDetectingImageView(frame: CGRect.zero)
        self.photoImageView.contentMode = .center
        
        self.addSubview(self.photoImageView)
        
        self.delegate = self
        self.backgroundColor = UIColor.black
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.decelerationRate = UIScrollViewDecelerationRateFast
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Center the image as it becomes smaller than the size of the screen.
        var frameToCenter = photoImageView.frame
        
        // Horizontally.
        if frameToCenter.width < bounds.width {
            frameToCenter.origin.x = floor((bounds.width - frameToCenter.width) / 2.0)
        } else{
            frameToCenter.origin.x = 0.0
        }
        
        // Vertically.
        if frameToCenter.height < bounds.height {
            frameToCenter.origin.y = floor((bounds.height - frameToCenter.height) / 2.0)
        } else {
            frameToCenter.origin.y = 0.0
        }
        
        photoImageView.frame = frameToCenter
    }
    
    // MARK: - Private Methods
    private func displayImage() {
        if image != nil {
            maximumZoomScale = 1.0
            minimumZoomScale = 1.0
            zoomScale = 1.0
            contentSize = CGSize.zero
            
            photoImageView.image = image
            
            // Setup photo frame
            photoImageView.frame = CGRect(origin: CGPoint.zero, size: image!.size)
            contentSize = photoImageView.frame.size
            
            // Set zoom to minimum zoom
            setMaxMinZoomScalesForCurrentBounds()
            
            setNeedsLayout()
        }
    }
    
    private func setMaxMinZoomScalesForCurrentBounds() {
        guard photoImageView.image != nil else {
            return
        }
        
        let imageSize = photoImageView.image!.size
        
        // Calculate Min
        // the scale needed to perfectly fit the image width-wise
        let xScale = bounds.width / imageSize.width
        
        // the scale needed to perfectly fit the image height-wise
        let yScale = bounds.height / imageSize.height
        
        // use minimum of these to allow the image to become fully visible
        var minimumScale = min(xScale, yScale)
        
        // Image is smaller than screen so no zooming
        if xScale >= 1.0 && yScale >= 1.0 {
            minimumScale = 1.0
        }
        
        // Set minimum maximum zoom scale
        maximumZoomScale = minimumScale * 2.0
        minimumZoomScale = minimumScale
        
        // Initial zoom scale
        zoomScale = minimumZoomScale
        
        // Disable scrolling initially until the first pinch to fix issues with swiping on an initally zoomed in photo
        isScrollEnabled = false
    }
}

// MARK: - UIScroll View Delegate
extension ZoomingScrollView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return photoImageView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        isScrollEnabled = true
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        setNeedsLayout()
        layoutIfNeeded()
    }
}
