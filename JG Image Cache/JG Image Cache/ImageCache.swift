//
//  ImageCache.swift
//  JG Image Cache
//
//  Created by James Gillin on 7/17/17.
//  Copyright © 2017 James Gillin. All rights reserved.
//

import UIKit

class ImageCache: ImageCacheProtocol {
    
    var memoryCache = NSCache<NSString, AnyObject>()
    private let diskCache: CacheDataStoreProtocol
    
    init(fileManager: CacheDataStoreProtocol) {
        self.diskCache = fileManager
    }
    
    //MARK: - Retrieval
        
    func imageFromMemoryCache(url: URL) -> UIImage? {
        let key = url.cacheKey as NSString
        return memoryCache.object(forKey: key) as? UIImage
    }
    
    func imageFromDiskCache(url: URL) -> UIImage? {
        if let cachedData = diskCache.retrieveFromDisk(filename: url.cacheKey) {
            return UIImage(data: cachedData)
        }
        return nil
    }
    
    //MARK: - Storage
    
    func cacheToMemory(image: UIImage, key: String, cost: Int) {
        memoryCache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    func cacheImageToDisk(imageData: Data, filename: String) {
        diskCache.cacheToDisk(data: imageData, filename: filename)
    }
    
    //MARK: - Cleanup
    
    func wipeMemoryCache() {
        memoryCache.removeAllObjects()
    }
        
    func diskCachedImageURLs() -> [URL] {
        return diskCache.cachedURLs
    }
    
    func removeImageFromDisk(at imageURL: URL) {
        diskCache.evictFromDisk(url: imageURL)
    }
    
    func evictExpiredImagesFromDisk(relativeTo expirationDate: Date) {
        let cachedImageURLs = diskCache.cachedURLs
        
        for imageURL in cachedImageURLs {
            if imageURL.isExpired(relativeTo: expirationDate) {
                diskCache.evictFromDisk(url: imageURL)
            }
        }
    }
    
    func downsizeDiskCache(to targetCacheSize: Int) {
        let cachedImageURLs = diskCache.cachedURLs
        let urlResourceKeys: Set<URLResourceKey> = [.contentAccessDateKey]
        //TODO this has got to have a cleaner way to sort
        let imageURLsByAge = cachedImageURLs.sorted { (lhs, rhs) -> Bool in
            let lhsAge = (try? lhs.resourceValues(forKeys: urlResourceKeys).contentAccessDate ?? Date(timeIntervalSince1970: 0)) ?? Date(timeIntervalSince1970: 0)
            let rhsAge = (try? rhs.resourceValues(forKeys: urlResourceKeys).contentAccessDate ?? Date(timeIntervalSince1970: 0)) ?? Date(timeIntervalSince1970: 0)
            return lhsAge < rhsAge
        }
        for cachedImageURL in imageURLsByAge {
            if diskCache.diskCacheSizeBytes < targetCacheSize { break }
            diskCache.evictFromDisk(url: cachedImageURL)
        }
    }
}
