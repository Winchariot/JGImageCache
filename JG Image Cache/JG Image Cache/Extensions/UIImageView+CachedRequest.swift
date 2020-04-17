//
//  UIImageView+CachedRequest.swift
//  JG Image Cache
//
//  Created by James Gillin on 7/13/17.
//  Copyright © 2017 James Gillin. All rights reserved.
//

import UIKit

extension UIImageView {
    
    func fetchImage(at url: URL, ignoreCache: Bool = false, completion: ImageCompletion? = nil) {
        ImageCacheManager.shared.fetchImage(
            at: url,
            completion: completion ?? { [weak self] result in
                
            if case .success(let image) = result {
                self?.alpha = 0.4
                self?.image = image
                UIView.animate(withDuration: 0.2) { [weak self] in
                    self?.alpha = 1
                }
            }
        })
    }
    
    //convenience for String urls
    func fetchImage(at urlString: String, ignoreCache: Bool = false, completion: ImageCompletion? = nil) {
        guard let url = URL(string: urlString) else { return }
        fetchImage(at: url, ignoreCache: ignoreCache, completion: completion)
    }
}
