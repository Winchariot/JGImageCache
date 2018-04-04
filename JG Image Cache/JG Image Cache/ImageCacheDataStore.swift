//
//  ImageCacheDataStore.swift
//  JG Image Cache
//
//  Created by James Gillin on 7/25/17.
//  Copyright © 2017 James Gillin. All rights reserved.
//

import Foundation

class ImageCacheDataStore: CacheDataStoreProtocol {
    private let ioQueue = DispatchQueue(label: "JGImageCache.DiskIOQueue")
    
    static var cacheURL: URL? = {
        guard let cachesDir = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return nil }
        let imagesDirURL = cachesDir.appendingPathComponent("Images")
        try? FileManager.default.createDirectory(at: imagesDirURL, withIntermediateDirectories: false, attributes: nil)
        return imagesDirURL
    }()
    
    var cachedURLs: [URL] {
        guard let directoryURL = ImageCacheDataStore.cacheURL else { return [] }
        let urlResourceKeys: Set<URLResourceKey> = [.contentAccessDateKey]
        guard let cachedURLs = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: Array(urlResourceKeys), options: []) else { return [] }
        return cachedURLs
    }
    
    var cacheSize: Int {
        guard let cachePathString = ImageCacheDataStore.cacheURL?.path else { return 0 }
        guard let cacheAttributes = try? FileManager.default.attributesOfItem(atPath: cachePathString) else { return 0 }
        guard let cacheSize = cacheAttributes[.size] as? NSNumber else { return 0 }
        return Int(cacheSize)
    }
    
    func cacheToDisk(data: Data, filename: String) {
        guard let directoryURL = ImageCacheDataStore.cacheURL else { return }
        let pathString = directoryURL.appendingPathComponent(filename).path
        
        _ = ioQueue.sync {
            FileManager.default.createFile(atPath: pathString, contents: data, attributes: nil)
        }
    }
    
    func evictFromDisk(url: URL) {
        _ = ioQueue.sync {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    func retrieveFromDisk(filename: String) -> Data? {
        guard let directoryURL = ImageCacheDataStore.cacheURL else { return nil }
        let hypotheticalImageURL = directoryURL.appendingPathComponent(filename)
        return try? Data(contentsOf: hypotheticalImageURL)
    }
}
