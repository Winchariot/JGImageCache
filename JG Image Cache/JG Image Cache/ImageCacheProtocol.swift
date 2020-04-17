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
    
    //retrieval
    func imageFromMemoryCache(url: URL) -> UIImage?
    func imageFromDiskCache(url: URL) -> UIImage?
    
    //storage
    func cacheImageToMemory(image: UIImage, key: String, cost: Int)
    func cacheImageToDisk(imageData: Data, filename: String)
    
    //eviction
    func evictExpiredImagesFromDisk(relativeTo expirationDate: Date) 
    func downsizeDiskCache(to sizeLimit: Int)
}
