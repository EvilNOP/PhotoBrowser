//
//  TapDetectingView.swift
//  PhotoBrowser
//
//  Created by Matthew on 09/11/2016.
//  Copyright © 2016年 Matthew. All rights reserved.
//

import UIKit

@objc protocol TapDetectingViewDelegate {
    
    @objc optional func singleTapDetectedFromTapView(_ touch: UITouch)
    @objc optional func doubleTapDetectedFromTapView(_ touch: UITouch)
}

class TapDetectingView: UIView {
    
    weak var delegate: TapDetectingViewDelegate?
    
    // MARK: - Initialization
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    }
    
    // MARK: - Private Methods
    private func handleSingleTap(_ touch: UITouch) {
        delegate?.singleTapDetectedFromTapView?(touch)
    }
    
    private func handleDoubleTap(_ touch: UITouch) {
        delegate?.doubleTapDetectedFromTapView?(touch)
    }
}
