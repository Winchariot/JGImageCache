//
//  DiskCache.swift
//  JG Image Cache
//
//  Created by James Gillin on 7/25/17.
//  Copyright © 2017 James Gillin. All rights reserved.
//

import Foundation

class DiskCache: CacheDataStoreProtocol {
    private let ioQueue = DispatchQueue(label: "JGImageCache.DiskIOQueue")
    
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
    
    func cacheToDisk(data: Data, filename: String) {
        guard let directoryURL = DiskCache.cacheDirectoryURL else { return }
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
        guard let directoryURL = DiskCache.cacheDirectoryURL else { return nil }
        let hypotheticalImageURL = directoryURL.appendingPathComponent(filename)
        return try? Data(contentsOf: hypotheticalImageURL)
    }
}
