//
//  DiskCache.swift
//  JG Image Cache
//
//  Created by James Gillin on 7/25/17.
//  Copyright © 2017 James Gillin. All rights reserved.
//

import Foundation
import UIKit

class DiskCache {
    let cacheLimitBytes: Int
    private let ttlSeconds: TimeInterval
    private let ioQueue = DispatchQueue(label: "JGImageCache.DiskIOQueue")
    private var expirationDate: Date {
        Date().addingTimeInterval(ttlSeconds * -1)
    }
    
    init(cacheLimitBytes: Int, ttlSeconds: TimeInterval) {
        self.cacheLimitBytes = cacheLimitBytes
        self.ttlSeconds = ttlSeconds
    }
    
    static var cacheDirectoryURL: URL? = {
        do {
            let cachesDir = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let imagesDirURL = cachesDir.appendingPathComponent("Images")
            try FileManager.default.createDirectory(at: imagesDirURL, withIntermediateDirectories: true)
            return imagesDirURL
        } catch {
            print(error)
            return nil
        }
    }()
    
    var cachedURLs: [URL] {
        guard let directoryURL = DiskCache.cacheDirectoryURL else { return [] }
        
        let urlResourceKeys: Array<URLResourceKey> = [.contentAccessDateKey]
        guard let cachedURLs = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: urlResourceKeys, options: []) else { return [] }
        
        return cachedURLs
    }
    
    var diskCacheSizeBytes: Int {
        guard let cachePathString = DiskCache.cacheDirectoryURL?.path else { return 0 }
        guard let cacheAttributes = try? FileManager.default.attributesOfItem(atPath: cachePathString) else { return 0 }
        guard let cacheSize = cacheAttributes[.size] as? Int else { return 0 }
        return cacheSize
    }
    
    func evictFromDisk(url: URL) {
        _ = ioQueue.sync {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

extension DiskCache: DiskCacheProtocol {
    func retrieve(_ url: URL) -> UIImage? {
        guard let directoryURL = DiskCache.cacheDirectoryURL else { return nil }
        let filename = url.cacheKey

        let hypotheticalImageURL = directoryURL.appendingPathComponent(filename)
        if let imageData = try? Data(contentsOf: hypotheticalImageURL) {
            return UIImage(data: imageData)
        } else {
            return nil
        }
    }
    
    func cache(imageData: Data, key: String) {
        guard diskCacheSizeBytes < cacheLimitBytes else { return }
        guard let directoryURL = DiskCache.cacheDirectoryURL else { return }
        
        let pathString = directoryURL.appendingPathComponent(key).path
        
        _ = ioQueue.sync {
            FileManager.default.createFile(atPath: pathString, contents: imageData, attributes: nil)
        }
    }
    
    func downsize() {
        evictExpiredImagesFromDisk()
        //2. delete things from the cache until it's down to size
    }
}

private extension DiskCache {
    func evictExpiredImagesFromDisk() {
        let cachedImageURLs = cachedURLs
        
        for imageURL in cachedImageURLs {
            if imageURL.isExpired(relativeTo: expirationDate) {
                evictFromDisk(url: imageURL)
            }
        }
    }
    
    func downsizeDiskCache(to targetCacheSize: Int) {
        let cachedImageURLs = cachedURLs
        let urlResourceKeys: Set<URLResourceKey> = [.contentAccessDateKey]
        //TODO this has got to have a cleaner way to sort
        let imageURLsByAge = cachedImageURLs.sorted { (lhs, rhs) -> Bool in
            let lhsAge = (try? lhs.resourceValues(forKeys: urlResourceKeys).contentAccessDate ?? Date(timeIntervalSince1970: 0)) ?? Date(timeIntervalSince1970: 0)
            let rhsAge = (try? rhs.resourceValues(forKeys: urlResourceKeys).contentAccessDate ?? Date(timeIntervalSince1970: 0)) ?? Date(timeIntervalSince1970: 0)
            return lhsAge < rhsAge
        }
        for cachedImageURL in imageURLsByAge {
            if diskCacheSizeBytes < targetCacheSize { break }
            evictFromDisk(url: cachedImageURL)
        }
    }
}
