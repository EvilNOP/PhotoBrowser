//
//  TapDetectingImageView.swift
//  PhotoBrowser
//
//  Created by Matthew on 09/11/2016.
//  Copyright © 2016 Matthew. All rights reserved.
//

import UIKit

@objc protocol TapDetectingImageViewDelegate {
    
    @objc optional func singleTapDetected(_ touch: UITouch)
    @objc optional func doubleTapDetected(_ touch: UITouch)
}

class TapDetectingImageView: UIImageView {
    
    weak var delegate: TapDetectingImageViewDelegate?
    
    // MARK: - Initialization
    convenience init() {
        self.init(frame: CGRect.zero)
        
        self.isUserInteractionEnabled = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isUserInteractionEnabled = true
    }
    
    override init(image: UIImage?) {
        super.init(image: image)
        
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(image: UIImage?, highlightedImage: UIImage?) {
        super.init(image: image, highlightedImage: highlightedImage)
        
        self.isUserInteractionEnabled = true
    }
    
    // MARK: - Overridden Methods
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = (touches as NSSet).anyObject() as! UITouch
        
        switch touch.tapCount {
        case 1:
            handleSingleTap(touch)
        case 2:
            handleDoubleTap(touch)
        default:
            break
        }
        
        next?.touchesEnded(touches, with: event)
    }
    
    // MARK: - Private Methods
    private func handleSingleTap(_ touch: UITouch) {
        delegate?.singleTapDetected?(touch)
    }
    
    private func handleDoubleTap(_ touch: UITouch) {
        delegate?.doubleTapDetected?(touch)
    }
}
