//
//  String+md5.swift
//  uShip
//
//  Created by James Gillin on 7/17/17.
//  Copyright © 2017 uShip. All rights reserved.
//

import Foundation
import CommonCrypto

extension String {
    var md5: String? {
        guard let str = self.cString(using: .utf8) else { return nil }
        let strLen = CC_LONG(self.lengthOfBytes(using: .utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        defer { result.deallocate(capacity: digestLen) }
        CC_MD5(str, strLen, result)
        
        var hash: String = ""
        for i in 0..<digestLen {
            hash = hash.appendingFormat("%02x", result[i])
        }
        
        return hash
    }
}
