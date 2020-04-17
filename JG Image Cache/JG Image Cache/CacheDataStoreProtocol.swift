//
//  CacheDataStoreProtocol.swift
//  JG Image Cache
//
//  Created by James Gillin on 7/25/17.
//  Copyright © 2017 James Gillin. All rights reserved.
//

import Foundation

protocol CacheDataStoreProtocol {
    var diskCacheSizeBytes: Int { get }
    var cachedURLs: [URL] { get }
    func cacheToDisk(data: Data, filename: String)
    func evictFromDisk(url: URL)
    func retrieveFromDisk(filename: String) -> Data?
}

