//
//  PhotoCell.swift
//  PhotoBrowser
//
//  Created by Matthew on 09/11/2016.
//  Copyright © 2016年 Matthew. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    
    private let padding: CGFloat = 10.0
    
    var page: ZoomingScrollView
    var representedAssetIdentifier: String?
    
    override init(frame: CGRect) {
        page = ZoomingScrollView(frame: CGRect(
            origin: CGPoint.zero,
            size: CGSize(width: frame.width - padding * 2.0, height: frame.height))
        )
        
        super.init(frame: frame)
        
        contentView.addSubview(page)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        page.image = nil
        page.photoImageView.image = nil
    }
}
