//
//  URL+ImageCaching.swift
//  JG Image Cache
//
//  Created by James Gillin on 7/18/17.
//  Copyright © 2017 James Gillin. All rights reserved.
//

import Foundation

extension URL {
    var cacheKey: String {
        return (self.absoluteString.md5 ?? self.absoluteString)
    }
    
    func isExpired(relativeTo expirationDate: Date) -> Bool {
        let urlResourceKeys: Set<URLResourceKey> = [.contentAccessDateKey]
        
        if let fileValues = try? self.resourceValues(forKeys: urlResourceKeys) {
            if let fileAccessDate = fileValues.contentAccessDate {
                return fileAccessDate.compare(expirationDate) == .orderedAscending
            }
        }
        return false
    }
}
