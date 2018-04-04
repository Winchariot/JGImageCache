//
//  ImageCacheProtocol.swift
//  JG Image Cache
//
//  Created by James Gillin on 7/18/17.
//  Copyright © 2017 James Gillin. All rights reserved.
//

import UIKit

protocol ImageCacheProtocol {
    var memoryCache: NSCache<NSString, AnyObject> { get }    
    
    func imageFromMemoryCache(url: URL) -> UIImage?
    func cacheToMemory(image: UIImage, key: String, cost: Int)
    func wipeMemoryCache() -> Void
    
    func diskCachedImageURLs() -> [URL]
    func imageFromDiskCache(url: URL) -> UIImage?
    func cacheImageToDisk(imageData: Data, filename: String)
    func removeImageFromDisk(at url: URL)
    func evictExpiredImagesFromDisk(relativeTo expirationDate: Date) 
    func downsizeDiskCache(to sizeLimit: Int)
    
}
