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
        return self.absoluteString.md5
    }
    
    func isExpired(relativeTo expirationDate: Date) -> Bool {
        let urlResourceKeys: Set<URLResourceKey> = [.creationDateKey]
        
        //grab last access date for this URL
        if let fileValues = try? self.resourceValues(forKeys: urlResourceKeys),
            let fileAccessDate = fileValues.contentAccessDate {
            
                return fileAccessDate.compare(expirationDate) == .orderedAscending
        }
        return false
    }
}
