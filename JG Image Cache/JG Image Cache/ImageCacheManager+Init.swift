//
//  ImageCacheManager+Init.swift
//  JG Image Cache
//
//  Created by James Gillin on 7/17/17.
//  Copyright © 2017 James Gillin. All rights reserved.
//

import Foundation

extension ImageCacheManager {
    static let shared: ImageCacheManager = {
        let imageCacheOptions = ImageCacheOptions(memoryCacheLimit: (48 * 1024 * 1024), diskCacheLimit: (120 * 1024 * 1024), diskCacheTTL: (60 * 60 * 24 * 10))
        let fileManager = ImageCacheDataStore()
        return ImageCacheManager(imageCache: ImageCache(fileManager: fileManager), imageCacheOptions: imageCacheOptions)
    }()
}

