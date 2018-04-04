//
//  UIImageView+CachedRequest.swift
//  JG Image Cache
//
//  Created by James Gillin on 7/13/17.
//  Copyright © 2017 James Gillin. All rights reserved.
//

import UIKit

extension UIImageView {
    
    var defaultCompletion: ImageCompletion {
        let completion: ImageCompletion = { result in
            switch result {
            case .success(let image):
                self.alpha = 0.4
                self.image = image
                UIView.animate(withDuration: 0.2, animations: { [unowned self] in
                    self.alpha = 1
                })
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        return completion
    }
    
    func fetchImage(at url: URL, ignoreCache: Bool = false, completion: ImageCompletion? = nil) {
        ImageCacheManager.shared.fetchImage(at: url, ignoreCache: ignoreCache, completion: completion ?? defaultCompletion)
    }
    
    @objc func fetchImage(at url: URL, ignoreCache: Bool) {
        ImageCacheManager.shared.fetchImage(at: url, ignoreCache: ignoreCache, completion: defaultCompletion)

    }
}

//Conforming to NSDiscardableContent causes the conforming type not to get automatically evicted from an NSCache upon backgrounding
//  https://stackoverflow.com/questions/13163480/nscache-and-background/13579963#13579963
extension UIImage : NSDiscardableContent {
    public func beginContentAccess() -> Bool { return true }
    
    public func endContentAccess() { }
    
    public func discardContentIfPossible() { }
    
    public func isContentDiscarded() -> Bool { return false }
}

