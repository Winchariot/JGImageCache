//
//  ImageCache.swift
//  JG Image Cache
//
//  Created by James Gillin on 7/17/17.
//  Copyright © 2017 James Gillin. All rights reserved.
//

import UIKit

class MemoryCache: MemoryCacheProtocol {
    
    let cacheLimitBytes: Int
    private var memoryCache = NSCache<NSString, AnyObject>()
    
    init(cacheLimitBytes: Int) {
        self.cacheLimitBytes = cacheLimitBytes
    }

    func retrieve(_ url: URL) -> UIImage? {
        let key = url.cacheKey as NSString
        return memoryCache.object(forKey: key) as? UIImage
    }
    
    func cache(image: UIImage, key: String, size: Int) {
        memoryCache.setObject(image, forKey: key as NSString, cost: size)
    }
    
    func downsize() {
        print("")
    }

    

}
