//
//  CacheDataStoreProtocol.swift
//  uShip
//
//  Created by James Gillin on 7/25/17.
//  Copyright © 2017 uShip. All rights reserved.
//

import Foundation

protocol CacheDataStoreProtocol {
    var cacheSize: Int { get }
    var cachedURLs: [URL] { get }
    func cacheToDisk(data: Data, filename: String)
    func evictFromDisk(url: URL)
    func retrieveFromDisk(filename: String) -> Data?
}

