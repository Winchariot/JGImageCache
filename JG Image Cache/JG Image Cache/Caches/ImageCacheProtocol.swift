//
//  ImageCacheProtocol.swift
//  JG Image Cache
//
//  Created by James Gillin on 7/18/17.
//  Copyright © 2017 James Gillin. All rights reserved.
//

import UIKit

protocol MemoryCacheProtocol {
    var cacheLimitBytes: Int { get }
    
    func retrieve(_ url: URL) -> UIImage?
    func cache(image: UIImage, key: String, size: Int)
}

protocol DiskCacheProtocol {
    var cacheLimitBytes: Int { get }
    
    func retrieve(_ url: URL) -> UIImage?
    func cache(imageData: Data, key: String)
    func downsize()
}
