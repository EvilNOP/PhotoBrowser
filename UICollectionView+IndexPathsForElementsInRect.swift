//
//  UICollectionView+IndexPathsForElementsInRect.swift
//  PhotoBrowser
//
//  Created by Matthew on 09/11/2016.
//  Copyright © 2016年 Matthew. All rights reserved.
//

import UIKit

extension UICollectionView {
    
    func indexPaths(forElementsInRect rect: CGRect) -> [IndexPath]? {
        if let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect) {
            return allLayoutAttributes.map { $0.indexPath }
        }
        
        return nil
    }
}
