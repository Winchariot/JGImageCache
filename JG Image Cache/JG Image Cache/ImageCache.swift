//
//  ImageCache.swift
//  uShip
//
//  Created by James Gillin on 7/17/17.
//  Copyright © 2017 uShip. All rights reserved.
//

import UIKit

class ImageCache: ImageCacheProtocol {
    
    var memoryCache = NSCache<NSString, AnyObject>()
    fileprivate let fileManager: CacheDataStoreProtocol
    
    init(fileManager: CacheDataStoreProtocol) {
        self.fileManager = fileManager
    }
    
    //MARK: - Memory cache
    
    func imageFromMemoryCache(url: URL) -> UIImage? {
        let key = url.cacheKey as NSString
        return memoryCache.object(forKey: key) as? UIImage
    }
    
    func cacheToMemory(image: UIImage, key: String, cost: Int) {
        memoryCache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    func wipeMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    //MARK: - Disk cache
    
    func diskCachedImageURLs() -> [URL] {
        return fileManager.cachedURLs
    }
    
    func imageFromDiskCache(url: URL) -> UIImage? {
        if let cachedData = fileManager.retrieveFromDisk(filename: url.cacheKey) {
            return UIImage(data: cachedData)
        }
        return nil
    }
    
    func cacheImageToDisk(imageData: Data, filename: String) {
        fileManager.cacheToDisk(data: imageData, filename: filename)
    }
    
    func removeImageFromDisk(at imageURL: URL) {
        fileManager.evictFromDisk(url: imageURL)
    }
    
    func evictExpiredImagesFromDisk(relativeTo expirationDate: Date) {
        let cachedImageURLs = fileManager.cachedURLs
        
        for imageURL in cachedImageURLs {
            if imageURL.isExpired(relativeTo: expirationDate) {
                fileManager.evictFromDisk(url: imageURL)
            }
        }
    }
    
    func downsizeDiskCache(to targetCacheSize: Int) {
        let cachedImageURLs = fileManager.cachedURLs
        let urlResourceKeys: Set<URLResourceKey> = [.contentAccessDateKey]
        //TODO this has got to have a cleaner way to sort
        let imageURLsByAge = cachedImageURLs.sorted { (lhs, rhs) -> Bool in
            let lhsAge = (try? lhs.resourceValues(forKeys: urlResourceKeys).contentAccessDate ?? Date(timeIntervalSince1970: 0)) ?? Date(timeIntervalSince1970: 0)
            let rhsAge = (try? rhs.resourceValues(forKeys: urlResourceKeys).contentAccessDate ?? Date(timeIntervalSince1970: 0)) ?? Date(timeIntervalSince1970: 0)
            return lhsAge < rhsAge
        }
        for cachedImageURL in imageURLsByAge {
            if fileManager.cacheSize < targetCacheSize { break }
            fileManager.evictFromDisk(url: cachedImageURL)
        }
    }
}
