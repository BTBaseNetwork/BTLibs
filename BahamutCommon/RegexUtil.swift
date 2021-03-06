//
//  RegexHelper.swift
//  Sharelink
//
//  Created by AlexChow on 15/8/14.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

public struct RegexMatcher {
    let regex: NSRegularExpression?

    init(_ pattern: String) {
        do {
            try regex = NSRegularExpression(pattern: pattern,
                                            options: .caseInsensitive)
        } catch let _ as NSError {
            regex = nil
        }
    }

    func match(_ input: String) -> Bool {
        let range = NSMakeRange(0, input.lengthOfBytes(using: String.Encoding.utf8))
        let matches = regex?.matches(in: input, options: [], range: range)
        return matches?.count > 0
    }

    func matchFirstString(_ input: String) -> String? {
        let range = NSMakeRange(0, input.distance(from: input.startIndex, to: input.endIndex))
        if let res = regex?.firstMatch(in: input, options: [], range: range), res.range.length > 0 {
            let locationIndex = input.index(input.startIndex, offsetBy: res.range.location)
            let endIndex = input.index(locationIndex, offsetBy: res.range.length)
            return input.substring(with: Range<String.Index>(uncheckedBounds: (lower: locationIndex, upper: endIndex)))
        } else {
            return nil
        }
    }
}

/*
 infix operator.isRegexMatch(pattern:{
 associativity none
 precedence 130
 }
 */

extension String {
    func isRegexMatch(pattern: String) -> Bool {
        if let _ = self.range(of: pattern, options: .regularExpression) {
            return true
        }
        return false
    }
}
