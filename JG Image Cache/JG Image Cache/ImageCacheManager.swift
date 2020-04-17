//
//  ImageCacheManager.swift
//  JG Image Cache
//
//  Created by James Gillin on 7/13/17.
//  Copyright © 2017 James Gillin. All rights reserved.
//

import UIKit

typealias ImageCompletion = ((Result<UIImage, ImageCacheError>) -> Void)

enum ImageCacheOptionKey {
    case memoryCacheLimitBytes
    case diskCacheLimitBytes
    case diskCacheTTLSeconds
}

class ImageCacheManager {
    
    let memoryCache: MemoryCacheProtocol
    let diskCache: DiskCacheProtocol
    let workerQueue = DispatchQueue.global(qos: .default)
        
    static let shared: ImageCacheManager = {
        let memoryCacheLimit: Int = 32 * 1024 * 1024 //32MB
        let diskCacheLimit: Int = 64 * 1024 * 1024 //64MB
        let diskCacheTTL: TimeInterval = 60 * 60 * 24 * 8 //8 days
        
        let memoryCache = MemoryCache(cacheLimitBytes: memoryCacheLimit)
        let diskCache = DiskCache(cacheLimitBytes: diskCacheLimit, ttlSeconds: diskCacheTTL)
        return ImageCacheManager(memoryCache: memoryCache, diskCache: diskCache)
    }()
  
    private init(memoryCache: MemoryCacheProtocol, diskCache: DiskCacheProtocol) {
        self.memoryCache = memoryCache
        self.diskCache = diskCache
        
        NotificationCenter.default.addObserver(self, selector: #selector(downsizeDiskCache), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    @objc func downsizeDiskCache() {
        diskCache.downsize()
    }
    
    func fetchImage(at url: URL, completion: @escaping ImageCompletion) {
        //see if cached in memory. Fast operation so we do it synchronously.
        if let memoryCachedImate = memoryCache.retrieve(url) {
            completion(.success(memoryCachedImate))
            return
        }
                
        workerQueue.async { [weak self] in
            //check if cached on disk. Slower, so this is async.
            if let diskCachedImage = self?.diskCache.retrieve(url) {
                DispatchQueue.main.async {
                    completion(.success(diskCachedImage))
                }
                return
            }
            
            //no cache hits; download the thing
            let task = URLSession.shared.downloadTask(with: url) { [weak self] (location, response, error) in
                DispatchQueue.main.async {

                guard let location = location, error == nil else {
                    completion(.failure(.downloadFailed))
                    return
                }
                guard let imageData = try? Data(contentsOf: location) else {
                    completion(.failure(.failedToAccessDownloadedData))
                    return
                }
                guard let image = UIImage(data: imageData) else {
                    completion(.failure(.failedToMakeImageFromData))
                    return
                }
                
                self?.cacheImage(image: image, imageData: imageData, key: url.cacheKey)
                completion(.success(image))
                }
            }
            task.resume()
        }
    }
}

private extension ImageCacheManager {
    func validate(location: URL?, response: URLResponse?, error: Error?) {
        
    }
    
    func cacheImage(image: UIImage, imageData: Data, key: String) {
        self.memoryCache.cache(image: image, key: key, size: imageData.count)
        self.diskCache.cache(imageData: imageData, key: key)
    }
}
