//
//  String+Base64.swift
//  BTBaseSDK
//
//  Created by Alex Chow on 2018/6/20.
//  Copyright © 2018年 btbase. All rights reserved.
//

import Foundation
extension String {
    var base64String: String? {
        return self.data(using: .utf8)?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
    }
    
    var base64UrlSafeString: String? {
        return base64String?.replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
    }

    var valueOfBase64String: String? {
        let encoded64 = self.padding(toLength: ((self.count+3)/4)*4,
                                     withPad: "=",
                                     startingAt: 0)
        if let data = Data(base64Encoded: encoded64, options: Data.Base64DecodingOptions(rawValue: 0)) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    var valueOfBase64UrlSafeString: String? {
        let replacing = self.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        return replacing.valueOfBase64String
    }
}
