//
//  ImageCacheError.swift
//  JG Image Cache
//
//  Created by Jim Gillin on 4/16/20.
//  Copyright © 2020 internetandbeer. All rights reserved.
//

import Foundation

enum ImageCacheError: Error {
    case downloadFailed
    case failedToAccessDownloadedData
    case failedToMakeImageFromData
}

