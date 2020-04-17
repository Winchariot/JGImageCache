//
//  ImageCacheManager.swift
//  JG Image Cache
//
//  Created by James Gillin on 7/13/17.
//  Copyright © 2017 James Gillin. All rights reserved.
//

import UIKit

//enum Result<T, U> {
//    case success(T)
//    case failure(U)
//}

typealias ImageCompletion = ((Result<UIImage, Error>) -> Void)

enum ImageCacheOptionKey {
    case memoryCacheLimitBytes
    case diskCacheLimitBytes
    case diskCacheTTLSeconds
}

class ImageCacheManager {
    
    let imageCache: ImageCacheProtocol
    let workerQueue = DispatchQueue.global()
    
    private var diskCacheTTL: TimeInterval
    private var diskCacheSizeLimit: Int
    private var requestsInFlight = [URL:[ImageCompletion]]()
    private var expirationDate: Date {
        return Date().addingTimeInterval(diskCacheTTL * -1)
    }
    
    static let shared: ImageCacheManager = {
        let imageCacheOptions: [ImageCacheOptionKey: Any] = [
            .memoryCacheLimitBytes: 48 * 1024 * 1024,
            .diskCacheLimitBytes: 64 * 1024 * 1024,
            .diskCacheTTLSeconds: 60 * 60 * 24 * 10]
        
        let fileManager = DiskCache()
        return ImageCacheManager(imageCache: ImageCache(fileManager: fileManager), options: imageCacheOptions)
    }()
    
    private init(imageCache: ImageCacheProtocol, options: [ImageCacheOptionKey: Any]) {
        let memoryCacheLimit = options[.memoryCacheLimitBytes] as? Int ?? 32 * 1024 * 1024
        let diskCacheLimit = options[.diskCacheLimitBytes] as? Int ?? 64 * 1024 * 1024
        let diskCacheTTL = options[.diskCacheTTLSeconds] as? TimeInterval ?? 60 * 60 * 24 * 10
        
        self.imageCache = imageCache
        self.imageCache.memoryCache.totalCostLimit = memoryCacheLimit
        self.diskCacheSizeLimit = diskCacheLimit
        self.diskCacheTTL = diskCacheTTL
        
        NotificationCenter.default.addObserver(self, selector: #selector(downsizeDiskCache), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    @objc func downsizeDiskCache() {
        imageCache.evictExpiredImagesFromDisk(relativeTo: expirationDate)
        imageCache.downsizeDiskCache(to: diskCacheSizeLimit)
    }
    
    func enforceNoDuplicateParellelRequests(checking url: URL, against requestsInFlight: inout [URL:[ImageCompletion]], completion: @escaping ImageCompletion) -> Bool {
        if requestsInFlight[url] == nil {
            requestsInFlight[url] = []
        }
        requestsInFlight[url]?.append(completion)
        return requestsInFlight[url]?.count == 1
    }
    
    func fetchImage(at url: URL, ignoreCache: Bool = false, completion: @escaping ImageCompletion) {
        if ignoreCache == false {
            if let memoryCachedImage = imageCache.imageFromMemoryCache(url: url) {
                completion(.success(memoryCachedImage))
                return
            }
        }
        
        guard enforceNoDuplicateParellelRequests(checking: url, against: &requestsInFlight, completion: completion) else { return }
        
        workerQueue.async { [weak self] in
            if ignoreCache == false {
                if let diskCachedImage = self?.imageCache.imageFromDiskCache(url: url) {
                    let result: Result<UIImage, Error> = .success(diskCachedImage)
                    self?._callCompletionHandlers(for: url, result: result)
                    return
                }
            }
            
            let session = URLSession.shared
            let task = session.downloadTask(with: url) { [weak self] (location, response, error) in
                guard let location = location, error == nil else {
                    let error = NSError(domain: "ImageCacheManager", code: 20, userInfo: nil)
                    let result: Result<UIImage, Error> = .failure(error)
                    self?._callCompletionHandlers(for: url, result: result)
                    return
                }
                guard let imageData = try? Data(contentsOf: location) else {
                    let error = NSError(domain: "ImageCacheManager", code: 30, userInfo: nil)
                    let result: Result<UIImage, Error> = .failure(error)
                    self?._callCompletionHandlers(for: url, result: result)
                    return
                }
                guard let image = UIImage(data: imageData) else {
                    let error = NSError(domain: "ImageCacheManager", code: 40, userInfo: nil)
                    let result: Result<UIImage, Error> = .failure(error)
                    self?._callCompletionHandlers(for: url, result: result)
                    return
                }
                
                self?.imageCache.cacheImageToMemory(image: image, key: url.cacheKey, cost: imageData.count)
                self?.imageCache.cacheImageToDisk(imageData: imageData, filename: url.cacheKey)
                let result: Result<UIImage, Error> = .success(image)
                self?._callCompletionHandlers(for: url, result: result)
            }
            task.resume()
        }
    }

    private func _callCompletionHandlers(for url: URL, result: Result<UIImage, Error>) {
        workerQueue.sync {
            guard let completionsForRequest = requestsInFlight[url] else { return }
            for completion in completionsForRequest {
                DispatchQueue.main.async {
                    completion(result)
                }
            }
            requestsInFlight[url] = nil
        }
    }
}
