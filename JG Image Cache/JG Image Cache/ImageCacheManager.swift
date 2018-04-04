//
//  ImageCacheManager.swift
//  JG Image Cache
//
//  Created by James Gillin on 7/13/17.
//  Copyright © 2017 James Gillin. All rights reserved.
//

import UIKit

enum Result<T, U> {
    case success(T)
    case failure(U)
}

typealias ImageCompletion = ((Result<UIImage, Error>) -> Void)

struct ImageCacheOptions {
    let memoryCacheLimit: Int
    let diskCacheLimit: Int
    let diskCacheTTL: TimeInterval
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
    
    //public for testing--use .shared singleton
    init(imageCache: ImageCacheProtocol, imageCacheOptions: ImageCacheOptions) {
        
        self.imageCache = imageCache
        self.imageCache.memoryCache.totalCostLimit = imageCacheOptions.memoryCacheLimit
        self.diskCacheSizeLimit = imageCacheOptions.diskCacheLimit
        self.diskCacheTTL = imageCacheOptions.diskCacheTTL
        
        NotificationCenter.default.addObserver(self, selector: #selector(downsizeDiskCache), name: .UIApplicationWillTerminate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(wipeMemoryCache), name: .UIApplicationDidReceiveMemoryWarning, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func wipeMemoryCache() {
        imageCache.wipeMemoryCache()
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
                
                self?.imageCache.cacheToMemory(image: image, key: url.cacheKey, cost: imageData.count)
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
